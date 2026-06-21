# 2026 GradCafe Political Science PhD Snapshot

**Report Date**: 2026-04-17
**Data Source**: GradCafe survey data exported on 2026-04-17
**Analysis Scope**: Fall 2026 Political Science PhD entries only
**Total Sample**: **1,030** cleaned posts

This note summarizes the 2026 application-cycle snapshot only. It is descriptive, not causal.

## 1. Decision Mix and Acceptance Rate

| Year | Total Cases | Accepted | Rejected | Interview | Wait listed | Other | Accept Rate |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2026 | 1030 | 262 | 587 | 43 | 138 | 0 | 30.9% |

Accept rate is calculated as Accepted / (Accepted + Rejected). Interview, waitlist, and other rows are excluded from the denominator.

Quick read:
- The 2026 sample has **1,030** posts.
- The overall 2026 acceptance rate is **30.9%** among accepted/rejected posts.
- The latest 2026 decision date in the exported dataset is **04/15**.

## 2. Nationality Split

| Status | Total Cases | Accepted | Rejected | Interview | Wait listed | Other | Accept Rate |
| --- | --- | --- | --- | --- | --- | --- | --- |
| American | 438 | 128 | 240 | 19 | 51 | 0 | 34.8% |
| International | 577 | 124 | 344 | 24 | 85 | 0 | 26.5% |

In 2026, the American-International acceptance-rate gap is **8.3 percentage points**. This is a reporting snapshot, not an estimate of admission odds.

## 3. Subfield Snapshot

### 3.1 Subfield Volume

| Subfield | Total Cases |
| --- | --- |
| AP | 53 |
| CP | 90 |
| IR | 72 |
| Methods | 17 |
| Psych/Behavior | 1 |
| Public Law/Policy | 6 |
| Theory | 24 |
| Unknown | 767 |

### 3.2 Subfield Acceptance Rate

| Subfield | Accepted/Rejected N | Accept Rate |
| --- | --- | --- |
| AP | 40 | 52.5% |
| CP | 74 | 43.2% |
| IR | 65 | 50.8% |
| Theory | 19 | 52.6% |
| Methods | 16 | 31.2% |
| Public Law/Policy | 6 | 33.3% |

Subfield information remains sparse: **74.5%** of 2026 rows are tagged Unknown, so subfield tables are useful for direction but not for strict ranking.

## 4. GRE/GPA Summary

| Decision | GRE V n | GRE V mean | GRE Q n | GRE Q mean | GPA n | GPA mean |
| --- | --- | --- | --- | --- | --- | --- |
| Accepted | 83 | 164.5 | 39 | 165.0 | 193 | 3.89 |
| Rejected | 168 | 163.6 | 58 | 165.0 | 378 | 3.86 |

GRE and GPA fields are self-reported and optional, so these means come from a selective subset.

## 5. GPA/GRE and Admission Outcome

Accepted is coded as 1 and Rejected as 0. Pearson r is therefore a point-biserial correlation between each reported metric and the binary outcome.

| Metric | Valid N | Accepted Mean | Rejected Mean | Difference | Correlation r | p-value | Interpretation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GPA | 571 | 3.89 | 3.86 | 0.04 | 0.120 | 0.0041 | Very weak linear relationship |
| GRE V | 251 | 164.5 | 163.6 | 0.8 | 0.089 | 0.1616 | Very weak linear relationship |
| GRE Q | 97 | 165.0 | 165.0 | 0.0 | 0.003 | 0.9744 | No meaningful linear relationship |

The 2026 snapshot shows a very weak positive GPA-outcome correlation, a very weak positive GRE V correlation, and no meaningful GRE Q correlation. These are descriptive associations from self-reported posts, not causal estimates or individual-level prediction rules.

## 6. Decision Timeline Markers

The timeline table uses January-April decision dates only, because later dates often reflect off-cycle updates, historical cleanup, or season-label artifacts.

| Start | 25% | Median | 75% | End |
| --- | --- | --- | --- | --- |
| 01/01 | 02/04 | 02/12 | 02/19 | 04/15 (n=1029) |

## 7. Takeaways

1. The 2026 sample contains 1,030 cleaned Political Science PhD posts.
2. The overall acceptance rate is 30.9%, based only on accepted and rejected posts.
3. American and international acceptance rates are 34.8% and 26.5%, a gap of 8.3 percentage points.
4. Subfield information is sparse: 74.5% of 2026 rows are tagged Unknown.
5. GPA is reported for 64.7% of 2026 rows; the observed GPA/GRE correlations with acceptance are weak to negligible.

## Method Notes

- Source: user-reported GradCafe posts.
- Scope: Fall 2026 PhD entries filtered to Political Science, International Relations, Politics, Government, and direct combinations.
- Cleaning: program labels and school names are rule-normalized; obvious junk or truncated school labels are filtered or repaired before export.
- Unit of observation: each row is a reported school-level outcome, not a distinct applicant. One applicant may apply to multiple schools and report multiple outcomes.
- Interpretation: use these numbers as a directional snapshot, not a full census.
