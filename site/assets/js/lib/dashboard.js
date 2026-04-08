export const OVERALL_LABEL = "Overall (All Schools)";
export const DEFAULT_DECISIONS = ["Accepted", "Rejected", "Interview", "Wait listed"];
export const DECISION_ORDER = ["Accepted", "Interview", "Wait listed", "Rejected", "Other"];
export const DECISION_COLORS = {
  Accepted: "#2563eb",
  Interview: "#16a34a",
  "Wait listed": "#ea580c",
  Rejected: "#dc2626",
  Other: "#64748b"
};
export const STATUS_COLORS = {
  American: "#2563eb",
  International: "#dc2626"
};
export const SUBFIELD_COLORS = {
  CP: "#6482A6",
  IR: "#CC7E7E",
  AP: "#729C7A",
  Theory: "#927AA6",
  Methods: "#D49D75",
  "Public Law/Policy": "#659AA6",
  "Psych/Behavior": "#B07590"
};

const ACCEPT_REJECT_DECISIONS = new Set(["Accepted", "Rejected"]);
const SUBFIELD_RATE_FIELDS = new Set(["CP", "IR", "AP", "Theory", "Methods"]);

const byYear = (left, right) => left.decisionYear - right.decisionYear;
const byYearAndSubfield = (left, right) =>
  left.decisionYear - right.decisionYear || left.subfield.localeCompare(right.subfield);

const formatMonthDay = (value) => {
  if (!value) {
    return "N/A";
  }

  const parts = value.split("-");
  return parts.length === 3 ? `${parts[1]}/${parts[2]}` : "N/A";
};

const firstDateForDecision = (records, decision) => {
  const candidates = records
    .filter((record) => record.decision === decision && record.decisionMonthDay)
    .map((record) => record.decisionMonthDay)
    .sort();

  return candidates.length > 0 ? formatMonthDay(candidates[0]) : "N/A";
};

const recordsForInstitution = (records, institution) => {
  if (!institution || institution === OVERALL_LABEL) {
    return [...records];
  }

  return records.filter((record) => record.institution === institution);
};

const acceptedRejectedOnly = (records) =>
  records.filter((record) => ACCEPT_REJECT_DECISIONS.has(record.decision));

export const applyFilters = (records, filters) =>
  records.filter((record) => {
    const institutionMatch =
      !filters.institution ||
      filters.institution === OVERALL_LABEL ||
      record.institution === filters.institution;
    const yearMatch = !filters.years?.length || filters.years.includes(record.decisionYear);
    const decisionMatch =
      !filters.decisions?.length || filters.decisions.includes(record.decision);

    return institutionMatch && yearMatch && decisionMatch;
  });

export const matchesSearchQuery = (record, query) => {
  const normalizedQuery = query?.trim().toLowerCase();

  if (!normalizedQuery) {
    return true;
  }

  return [
    record.institution,
    record.decision,
    String(record.decisionYear),
    record.decisionMonthDay ?? "",
    record.status ?? "",
    record.subfield ?? "",
    record.gpa ?? "",
    formatGre(record),
    record.notes ?? ""
  ]
    .join(" ")
    .toLowerCase()
    .includes(normalizedQuery);
};

export const buildKeyDateLabels = (records) => ({
  accepted: `First Acceptance: ${firstDateForDecision(records, "Accepted")}`,
  rejected: `First Rejection: ${firstDateForDecision(records, "Rejected")}`,
  interview: `First Interview: ${firstDateForDecision(records, "Interview")}`,
  waitlisted: `First Waitlist: ${firstDateForDecision(records, "Wait listed")}`
});

export const buildComparisonMetrics = (records, institution) => {
  const schoolRecords = recordsForInstitution(records, institution);
  const currentYear = Math.max(...schoolRecords.map((record) => record.decisionYear));
  const recentRecords = schoolRecords.filter((record) => record.decisionYear >= currentYear - 2);

  return [
    {
      metric: "First Acceptance",
      recent: firstDateForDecision(recentRecords, "Accepted"),
      overall: firstDateForDecision(schoolRecords, "Accepted")
    },
    {
      metric: "First Rejection",
      recent: firstDateForDecision(recentRecords, "Rejected"),
      overall: firstDateForDecision(schoolRecords, "Rejected")
    },
    {
      metric: "First Interview",
      recent: firstDateForDecision(recentRecords, "Interview"),
      overall: firstDateForDecision(schoolRecords, "Interview")
    },
    {
      metric: "First Waitlist",
      recent: firstDateForDecision(recentRecords, "Wait listed"),
      overall: firstDateForDecision(schoolRecords, "Wait listed")
    },
    {
      metric: "Total Results",
      recent: String(recentRecords.length),
      overall: String(schoolRecords.length)
    }
  ];
};

