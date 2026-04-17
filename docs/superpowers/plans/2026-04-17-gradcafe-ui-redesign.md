# GradCafe UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved light-gray/white data-note visual direction to the GitHub Pages site.

**Architecture:** Keep the existing static React-style component structure and JSON data flow. Change presentation in `site/assets/css/styles.css`, adjust title/header copy in `site/assets/js/App.js`, and add row-local notes expansion in `site/assets/js/components/views/DataView.js`.

**Tech Stack:** Static GitHub Pages, vanilla CSS, React/htm modules, Node tests, R export/tests.

---

### Task 1: Header and Copy

**Files:**
- Modify: `site/assets/js/App.js`

- [x] Remove row-count and HTML-version badges from the primary UI.
- [x] Move the approved title into the main content header: `Political Science PhD Results (2016-2026)`.
- [x] Remove dashboard wording from visible copy.
- [x] Keep a compact active-filter summary only.

### Task 2: Notes Preview

**Files:**
- Modify: `site/assets/js/components/views/DataView.js`

- [x] Track expanded row IDs in local component state.
- [x] Render notes as a 2-3 line preview by default.
- [x] Add a row-local Show more / Show less button only when a note is long enough to need it.

### Task 3: Visual Styling

**Files:**
- Modify: `site/assets/css/styles.css`

- [x] Replace the dark dashboard palette with light gray page background and white panels.
- [x] Remove purple gradients, glass effects, and large rounded containers.
- [x] Use thin borders, compact radii, restrained decision colors, and document-like table styling.
- [x] Keep responsive behavior intact.

### Task 4: Verification

**Files:**
- Modify: `tests/run-dashboard-tests.mjs` if the UI behavior needs a static assertion.

- [x] Run `node --check` on changed JavaScript files.
- [x] Run `cmd /c npm test`.
- [x] Run `Rscript tests/run-normalization-tests.R`.
- [x] Run `git diff --check`.
- [x] Confirm no `Dashboard`, row-count badge, `HTML version`, `Figure 1`, or `Table 1` remains in primary site UI.

### Task 5: Publish

- [x] Remove temporary preview files once implementation is complete.
- [ ] Commit the UI changes.
- [ ] Push `polsci-site-json-data` and update `master` for GitHub Pages.
