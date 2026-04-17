# GradCafe UI Design Direction

## Goal

The site should feel like a public data note and admissions-result index, not a SaaS dashboard. The main user is a political science PhD applicant who wants to search by school, year, decision type, and notes without learning a complex dashboard.

## Approved Title

Political Science PhD Results (2016-2026)

Avoid "Dashboard" in the main title. Do not show row-count badges or the HTML version link in the primary UI.

The title should be prominent but not oversized. It should read as a page title for a search tool, not as a landing-page hero headline.

## Visual Direction

Use a light gray page background with white panels. The tone should be closer to a clean data article or archive page than a dark analytics app.

Core changes from the current look:

- Remove the black background.
- Remove purple radial gradients and glassmorphism.
- Remove heavy glowing or floating-card effects.
- Reduce large border radii.
- Use thin borders, typography, and spacing for structure.
- Keep the app functional, but make the presentation document-like.

## Palette

- Page background: very light cool gray.
- Panels: white or near-white.
- Primary text: charcoal or ink.
- Secondary text: medium neutral gray.
- Main accent: restrained deep blue.
- Secondary accent: muted olive gray.
- Rejection/negative color: restrained red.
- Interview/waitlist colors: soft green and ochre.

Decision colors should stay distinguishable but lower in saturation than the current dashboard colors.

## Layout

Keep the current high-level structure:

- Left panel: school search and filters.
- Right panel: title, active filter summary, timeline, results table, optional additional analysis.

The left panel should feel like a document index panel rather than an app sidebar. The right panel should read as a sequence of sections rather than nested dashboard cards.

## Components

School search remains the first control because it is the main action.

Year and decision filters can remain checkbox or pill based, but the visual treatment should be quieter. They should read as compact filter controls rather than large buttons.

Timeline should be treated like a figure:

- White or near-white figure area.
- Thin border or divider.
- Light grid lines.
- Muted decision colors.
- Minimal decorative framing.
- Do not label it "Figure 1" in the public UI.

Results should be treated like a data table:

- Thin row dividers.
- Stable column widths.
- Slightly more open row spacing.
- Notes should use a 2-3 line preview with expand behavior, rather than forcing every long note to fully expand the row by default.
- Do not label it "Table 1" in the public UI.

## Copy

Use minimal, functional copy. Do not include a general helper subtitle under the title by default; the school search field and filter controls are sufficient to communicate how the site works.

A compact active-filter summary may appear under the title, for example:

University of Toronto (UofT) · 2024-2026 · 4 decision types

Avoid long explanatory text on the first screen. Detailed methodology belongs in README or the analysis markdown.

## Implementation Constraints

Change visual styling without changing the data pipeline.

Keep the current static GitHub Pages architecture:

- site/data/gradcafe.json remains the source for the public site.
- Existing filters and table behavior should remain intact unless explicitly changed.
- The HTML version should remain reachable if needed, but it should not be a primary UI element.

## Open Detail

When implemented, decide whether the notes expansion should be row-local with a small "more" control or table-level with expanded row state. The preferred direction is row-local expansion.
