import { html } from "../../lib/html.js";
import {
  buildSubfieldRateSeries,
  buildSubfieldVolumeSeries,
  SUBFIELD_COLORS
} from "../../lib/dashboard.js";

const WIDTH = 920;
const HEIGHT = 360;
const MARGIN = { top: 24, right: 24, bottom: 36, left: 54 };

const pivotRows = (rows, valueKey, sampleKey) => {
  const merged = new Map();
  rows.forEach((row) => {
    const item = merged.get(row.decisionYear) ?? { decisionYear: row.decisionYear };
    item[row.subfield] = row[valueKey];
    if (sampleKey) {
      item[`${row.subfield}Total`] = row[sampleKey];
    }
    merged.set(row.decisionYear, item);
  });
  return [...merged.values()].sort((left, right) => left.decisionYear - right.decisionYear);
};

const buildLinePath = (points) =>
  points.map((point, index) => `${index === 0 ? "M" : "L"} ${point.x} ${point.y}`).join(" ");

const stackedBarSvg = (rows, keys) => {
  const maxValue = Math.max(
    ...rows.map((row) => keys.reduce((sum, key) => sum + (row[key] ?? 0), 0)),
    1
  );
  const band = (WIDTH - MARGIN.left - MARGIN.right) / rows.length;
  const barWidth = Math.min(76, band * 0.7);
  const yScale = (value) => HEIGHT - MARGIN.bottom - (value / maxValue) * (HEIGHT - MARGIN.top - MARGIN.bottom);

  return html`
    <svg viewBox="0 0 ${WIDTH} ${HEIGHT}" width="100%" height="100%" role="img">
      ${[0, 0.25, 0.5, 0.75, 1].map((ratio) => {
        const value = Math.round(maxValue * ratio);
        return html`
          <g key=${ratio}>
            <line
              x1=${MARGIN.left}
              x2=${WIDTH - MARGIN.right}
              y1=${yScale(value)}
              y2=${yScale(value)}
              stroke="rgba(255,255,255,0.12)"
            />
            <text x=${MARGIN.left - 10} y=${yScale(value) + 4} text-anchor="end" fill="#c1c8d2" font-size="12">
              ${value}
            </text>
          </g>
        `;
      })}
      ${rows.map((row, index) => {
        const x = MARGIN.left + index * band + (band - barWidth) / 2;
        let baseline = HEIGHT - MARGIN.bottom;
        return html`
          <g key=${row.decisionYear}>
            ${keys.map((key) => {
              const value = row[key] ?? 0;
              const top = yScale(value + (HEIGHT - MARGIN.bottom - baseline === 0 ? 0 : 0));
              const height = ((value / maxValue) * (HEIGHT - MARGIN.top - MARGIN.bottom));
              const y = baseline - height;
              baseline = y;
              return value
                ? html`
                    <rect x=${x} y=${y} width=${barWidth} height=${height} fill=${SUBFIELD_COLORS[key]}>
                      <title>${`${row.decisionYear} | ${key}: ${value}`}</title>
                    </rect>
                  `
                : null;
            })}
            <text x=${x + barWidth / 2} y=${HEIGHT - 12} text-anchor="middle" fill="#c1c8d2" font-size="12">
              ${row.decisionYear}
            </text>
          </g>
        `;
      })}
    </svg>
  `;
};

const lineSvg = (rows, keys) => {
  const years = rows.map((row) => row.decisionYear);
  const minYear = Math.min(...years);
  const maxYear = Math.max(...years);
  const xScale = (year) =>
    MARGIN.left + ((year - minYear) / Math.max(1, maxYear - minYear)) * (WIDTH - MARGIN.left - MARGIN.right);
  const yScale = (rate) => HEIGHT - MARGIN.bottom - (rate / 100) * (HEIGHT - MARGIN.top - MARGIN.bottom);

  return html`
    <svg viewBox="0 0 ${WIDTH} ${HEIGHT}" width="100%" height="100%" role="img">
      ${[0, 25, 50, 75, 100].map(
        (tick) => html`
          <g key=${tick}>
            <line
              x1=${MARGIN.left}
              x2=${WIDTH - MARGIN.right}
              y1=${yScale(tick)}
              y2=${yScale(tick)}
              stroke="rgba(255,255,255,0.12)"
            />
            <text x=${MARGIN.left - 10} y=${yScale(tick) + 4} text-anchor="end" fill="#c1c8d2" font-size="12">
              ${tick}
            </text>
          </g>
        `
      )}
      ${rows.map(
        (row) => html`
          <text
            key=${row.decisionYear}
            x=${xScale(row.decisionYear)}
            y=${HEIGHT - 12}
            text-anchor="middle"
            fill="#c1c8d2"
            font-size="12"
          >
            ${row.decisionYear}
          </text>
        `
      )}
      ${keys.map((key) => {
        const points = rows
          .filter((row) => row[key] !== undefined)
          .map((row) => ({ x: xScale(row.decisionYear), y: yScale(row[key]), row }));
        if (!points.length) return null;
        return html`
          <g key=${key}>
            <path d=${buildLinePath(points)} fill="none" stroke=${SUBFIELD_COLORS[key]} stroke-width="3" />
            ${points.map(
              (point) => html`
                <circle cx=${point.x} cy=${point.y} r="4.5" fill=${SUBFIELD_COLORS[key]}>
                  <title>${`${key} | ${point.row.decisionYear}
Rate: ${point.row[key]}%
Sample: ${point.row[`${key}Total`] ?? 0}`}</title>
                </circle>
              `
            )}
          </g>
        `;
      })}
    </svg>
  `;
};

export function SubfieldsView({ records }) {
  const volumeRows = pivotRows(buildSubfieldVolumeSeries(records), "count");
  const rateRows = pivotRows(buildSubfieldRateSeries(records, 3), "rate", "total");
  const visibleSubfields = Object.keys(SUBFIELD_COLORS).filter(
    (key) => volumeRows.some((row) => row[key]) || rateRows.some((row) => row[key] !== undefined)
  );

  return html`
    <section className="content-card">
      <h2>Subfield Report Volume</h2>
      ${volumeRows.length
        ? html`<div className="chart-shell">${stackedBarSvg(volumeRows, visibleSubfields)}</div>`
        : html`<div className="empty-state">No reported subfield labels match the active filters.</div>`}
    </section>

    <section className="content-card">
      <h2>Subfield Acceptance Rate</h2>
      ${rateRows.length
        ? html`
            <div className="chart-shell">${lineSvg(rateRows, visibleSubfields)}</div>
            <div className="stats-inline">
              ${visibleSubfields.map(
                (key) => html`
                  <span key=${key} className="stats-pill">
                    <span
                      style=${{
                        display: "inline-block",
                        width: "10px",
                        height: "10px",
                        borderRadius: "999px",
                        background: SUBFIELD_COLORS[key],
                        marginRight: "8px"
                      }}
                    ></span>
                    ${key}
                  </span>
                `
              )}
            </div>
          `
        : html`<div className="empty-state">No subfield rate series survive the active filters.</div>`}
    </section>
  `;
}
