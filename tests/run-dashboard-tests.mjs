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
assert.equal(payload.recordCount, 4746);
assert.equal(payload.seasonRange, "2016-2026");
assert.equal(payload.latestDecisionDate, "2026-04-15");
assert.deepEqual(DEFAULT_DECISIONS, ["Accepted", "Rejected", "Interview", "Wait listed", "Other"]);

const years = getYears(payload.records);
assert.equal(years[0], 2026);
assert.equal(years[years.length - 1], 2016);

const institutions = getInstitutions(payload.records);
assert.equal(OVERALL_LABEL, "");
assert.equal(institutions.filter((institution) => /^(all|overall|overall \(all schools\))$/i.test(institution)).length, 0);
assert.ok(institutions.includes("University of Toronto (UofT)"));
assert.ok(institutions.includes("Northern Illinois University (NIU)"));
assert.ok(institutions.includes("University of California, Berkeley (UCB)"));
assert.ok(institutions.includes("University of Massachusetts Amherst (UMass)"));
assert.equal(
  payload.records.filter((record) => /the university of toront/i.test(record.institution)).length,
  0
);
assert.equal(
  payload.records.filter((record) =>
    /^(all|overall|overall \(all schools\)|nsf grfp|sis|coomtown university)$/i.test(record.institution) ||
    /Berkekey|Berkely|Berekeley|George Washingon|U Mass|UMASS|UCONN|UPENN|FLETCHER|KORBEL|UFL OR UF/.test(record.institution)
  ).length,
  0
);

console.log("dashboard data tests passed");
