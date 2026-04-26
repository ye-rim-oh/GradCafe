import { html } from "../../lib/html.js";
import { buildTimelinePoints, DECISION_COLORS, DECISION_ORDER, getInstitutionLabel } from "../../lib/dashboard.js";

const WIDTH = 920;
const HEIGHT = 620;
const MARGIN = { top: 36, right: 28, bottom: 42, left: 170 };
const START = new Date("2020-01-01").getTime();
const END = new Date("2020-04-30").getTime();
const MONTHS = [
  ["Jan", new Date("2020-01-01").getTime()],
  ["Feb", new Date("2020-02-01").getTime()],
  ["Mar", new Date("2020-03-01").getTime()],
  ["Apr", new Date("2020-04-01").getTime()]
];

const xScale = (value) =>
  MARGIN.left + ((value - START) / (END - START)) * (WIDTH - MARGIN.left - MARGIN.right);

const yScale = (decisionIndex) =>
  MARGIN.top + decisionIndex * ((HEIGHT - MARGIN.top - MARGIN.bottom) / (DECISION_ORDER.length - 1));

export function TimelineView({ records, points: providedPoints }) {
  const points = (providedPoints ?? buildTimelinePoints(records)).map((record, index) => ({
    ...record,
    cx: xScale(new Date(record.decisionMonthDay).getTime()),
    cy: yScale(DECISION_ORDER.indexOf(record.decision)) + ((index % 5) - 2) * 5
  }));

  if (!points.length) {
    return html`
      <section className="content-card">
        <h2>Decision Timeline</h2>
        <div className="empty-state">No dated outcomes match the active filters.</div>
      </section>
    `;
  }

  return html`
    <section className="content-card">
      <h2>Decision Timeline</h2>
      <div className="chart-shell chart-tall">
        <svg viewBox="0 0 ${WIDTH} ${HEIGHT}" width="100%" height="100%" role="img" aria-label="Decision timeline">
          ${MONTHS.map(
            ([label, value]) => html`
              <g key=${label}>
                <line
                  x1=${xScale(value)}
                  x2=${xScale(value)}
                  y1=${MARGIN.top - 8}
                  y2=${HEIGHT - MARGIN.bottom}
                  stroke="rgba(32,32,29,0.14)"
                  strokeDasharray="4 6"
                />
                <text x=${xScale(value)} y=${HEIGHT - 16} text-anchor="middle" fill="#6e6b63" font-size="14">
                  ${label}
                </text>
              </g>
            `
          )}
          ${DECISION_ORDER.map(
            (decision, index) => html`
              <g key=${decision}>
                <line
                  x1=${MARGIN.left}
                  x2=${WIDTH - MARGIN.right}
                  y1=${yScale(index)}
                  y2=${yScale(index)}
                  stroke="rgba(32,32,29,0.1)"
                />
                <text x=${MARGIN.left - 14} y=${yScale(index) + 5} text-anchor="end" fill="#20201d" font-size="14">
                  ${decision}
                </text>
              </g>
            `
          )}
          ${points.map(
            (point) => html`
              <circle
                key=${point.timelineKey}
                cx=${point.cx}
                cy=${point.cy}
                r="5.5"
                fill=${DECISION_COLORS[point.decision] ?? DECISION_COLORS.Other}
                fill-opacity="0.8"
              >
                <title>
                  ${`${point.decision} | ${point.monthDayLabel}, ${point.decisionYear}
${getInstitutionLabel(point)}
${point.status !== "Unknown" ? point.status : "Nationality not reported"}
${point.subfield !== "Unknown" ? point.subfield : "Subfield not reported"}
${point.gpa ? `GPA ${point.gpa}` : "GPA not reported"}`}
                </title>
              </circle>
            `
          )}
        </svg>
      </div>
      <div className="stats-inline">
        ${DECISION_ORDER.map(
          (decision) => html`
            <span key=${decision} className="stats-pill">
              <span
                style=${{
                  display: "inline-block",
                  width: "10px",
                  height: "10px",
                  borderRadius: "999px",
                  background: DECISION_COLORS[decision] ?? DECISION_COLORS.Other,
                  marginRight: "8px"
                }}
              ></span>
              ${decision}
            </span>
          `
        )}
      </div>
    </section>
  `;
}