export const buildYearlyAcceptanceRates = (records, institution) => {
  const summary = new Map();

  acceptedRejectedOnly(recordsForInstitution(records, institution)).forEach((record) => {
    const row = summary.get(record.decisionYear) ?? {
      decisionYear: record.decisionYear,
      accepted: 0,
      rejected: 0,
      total: 0,
      rate: 0
    };

    if (record.decision === "Accepted") {
      row.accepted += 1;
    }

    if (record.decision === "Rejected") {
      row.rejected += 1;
    }

    row.total = row.accepted + row.rejected;
    row.rate = row.total > 0 ? (row.accepted / row.total) * 100 : 0;
    summary.set(record.decisionYear, row);
  });

  return [...summary.values()]
    .sort(byYear)
    .map((row) => ({ ...row, rate: Number(row.rate.toFixed(1)) }));
};

export const buildNationalityRates = (records, institution) => {
  const summary = new Map();

  acceptedRejectedOnly(recordsForInstitution(records, institution))
    .filter((record) => record.status === "American" || record.status === "International")
    .forEach((record) => {
      const key = `${record.decisionYear}::${record.status}`;
      const row = summary.get(key) ?? {
        decisionYear: record.decisionYear,
        status: record.status,
        accepted: 0,
        total: 0,
        rate: 0
      };

      if (record.decision === "Accepted") {
        row.accepted += 1;
      }

      row.total += 1;
      row.rate = row.total > 0 ? (row.accepted / row.total) * 100 : 0;
      summary.set(key, row);
    });

  return [...summary.values()]
    .sort((left, right) => left.decisionYear - right.decisionYear || left.status.localeCompare(right.status))
    .map(({ accepted, ...row }) => ({ ...row, rate: Number(row.rate.toFixed(1)) }));
};

export const buildSubfieldVolumeSeries = (records) => {
  const summary = new Map();

  records
    .filter((record) => record.subfield && record.subfield !== "Unknown")
    .forEach((record) => {
      const key = `${record.decisionYear}::${record.subfield}`;
      const row = summary.get(key) ?? {
        decisionYear: record.decisionYear,
        subfield: record.subfield,
        count: 0
      };

      row.count += 1;
      summary.set(key, row);
    });

  return [...summary.values()].sort(byYearAndSubfield);
};

export const buildSubfieldRateSeries = (records, minimumSample = 3) => {
  const summary = new Map();

  records
    .filter(
      (record) =>
        SUBFIELD_RATE_FIELDS.has(record.subfield) && ACCEPT_REJECT_DECISIONS.has(record.decision)
    )
    .forEach((record) => {
      const key = `${record.decisionYear}::${record.subfield}`;
      const row = summary.get(key) ?? {
        decisionYear: record.decisionYear,
        subfield: record.subfield,
        accepted: 0,
        total: 0,
        rate: 0
      };

      if (record.decision === "Accepted") {
        row.accepted += 1;
      }

      row.total += 1;
      row.rate = row.total > 0 ? (row.accepted / row.total) * 100 : 0;
      summary.set(key, row);
    });

  return [...summary.values()]
    .filter((row) => row.total >= minimumSample)
    .sort(byYearAndSubfield)
    .map(({ accepted, ...row }) => ({ ...row, rate: Number(row.rate.toFixed(1)) }));
};

export const buildTimelinePoints = (records, institution) =>
  applyFilters(recordsForInstitution(records, institution), { decisions: [], years: [] })
    .map((record, index) => ({
      ...record,
      timelineKey: `${record.institution}-${record.decisionYear}-${record.decisionMonthDay ?? "na"}-${index}`,
      sourceIndex: index
    }))
    .filter((record) => record.decisionMonthDay)
    .map((record) => ({
      ...record,
      monthDayLabel: formatMonthDay(record.decisionMonthDay)
    }))
    .sort((left, right) =>
      left.decisionMonthDay.localeCompare(right.decisionMonthDay) ||
      left.decision.localeCompare(right.decision) ||
      left.sourceIndex - right.sourceIndex
    );

export const formatGre = (record) => {
  if (record.greV && record.greQ) {
    return `V${record.greV}/Q${record.greQ}`;
  }

  if (record.greV) {
    return `V${record.greV}`;
  }

  if (record.greQ) {
    return `Q${record.greQ}`;
  }

  return "-";
};

export const buildTableRows = (records, showSchool) =>
  [...records]
    .sort((left, right) =>
      right.decisionYear - left.decisionYear ||
      (left.decisionMonthDay ?? "").localeCompare(right.decisionMonthDay ?? "")
    )
    .map((record, index) => ({
      id: `${record.institution}-${record.decisionYear}-${record.decisionMonthDay ?? "na"}-${index}`,
      school: record.institution,
      decision: record.decision,
      year: String(record.decisionYear),
      date: record.decisionMonthDay ? formatMonthDay(record.decisionMonthDay) : "-",
      status: record.status === "Unknown" ? "-" : record.status,
      subfield: record.subfield === "Unknown" ? "-" : record.subfield,
      gpa: record.gpa ?? "-",
      gre: formatGre(record),
      notes: record.notes?.trim() ? record.notes : "-",
      showSchool
    }));

export const getInstitutions = (records) => [
  OVERALL_LABEL,
  ...new Set(records.map((record) => record.institution).sort((left, right) => left.localeCompare(right)))
];

export const getYears = (records) =>
  [...new Set(records.map((record) => record.decisionYear))].sort((left, right) => right - left);
