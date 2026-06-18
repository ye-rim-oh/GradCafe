import { html, React } from "../../lib/html.js";
import { buildTimelinePoints, DECISION_COLORS, DECISION_ORDER, formatGre } from "../../lib/dashboard.js";

const { useEffect, useState } = React;

const WIDTH = 1160;
const HEIGHT = 700;
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
  const [hoverKey, setHoverKey] = useState(null);
  const [pinnedKey, setPinnedKey] = useState(null);
  const points = (providedPoints ?? buildTimelinePoints(records)).map((record, index) => ({
    ...record,
    cx: xScale(new Date(record.decisionMonthDay).getTime()),
    cy: yScale(DECISION_ORDER.indexOf(record.decision)) + ((index % 5) - 2) * 5
  }));
  const activeKey = hoverKey ?? pinnedKey;
  const activePoint = points.find((point) => point.timelineKey === activeKey);
  const tooltipPlacement = activePoint
    ? [
        activePoint.cx > WIDTH * 0.72 ? "timeline-tooltip-left" : "timeline-tooltip-right",
        activePoint.cy > HEIGHT * 0.72 ? "timeline-tooltip-above" : "timeline-tooltip-middle"
      ].join(" ")
    : "";
  const tooltipText = activePoint
    ? `Date: ${activePoint.monthDayLabel}, ${activePoint.decisionYear}
Status: ${activePoint.status !== "Unknown" ? activePoint.status : "Nationality not reported"}
GPA: ${activePoint.gpa ?? "N/A"}
GRE: ${formatGre(activePoint)}
Notes: ${activePoint.notes?.trim() ? activePoint.notes : "N/A"}`
    : "";

  useEffect(() => {
    setHoverKey(null);
    setPinnedKey(null);
  }, [records]);

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
      <div className="chart-shell chart-tall timeline-shell">
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
                className=${`timeline-dot ${activeKey === point.timelineKey ? "timeline-dot-selected" : ""}`}
                cx=${point.cx}
                cy=${point.cy}
                r="5.5"
                fill=${DECISION_COLORS[point.decision] ?? DECISION_COLORS.Other}
                fill-opacity="0.8"
                role="button"
                tabIndex="0"
                onMouseEnter=${() => setHoverKey(point.timelineKey)}
                onMouseLeave=${() => setHoverKey(null)}
                onFocus=${() => setHoverKey(point.timelineKey)}
                onBlur=${() => setHoverKey(null)}
                onClick=${() =>
                  setPinnedKey((current) => (current === point.timelineKey ? null : point.timelineKey))
                }
                onKeyDown=${(event) => {
                  if (event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    setPinnedKey((current) => (current === point.timelineKey ? null : point.timelineKey));
                  }
                }}
              >
                <title>${point.institution}</title>
              </circle>
            `
          )}
        </svg>
        ${activePoint
          ? html`
              <div
                className=${`timeline-tooltip ${tooltipPlacement}`}
                style=${{
                  left: `${(activePoint.cx / WIDTH) * 100}%`,
                  top: `${Math.max(10, Math.min((activePoint.cy / HEIGHT) * 100, 90))}%`
                }}
              >
                ${tooltipText}
              </div>
            `
          : null}
      </div>
      <div className="timeline-legend">
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
