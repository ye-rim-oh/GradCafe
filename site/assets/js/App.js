import { html, React } from "./lib/html.js";
import {
  applyFilters,
  buildTimelinePoints,
  DEFAULT_DECISIONS,
  getInstitutions,
  getYears,
  matchesSearchQuery,
  OVERALL_LABEL
} from "./lib/dashboard.js";
import { FilterPanel } from "./components/FilterPanel.js";
import { TimelineView } from "./components/views/TimelineView.js";
import { TrendsView } from "./components/views/TrendsView.js";
import { SubfieldsView } from "./components/views/SubfieldsView.js";
import { DataView } from "./components/views/DataView.js";

const { useState } = React;

const toggleValue = (values, value) =>
  values.includes(value) ? values.filter((item) => item !== value) : [...values, value];

export default function App({ payload }) {
  const records = payload.records;
  const institutions = getInstitutions(records);
  const years = getYears(records);
  const [searchQuery, setSearchQuery] = useState("");
  const [schoolQuery, setSchoolQuery] = useState("");

  const [filters, setFilters] = useState({
    institution: OVERALL_LABEL,
    years,
    decisions: DEFAULT_DECISIONS
  });

  const filteredRecords = applyFilters(records, filters);
  const searchedRecords = filteredRecords.filter((record) => matchesSearchQuery(record, searchQuery));
  const timelinePoints = buildTimelinePoints(searchedRecords);
  const showSchool = filters.institution === OVERALL_LABEL;

  return html`
    <div className="page-shell">
      <div className="app-grid">
        <aside className="panel sidebar">
          <div className="brand-block">
            <p className="eyebrow">Search index</p>
            <h2>Find a school</h2>
          </div>

          <${FilterPanel}
            institutions=${institutions}
            years=${years}
            decisions=${payload.decisionChoices}
            filters=${filters}
            schoolQuery=${schoolQuery}
            onSchoolQueryChange=${setSchoolQuery}
            onInstitutionChange=${(institution) => setFilters((current) => ({ ...current, institution }))}
            onYearToggle=${(year) =>
              setFilters((current) => ({
                ...current,
                years: toggleValue(current.years, year).sort((left, right) => right - left)
              }))
            }
            onDecisionToggle=${(decision) =>
              setFilters((current) => ({
                ...current,
                decisions: toggleValue(current.decisions, decision)
              }))
            }
            onReset=${() => {
              setSchoolQuery("");
              setFilters({
                institution: OVERALL_LABEL,
                years,
                decisions: DEFAULT_DECISIONS
              });
            }}
          />
        </aside>

        <main className="panel main-panel">
          <section className="hero-header">
            <div>
              <h1 className="hero-title">Political Science PhD Results (2016-2026)</h1>
            </div>
          </section>

          <div className="stats-inline">
            <span className="stats-pill">${showSchool ? "No school filter" : filters.institution}</span>
            <span className="stats-pill">${searchedRecords.length} filtered rows</span>
            <span className="stats-pill">${timelinePoints.length} timeline dots</span>
            <span className="stats-pill">${filters.years.length} years selected</span>
          </div>

          <div className="view-stack">
            <section className="hero-stage">
              <${TimelineView} records=${searchedRecords} points=${timelinePoints} />
            </section>

            <section className="stack-section">
              <${DataView}
                records=${searchedRecords}
                showSchool=${showSchool}
                query=${searchQuery}
                onQueryChange=${setSearchQuery}
              />
            </section>

            <details className="analysis-details">
              <summary>Additional analysis</summary>
              <div className="analysis-grid">
                <${TrendsView} records=${searchedRecords} />
                <${SubfieldsView} records=${searchedRecords} />
              </div>
            </details>
          </div>
        </main>
      </div>
    </div>
  `;
}
