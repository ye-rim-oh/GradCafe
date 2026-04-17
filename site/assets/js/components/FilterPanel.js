import { html } from "../lib/html.js";

export function FilterPanel({
  institutions,
  years,
  decisions,
  filters,
  schoolQuery,
  onSchoolQueryChange,
  onInstitutionChange,
  onYearToggle,
  onDecisionToggle,
  onReset
}) {
  const normalizedSchoolQuery = schoolQuery.trim().toLowerCase();
  const visibleInstitutions = normalizedSchoolQuery
    ? institutions.filter((institution) => institution.toLowerCase().includes(normalizedSchoolQuery))
    : institutions;
  const selectInstitutions =
    filters.institution && !visibleInstitutions.includes(filters.institution)
      ? [filters.institution, ...visibleInstitutions]
      : visibleInstitutions;

  return html`
    <section className="section-card">
      <span className="section-label">Filters</span>

      <div className="control-group">
        <h3>School</h3>
        <input
          className="search-input school-search"
          type="search"
          value=${schoolQuery}
          placeholder="Search schools"
          onInput=${(event) => onSchoolQueryChange(event.target.value)}
        />
        <select
          className="select-input"
          value=${filters.institution}
          onChange=${(event) => onInstitutionChange(event.target.value)}
        >
          <option value="">No school filter</option>
          ${selectInstitutions.map(
            (institution) => html`
              <option key=${institution} value=${institution}>${institution}</option>
            `
          )}
        </select>
      </div>

      <div className="control-group">
        <h3>Years</h3>
        <div className="check-grid">
          ${years.map(
            (year) => html`
              <label key=${year} className="check-pill">
                <input
                  type="checkbox"
                  checked=${filters.years.includes(year)}
                  onChange=${() => onYearToggle(year)}
                />
                <span>${year}</span>
              </label>
            `
          )}
        </div>
      </div>

      <div className="control-group">
        <h3>Decision Types</h3>
        <div className="check-grid">
          ${decisions.map(
            (decision) => html`
              <label key=${decision} className="check-pill">
                <input
                  type="checkbox"
                  checked=${filters.decisions.includes(decision)}
                  onChange=${() => onDecisionToggle(decision)}
                />
                <span>${decision}</span>
              </label>
            `
          )}
        </div>
      </div>

      <button className="reset-button" type="button" onClick=${onReset}>
        Reset Filters
      </button>
    </section>
  `;
}
