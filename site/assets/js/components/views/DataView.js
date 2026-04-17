import { html, React } from "../../lib/html.js";
import { buildTableRows } from "../../lib/dashboard.js";

const { useEffect, useState } = React;
const pageSize = 10;

const decisionClass = (decision) => {
  if (decision === "Accepted") return "decision-tag decision-accepted";
  if (decision === "Rejected") return "decision-tag decision-rejected";
  if (decision === "Interview") return "decision-tag decision-interview";
  if (decision === "Wait listed") return "decision-tag decision-waitlisted";
  return "decision-tag decision-other";
};

export function DataView({ records, showSchool, query, onQueryChange }) {
  const [page, setPage] = useState(0);

  const rows = buildTableRows(records, showSchool);
  const totalPages = Math.max(1, Math.ceil(rows.length / pageSize));
  const currentPage = Math.min(page, totalPages - 1);
  const pageRows = rows.slice(currentPage * pageSize, currentPage * pageSize + pageSize);

  useEffect(() => {
    setPage(0);
  }, [query, records]);

  return html`
    <section className="content-card">
      <h2>All Results</h2>

      <div className="data-toolbar">
        <input
          className="search-input"
          type="search"
          value=${query}
          placeholder="Search school, decision, status, GRE, notes..."
          onInput=${(event) => onQueryChange(event.target.value)}
        />
        <span className="stats-pill">${rows.length} matching rows</span>
      </div>

      <div className="table-wrap">
        <table className="results-table">
          <thead>
            <tr>
              ${showSchool ? html`<th>School</th>` : null}
              <th>Decision</th>
              <th>Year</th>
              <th>Date</th>
              <th>Status</th>
              <th>Subfield</th>
              <th>GPA</th>
              <th>GRE</th>
              <th>Notes</th>
            </tr>
          </thead>
          <tbody>
            ${pageRows.map(
              (row) => html`
                <tr key=${row.id}>
                  ${showSchool ? html`<td>${row.school}</td>` : null}
                  <td><span className=${decisionClass(row.decision)}>${row.decision}</span></td>
                  <td>${row.year}</td>
                  <td>${row.date}</td>
                  <td>${row.status}</td>
                  <td>${row.subfield}</td>
                  <td>${row.gpa}</td>
                  <td>${row.gre}</td>
                  <td className="notes-cell">${row.notes}</td>
                </tr>
              `
            )}
          </tbody>
        </table>
      </div>

      <div className="pager">
        <button
          className="pager-button"
          type="button"
          onClick=${() => setPage((value) => Math.max(0, value - 1))}
          disabled=${currentPage === 0}
        >
          Previous
        </button>
        <span>Page ${currentPage + 1} / ${totalPages}</span>
        <button
          className="pager-button"
          type="button"
          onClick=${() => setPage((value) => Math.min(totalPages - 1, value + 1))}
          disabled=${currentPage >= totalPages - 1}
        >
          Next
        </button>
      </div>
    </section>
  `;
}
