# 2026 GradCafe Political Science PhD Admission Analysis

- **Report Date**: 2026-06-23
- **Data Source**: GradCafe survey data refreshed through 2026-05-19
- **Analysis Scope**: Fall 2026 PhD entries in Political Science, International Relations, Politics, Government, and direct combinations
- **Total Sample**: **1,033** cleaned posts

This note summarizes the 2026 application-cycle snapshot only. It is descriptive, not causal.

## 1. Decision Mix and Acceptance Rate

| Year | Total Cases | Accepted | Rejected | Interview | Wait listed | Other | Accept Rate |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2026 | 1033 | 266 | 591 | 43 | 133 | 0 | 31.0% |

Accept rate is calculated as `Accepted / (Accepted + Rejected)`. Interview, waitlist, and other rows are excluded from the denominator.

Quick read:
- The 2026 sample has **1033** posts.
- The overall 2026 acceptance rate is **31.0%** among accepted/rejected posts.
- The latest decision date in the exported dataset is **2026-05-19**.

## 2. Nationality Split

### 2.1 2026 Acceptance Rate by Nationality

| Year | American | International |
| --- | --- | --- |
| 2026 | 34.9% | 26.8% |

### 2.2 2026 Breakdown

| Year | Status | Total Cases | Accepted | Rejected | Interview | Wait listed | Other | Accept Rate |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2026 | American | 438 | 129 | 241 | 19 | 49 | 0 | 34.9% |
| 2026 | International | 580 | 127 | 347 | 24 | 82 | 0 | 26.8% |

In 2026, the American-International gap is **8.1 percentage points**. This is a reporting snapshot, not an estimate of admission odds.

## 3. Subfield Snapshot

### 3.1 Subfield Volume

| Year | AP | CP | IR | Methods | Psych/Behavior | Public Law/Policy | Theory | Unknown |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2026 | 53 | 90 | 72 | 17 | 1 | 6 | 24 | 770 |

### 3.2 Subfield Acceptance Rate

| Year | AP | CP | IR | Theory | Methods | Public Law/Policy |
| --- | --- | --- | --- | --- | --- | --- |
| 2026 | 53.7% | 44.0% | 50.0% | 55.0% | 31.2% | 33.3% |

Most rows are still tagged as Unknown (**74.5%** of 2026 rows), so subfield tables are useful for direction but not for strict ranking.

## 4. GRE/GPA Summary (2026, Accepted vs Rejected)

| Year | Decision | GRE V n | GRE V mean | GRE Q n | GRE Q mean | GRE AW n | GRE AW mean | GPA n | GPA mean |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2026 | Accepted | 84 | 164.5 | 77 | 165.6 | 75 | 4.69 | 195 | 3.89 |
| 2026 | Rejected | 171 | 163.6 | 153 | 165.4 | 142 | 4.66 | 381 | 3.86 |

GRE and GPA fields are self-reported and optional, so these means come from a selective subset.

## 5. GRE/GPA vs Outcome Correlation (2026)

Accepted is coded as 1, Rejected as 0, and Pearson correlation is used.

| Metric | Valid N | Correlation r | p-value | Interpretation |
| --- | --- | --- | --- | --- |
| GPA | 576 | 0.120 | 0.0040 | Very weak linear correlation |
| GRE V | 255 | 0.094 | 0.1335 | Very weak linear correlation |
| GRE Q | 230 | 0.017 | 0.7992 | No meaningful linear correlation |
| GRE AW | 217 | 0.016 | 0.8109 | No meaningful linear correlation |

These are small observational correlations and should not be interpreted as causal.

## 6. Decision Timeline Markers

The timeline table uses January-April decision dates only, because later dates often reflect off-cycle updates, historical cleanup, or season-label artifacts.

| Year | Start | 25% | Median | 75% | End |
| --- | --- | --- | --- | --- | --- |
| 2026 | 01/01 | 02/04 | 02/12 | 02/19 | 04/24 (n=1031) |

## 7. Master Summary Table

| Year | Total Cases | Overall Accept Rate | American Cases | American Accept Rate | International Cases | International Accept Rate | GRE V n | GRE V mean | GRE Q n | GRE Q mean | GPA Reporting Rate | Timeline Start | Timeline 75% |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2026 | 1033 | 31.0% | 438 | 34.9% | 580 | 26.8% | 284 | 163.8 | 257 | 165.6 | 64.6% | 01/01 | 02/19 |

## 8. Takeaways

1. The 2026 sample contains 1,033 cleaned posts across 115 canonical institutions.
2. The overall acceptance rate is 31.0%, based only on accepted and rejected posts.
3. In 2026, American and international acceptance rates are 34.9% and 26.8%, a gap of 8.1 percentage points.
4. Subfield information is sparse: 74.5% of 2026 rows are tagged Unknown.
5. GRE/GPA fields are optional and self-reported, so their correlations with outcomes remain descriptive rather than predictive.

## Fall 2026 Snapshot

- Total posts: **1033**
- Overall acceptance rate: **31.0%**
- American vs International: **34.9% vs 26.8%**
- Latest decision date in the dataset: **2026-05-19**

## Method Notes

- Source: user-reported GradCafe posts.
- Scope: Fall 2026 PhD entries filtered to Political Science, International Relations, Politics, Government, and direct combinations.
- Cleaning: program labels and school names are rule-normalized; obvious junk or truncated school labels are filtered or repaired.
- Collection: season-filtered pages are supplemented with recent no-season pages; **513** clean rows currently come from that supplement path.
- Unit of observation: each row is a reported school-level outcome, not a distinct applicant. One applicant may apply to multiple schools and report multiple outcomes, so 12 reported cases do not necessarily mean 12 distinct people. It could just as easily mean 6 people reporting 2 schools each, or 3 people reporting 4 schools each.
- Interpretation: use these numbers as a directional snapshot, not a full census.
