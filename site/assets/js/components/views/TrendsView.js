import { html } from "../../lib/html.js";
import { buildNationalityRates, buildYearlyAcceptanceRates, STATUS_COLORS } from "../../lib/dashboard.js";

const WIDTH = 920;
const HEIGHT = 360;
const MARGIN = { top: 24, right: 24, bottom: 36, left: 54 };

const buildLinePath = (points) =>
  points.map((point, index) => `${index === 0 ? "M" : "L"} ${point.x} ${point.y}`).join(" ");

const buildChartMeta = (rows) => {
  const years = rows.map((row) => row.decisionYear);
  const minYear = Math.min(...years);
  const maxYear = Math.max(...years);
  const xScale = (year) =>
    MARGIN.left + ((year - minYear) / Math.max(1, maxYear - minYear)) * (WIDTH - MARGIN.left - MARGIN.right);
  const yScale = (rate) => HEIGHT - MARGIN.bottom - (rate / 100) * (HEIGHT - MARGIN.top - MARGIN.bottom);
  return { years, minYear, maxYear, xScale, yScale };
};

const mergeNationalityRows = (rows) => {
  const merged = new Map();
  rows.forEach((row) => {
    const item = merged.get(row.decisionYear) ?? { decisionYear: row.decisionYear };
    item[row.status] = row.rate;
    item[`${row.status}Total`] = row.total;
    merged.set(row.decisionYear, item);
  });
  return [...merged.values()].sort((left, right) => left.decisionYear - right.decisionYear);
};

const lineSvg = (rows, series, colors) => {
  const meta = buildChartMeta(rows);

  return html`
    <svg viewBox="0 0 ${WIDTH} ${HEIGHT}" width="100%" height="100%" role="img">
      ${[0, 25, 50, 75, 100].map(
        (tick) => html`
          <g key=${tick}>
            <line
              x1=${MARGIN.left}
              x2=${WIDTH - MARGIN.right}
              y1=${meta.yScale(tick)}
              y2=${meta.yScale(tick)}
              stroke="rgba(32,32,29,0.12)"
            />
            <text x=${MARGIN.left - 10} y=${meta.yScale(tick) + 4} text-anchor="end" fill="#6e6b63" font-size="12">
              ${tick}
            </text>
          </g>
        `
      )}
      ${rows.map(
        (row) => html`
          <text
            key=${row.decisionYear}
            x=${meta.xScale(row.decisionYear)}
            y=${HEIGHT - 12}
            text-anchor="middle"
            fill="#6e6b63"
            font-size="12"
          >
            ${row.decisionYear}
          </text>
        `
      )}
      ${series.map((item) => {
        const points = rows
          .filter((row) => row[item.key] !== undefined && row[item.key] !== null)
          .map((row) => ({
            x: meta.xScale(row.decisionYear),
            y: meta.yScale(row[item.key]),
            row
          }));

        if (!points.length) {
          return null;
        }

        return html`
          <g key=${item.key}>
            <path d=${buildLinePath(points)} fill="none" stroke=${colors[item.key]} stroke-width="3" />
            ${points.map(
              (point) => html`
                <circle cx=${point.x} cy=${point.y} r="4.5" fill=${colors[item.key]}>
                  <title>
                    ${`${item.label} | ${point.row.decisionYear}
Rate: ${point.row[item.key]}%
Sample: ${point.row[`${item.key}Total`] ?? point.row.total ?? 0}`}
                  </title>
                </circle>
              `
            )}
          </g>
        `;
      })}
    </svg>
  `;
};

export function TrendsView({ records }) {
  const yearlyRates = buildYearlyAcceptanceRates(records);
  const nationalityRates = mergeNationalityRows(buildNationalityRates(records));

  return html`
    <section className="content-card">
      <h2>Yearly Acceptance Rate</h2>
      ${yearlyRates.length
        ? html`
            <div className="chart-shell">
              ${lineSvg(yearlyRates, [{ key: "rate", label: "Acceptance rate" }], { rate: "#234d73" })}
            </div>
          `
        : html`<div className="empty-state">No accepted or rejected outcomes match the active filters.</div>`}
    </section>

    <section className="content-card">
      <h2>American vs International</h2>
      ${nationalityRates.length
        ? html`
            <div className="chart-shell">
              ${lineSvg(
                nationalityRates,
                [
                  { key: "American", label: "American" },
                  { key: "International", label: "International" }
                ],
                STATUS_COLORS
              )}
            </div>
            <div className="stats-inline">
              <span className="stats-pill">American</span>
              <span className="stats-pill">International</span>
            </div>
          `
        : html`<div className="empty-state">No nationality split is available for the active filters.</div>`}
    </section>
  `;
}
