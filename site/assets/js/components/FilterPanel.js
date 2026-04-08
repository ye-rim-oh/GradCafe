import { html } from "../lib/html.js";

export function FilterPanel({
  institutions,
  years,
  decisions,
  filters,
  onInstitutionChange,
  onYearToggle,
  onDecisionToggle,
  onReset
}) {
  return html`
    <section className="section-card">
      <span className="section-label">Filters</span>

      <div className="control-group">
        <h3>School</h3>
        <select
          className="select-input"
          value=${filters.institution}
          onChange=${(event) => onInstitutionChange(event.target.value)}
        >
          ${institutions.map(
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
