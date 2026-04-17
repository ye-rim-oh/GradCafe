import { html } from "../lib/html.js";

const tabs = [
  { id: "timeline", label: "Timeline" },
  { id: "trends", label: "Trends" },
  { id: "subfields", label: "Subfields" },
  { id: "data", label: "Data" }
];

export function TabNav({ activeTab, onTabChange }) {
  return html`
    <nav className="tab-strip" aria-label="Results views">
      ${tabs.map(
        (tab) => html`
          <button
            key=${tab.id}
            className=${`tab-button ${activeTab === tab.id ? "is-active" : ""}`}
            type="button"
            onClick=${() => onTabChange(tab.id)}
          >
            ${tab.label}
          </button>
        `
      )}
    </nav>
  `;
}
