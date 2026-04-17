import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  DEFAULT_DECISIONS,
  getInstitutions,
  getYears,
  OVERALL_LABEL
} from "../site/assets/js/lib/dashboard.js";

const payload = JSON.parse(readFileSync("site/data/gradcafe.json", "utf8"));

assert.equal(payload.recordCount, payload.records.length);
assert.equal(payload.recordCount, 4750);
assert.equal(payload.seasonRange, "2016-2026");
assert.equal(payload.latestDecisionDate, "2026-04-15");
assert.deepEqual(DEFAULT_DECISIONS, ["Accepted", "Rejected", "Interview", "Wait listed", "Other"]);

const years = getYears(payload.records);
assert.equal(years[0], 2026);
assert.equal(years[years.length - 1], 2016);

const institutions = getInstitutions(payload.records);
assert.equal(institutions[0], OVERALL_LABEL);
assert.ok(institutions.includes("University of Toronto (UofT)"));
assert.equal(
  payload.records.filter((record) => /the university of toront/i.test(record.institution)).length,
  0
);

console.log("dashboard data tests passed");
