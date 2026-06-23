import fs from "node:fs";
import path from "node:path";

const outDir = path.join("output", "polisci_analysis");
fs.mkdirSync(outDir, { recursive: true });

const baseUrl = "https://www.thegradcafe.com/survey";
const queries = ["political science", "international relations", "politics", "government"];
const targetYears = Array.from({ length: 11 }, (_, i) => 2016 + i);
const seasonCodes = Object.fromEntries(targetYears.map((year) => [year, `F${String(year).slice(2)}`]));
const maxPagesPerQuery = Number(process.env.GRADCAFE_MAX_PAGES || 2000);
const supplementPagesPerQuery = Number(process.env.GRADCAFE_SUPPLEMENT_PAGES || 80);
const concurrency = Number(process.env.GRADCAFE_CONCURRENCY || 8);
const fetchTimeoutMs = Number(process.env.GRADCAFE_FETCH_TIMEOUT_MS || 120000);
const fetchRetries = Number(process.env.GRADCAFE_FETCH_RETRIES || 2);
const userAgent =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

function surveyUrl(query, page, extra = {}) {
  const params = new URLSearchParams({ q: query, sort: "newest", page: String(page), ...extra });
  return `${baseUrl}?${params.toString()}`;
}

function decodeHtmlEntities(value) {
  return String(value ?? "")
    .replaceAll("&quot;", "\"")
    .replaceAll("&#039;", "'")
    .replaceAll("&#x27;", "'")
    .replaceAll("&amp;", "&");
}

function scalarString(value) {
  if (value === null || value === undefined || value === "") return "";
  return decodeHtmlEntities(value);
}

function scalarNumber(value) {
  const number = Number(value);
  if (!Number.isFinite(number) || number === 0) return "";
  return number;
}

function scalarDate(value) {
  const text = scalarString(value);
  return text ? text.slice(0, 10) : "";
}

function statusLabel(value) {
  const text = scalarString(value);
  return ["American", "International", "Other"].includes(text) ? text : "Unknown";
}

async function fetchWithRetry(url) {
  let lastError;
  for (let attempt = 0; attempt <= fetchRetries; attempt += 1) {
    try {
      const response = await fetch(url, {
        headers: { "user-agent": userAgent },
        signal: AbortSignal.timeout(fetchTimeoutMs),
      });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      return response;
    } catch (error) {
      lastError = error;
      if (attempt < fetchRetries) {
        console.error(`retry ${attempt + 1}/${fetchRetries}: ${url} (${error.message})`);
      }
    }
  }
  throw new Error(`${lastError.message} for ${url}`);
}

async function fetchPayload(url) {
  const response = await fetchWithRetry(url);
  const html = await response.text();
  const match = html.match(/data-page="([^"]+)"/);
  if (!match) {
    throw new Error(`No data-page JSON payload found for ${url}`);
  }
  return JSON.parse(decodeHtmlEntities(match[1]));
}

function recordToRow(record, queryTerm, sourceUrl, sourcePage, sourceMode) {
  let gpa = scalarNumber(record.ugpa);
  if (gpa !== "" && gpa > 4.5) gpa = "";
  const decisionDate = scalarDate(record.date_of_notification);
  const decision = scalarString(record.decision);
  let decisionText = scalarString(record.decision_label);
  if (!decisionText && decision && decisionDate) {
    const date = new Date(`${decisionDate}T00:00:00Z`);
    decisionText = `${decision} on ${date.toLocaleString("en-US", { month: "short", day: "2-digit", timeZone: "UTC" })}`;
  }

  return {
    result_id: scalarString(record.id),
    school: scalarString(record.school),
    program: scalarString(record.program),
    degree: scalarString(record.level),
    decision_type: decision,
    decision_text: decisionText,
    decision_date: decisionDate,
    added_date: scalarDate(record.created_at),
    season: scalarString(record.season),
    status: statusLabel(record.status),
    gpa,
    gre_v: scalarNumber(record.grev),
    gre_q: scalarNumber(record.greq),
    gre_aw: scalarNumber(record.grew),
    gre_total: scalarNumber(record.gres),
    notes: scalarString(record.notes),
    query_term: queryTerm,
    source_mode: sourceMode,
    source_url: sourceUrl,
    source_page: sourcePage,
  };
}

async function fetchPage(query, page, extra, sourceMode) {
  const url = surveyUrl(query, page, extra);
  const payload = await fetchPayload(url);
  const results = payload.props.results;
  const rows = (results.data || []).map((record) => recordToRow(record, query, url, page, sourceMode));
  return { rows, meta: results.meta || {}, url };
}

async function mapLimit(items, limit, mapper) {
  const results = new Array(items.length);
  let index = 0;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (index < items.length) {
      const current = index++;
      results[current] = await mapper(items[current], current);
    }
  });
  await Promise.all(workers);
  return results;
}

async function scrapeJob(query, extra, sourceMode, maxPages) {
  const first = await fetchPage(query, 1, extra, sourceMode);
  const lastPage = Math.min(Number(first.meta.last_page || 1), maxPages);
  const pages = Array.from({ length: Math.max(lastPage - 1, 0) }, (_, i) => i + 2);
  const rest = await mapLimit(pages, concurrency, async (page) => fetchPage(query, page, extra, sourceMode));
  const all = [first, ...rest];
  for (const pageResult of all) {
    if (pageResult.rows.length > 0) {
      const dates = pageResult.rows.map((row) => row.decision_date).filter(Boolean).sort();
      const oldest = dates[0] || "NA";
      const newest = dates[dates.length - 1] || "NA";
      console.error(`${sourceMode}: ${query} ${extra.season || ""} page ${pageResult.rows[0].source_page}/${lastPage}: ${pageResult.rows.length} rows, dates ${oldest} to ${newest}`);
    }
  }
  return all.flatMap((pageResult) => pageResult.rows);
}

function csvEscape(value) {
  if (value === null || value === undefined || value === "") return "";
  const text = String(value);
  if (/[",\r\n]/.test(text)) {
    return `"${text.replaceAll("\"", "\"\"")}"`;
  }
  return text;
}

function writeCsv(rows, filePath) {
  const headers = [
    "result_id",
    "school",
    "program",
    "degree",
    "decision_type",
    "decision_text",
    "decision_date",
    "added_date",
    "season",
    "status",
    "gpa",
    "gre_v",
    "gre_q",
    "gre_aw",
    "gre_total",
    "notes",
    "query_term",
    "source_mode",
    "source_url",
    "source_page",
  ];
  const lines = [headers.join(",")];
  for (const row of rows) {
    lines.push(headers.map((header) => csvEscape(row[header])).join(","));
  }
  fs.writeFileSync(filePath, `${lines.join("\n")}\n`, "utf8");
}

const seasonRows = [];
for (const query of queries) {
  for (const year of targetYears) {
    console.error(`\n--- Query: ${query} | Season: ${seasonCodes[year]} ---`);
    seasonRows.push(...await scrapeJob(query, { season: seasonCodes[year] }, "season", maxPagesPerQuery));
  }
}

const supplementRows = [];
for (const query of queries) {
  console.error(`\n--- Query supplement: ${query} ---`);
  supplementRows.push(...await scrapeJob(query, {}, "no-season-supplement", supplementPagesPerQuery));
}

const rows = [...seasonRows, ...supplementRows];
writeCsv(rows, path.join(outDir, "gradcafe_polisci_2016_2026_raw.csv"));
console.log(`Raw rows: ${rows.length}`);
