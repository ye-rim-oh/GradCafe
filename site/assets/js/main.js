import { html } from "./lib/html.js";
import App from "./App.js";

const rootElement = document.getElementById("root");
const mount = (node) => {
  if (typeof window.ReactDOM.createRoot === "function") {
    const root = window.ReactDOM.createRoot(rootElement);
    root.render(node);
    return;
  }

  window.ReactDOM.render(node, rootElement);
};

const renderError = (message) => {
  mount(html`
    <div className="error-shell">
      <div>
        <p className="eyebrow">GradCafe Dashboard</p>
        <h1>Could not load the snapshot.</h1>
        <p>${message}</p>
      </div>
    </div>
  `);
};

fetch("./data/gradcafe.json")
  .then((response) => {
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    return response.json();
  })
  .then((payload) => {
    mount(html`<${App} payload=${payload} />`);
  })
  .catch((error) => {
    renderError(error.message);
  });
