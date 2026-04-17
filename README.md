# GradCafe 2016-2026 political science PhD trend analysis

[한국어](#한국어) | [English](#english)

---

## 한국어

2016년부터 2026년까지의 GradCafe 자기보고 데이터를 바탕으로 정치학 PhD 어드미션 흐름을 정리한 프로젝트입니다.

해마다 같은 방식으로 데이터를 모으고, 같은 규칙으로 정리한 뒤, Shiny 대시보드에서 결과를 바로 확인할 수 있게 했습니다.

저장소 안에는 **GitHub Pages용 정적 React 사이트**도 함께 들어 있습니다. Shiny를 서버에 올리지 않아도 `site/` 폴더만으로 브라우저에서 학교 검색, 필터링, 타임라인, 결과표를 확인할 수 있습니다. GradCafe 사이트가 기존 HTML 표 대신 현재 survey 데이터를 JSON으로 제공하는 구조에 맞춰, 새 스크래퍼와 Pages 데이터 export도 JSON 기반 cleaned 데이터로 갱신했습니다.

사이트 주소: <https://ye-rim-oh.github.io/GradCafe/>

### 데이터와 사이트

JSON 스크래퍼가 만든 cleaned 데이터가 `site/data/gradcafe.json`으로 export되고, GitHub Pages 홈페이지는 이 파일을 읽어 필터와 시각화를 구성합니다.

Shiny 앱도 같은 cleaned 데이터를 기준으로 실행됩니다.

### 파이프라인

| 단계 | 스크립트 | 입력 | 출력 |
| ---: | --- | --- | --- |
| 1 | `scripts/R/scrape_gradcafe_polisci.R` | GradCafe survey data | `output/polisci_analysis/gradcafe_polisci_2016_2026_clean.rds` |
| 2 | `scripts/R/analyze_gradcafe_polisci.R` | 정제 데이터 | `gradcafe_polisci_2016_2026_analysis.md` |
| 3 | `scripts/export_dashboard_data.R` + `site/` | 정제 데이터 | GitHub Pages용 `site/data/gradcafe.json` |
| 4 | `app_functions.R` + `app.R` | 같은 정제 데이터 | 로컬 또는 배포용 Shiny 대시보드 |

### 주요 파일

| 파일 | 설명 |
| --- | --- |
| `scripts/R/scrape_gradcafe_polisci.R` | 2016-2026 데이터를 현재 GradCafe survey 구조에 맞춰 수집 |
| `scripts/R/update_polisci_data.R` | 수집, 분석, Pages 데이터 export를 한 번에 실행 |
| `app_functions.R` | 데이터 로딩, 정제, 정규화, 보조 함수 |
| `app.R` | Shiny UI와 서버 로직 |
| `scripts/export_dashboard_data.R` | 정제된 데이터를 `site/data/gradcafe.json`으로 내보냄 |
| `site/` | GitHub Pages에 배포되는 정적 React 사이트 |
| `legacy_code/html_version/` | 기존 HTML-table 파서와 2020-2026 Shiny 버전 보관본 |
| `gradcafe_polisci_2016_2026_analysis.md` | 현재 cleaned 데이터 기반 분석 리포트 |
| `legacy_code/` | 예전 스크립트와 이전 구조 보관본 |

### 스크래퍼 동작 방식

스크래퍼는 `political science`, `international relations`, `politics`, `government` 네 가지 검색어와 Fall 2016-2026 season 필터로 GradCafe survey 데이터를 조회합니다.

그다음 아래 규칙으로 정리합니다.

- GradCafe 페이지의 Inertia `data-page` JSON payload에서 결과 행을 추출합니다.
- 결정 유형, 날짜, GRE, GPA, 국적 태그, 노트를 추출합니다.
- `(school, decision_text, notes, added_date)` 기준으로 중복을 제거합니다.
- `degree == "PhD"`만 남깁니다.
- `program` 문자열을 정규화한 뒤 목표 전공만 유지합니다.
- 노트 내용을 바탕으로 `CP`, `IR`, `AP`, `Theory`, `Methods`, `Public Law/Policy`, `Psych/Behavior`, `Unknown` 태그를 붙입니다.

### 앱 전처리

시각화 전에 앱 단계에서 한 번 더 정리합니다.

- 복원 가능한 경우 `gre_total`을 바탕으로 `gre_q`를 되살립니다.
- 비정상적인 GRE와 AW 값을 제거합니다.
- 연도 비교가 가능하도록 타임라인 날짜를 표준화합니다.
- 노이즈 행을 걸러내고 학교명을 규칙 기반으로 통합합니다.

### 웹사이트 구성

- `Decision timeline`: 날짜축 위에서 결과 시점을 확인하는 메인 섹션
- `All results`: 검색 가능한 원자료 테이블
- `Additional analysis`: 연도별 합격률, 국적 분포, 서브필드별 표본 수와 합격률

### 의존 패키지

- R (>= 4.0)
- `rvest`, `httr`, `dplyr`, `tidyr`, `lubridate`, `stringr`, `plotly`, `ggplot2`, `rmarkdown`, `knitr`, `kableExtra`, `shiny`, `shinyjs`, `shinyWidgets`, `DT`

한 번만 설치하면 됩니다.

```r
install.packages(c("rvest", "httr", "dplyr", "tidyr", "lubridate", "stringr",
                   "plotly", "ggplot2", "rmarkdown", "knitr", "kableExtra",
                   "shiny", "shinyjs", "shinyWidgets", "DT"))
```

### 데이터 해석 시 주의

- GradCafe는 자기보고 데이터라 누락과 표본 편향이 있습니다.
- 파싱과 정규화는 규칙 기반이라 일부 예외가 남을 수 있습니다.
- 합격률 계산식은 `Accepted / (Accepted + Rejected)`입니다.
- 최신 데이터 기준일은 **2026-04-15**입니다.
- 웹사이트 표본은 **4,746건**입니다. 학교명이 아닌 잡음 행과 가짜 institution은 필터에서 제외했습니다.
- 2026 표본은 **1,030건**입니다.
- 2026 수치는 이후 게시글이 더 들어오면 달라질 수 있습니다.

### 크레딧

이 프로젝트는 **Martin Devaux**의 기존 GradCafe 정치학 PhD 분석을 바탕으로 확장했습니다.
원문: <https://www.martindevaux.com/2020/11/political-science-phd-admission-decisions/>

초기 워크플로를 공개해 준 Martin Devaux 덕분에 이후 확장 작업을 훨씬 수월하게 이어갈 수 있었습니다.

또한 결과를 꾸준히 남겨 준 GradCafe 커뮤니티 이용자들과 사이트 운영진에게도 감사드립니다. 그 기록과 플랫폼이 없었다면 이 프로젝트도 성립하지 않았을 것입니다.

데이터 출처: **[The GradCafe](https://www.thegradcafe.com/survey)**

### 레거시 코드

기존 HTML-table 파서 버전은 `legacy_code/html_version/`에 따로 모아 두었습니다. 메인 홈페이지와 기본 데이터 갱신 경로는 JSON 버전입니다.

이전 스크립트와 예전 프로젝트 구조는 `legacy_code/`에 보관되어 있습니다.

---

## English

This repository tracks self-reported GradCafe outcomes for political science PhD admissions from 2016 through 2026.

The point is straightforward: scrape each cycle the same way, clean it with the same rules, and make the results easy to inspect in a Shiny dashboard.

The repository now also includes a **GitHub Pages-ready static React dashboard** in `site/`. That version keeps the shared filters and tabs in the browser, so it can be deployed for free without running a Shiny server. Because GradCafe's current survey pages are no longer reliably available as the old HTML table, the scraper and Pages export now use the current JSON-backed survey data path.

Static site: <https://ye-rim-oh.github.io/GradCafe/>

### Data and Site

The JSON scraper produces cleaned data, exports it to `site/data/gradcafe.json`, and the GitHub Pages homepage reads that file to build the filters and visualizations.

The Shiny app uses the same cleaned data.

### Pipeline

| Step | Script | Input | Output |
| ---: | --- | --- | --- |
| 1 | `scripts/R/scrape_gradcafe_polisci.R` | GradCafe survey data | `output/polisci_analysis/gradcafe_polisci_2016_2026_clean.rds` |
| 2 | `scripts/R/analyze_gradcafe_polisci.R` | Cleaned data | `gradcafe_polisci_2016_2026_analysis.md` |
| 3 | `scripts/export_dashboard_data.R` + `site/` | Cleaned data | `site/data/gradcafe.json` for GitHub Pages |
| 4 | `app_functions.R` + `app.R` | Same cleaned data | Local or deployed Shiny dashboard |

### Main files

| File | Description |
| --- | --- |
| `scripts/R/scrape_gradcafe_polisci.R` | Scrapes 2016-2026 data against the current GradCafe survey structure |
| `scripts/R/update_polisci_data.R` | Runs scrape, analysis, and Pages data export together |
| `app_functions.R` | Data loading, cleanup, normalization, and helper functions |
| `app.R` | Shiny UI and server logic |
| `scripts/export_dashboard_data.R` | Exports the cleaned dataset to `site/data/gradcafe.json` |
| `site/` | Static React dashboard deployed to GitHub Pages |
| `legacy_code/html_version/` | Archived HTML-table parser and 2020-2026 Shiny version |
| `gradcafe_polisci_2016_2026_analysis.md` | Current analysis report generated from the cleaned dataset |
| `legacy_code/` | Older scripts and the previous project structure |

### How the scraper works

The scraper queries GradCafe survey data with four broad terms: `political science`, `international relations`, `politics`, and `government`, combined with Fall 2016-2026 season filters.

It then applies the same cleanup rules each year.

- It extracts result rows from the Inertia `data-page` JSON payload embedded in the survey page.
- It extracts decision labels, dates, GRE, GPA, nationality tags, and notes.
- It removes duplicates with `(school, decision_text, notes, added_date)`.
- It keeps only `degree == "PhD"`.
- It normalizes `program` text and keeps only the target majors.
- It tags subfields from notes: `CP`, `IR`, `AP`, `Theory`, `Methods`, `Public Law/Policy`, `Psych/Behavior`, and `Unknown`.

### App-side cleanup

Before plotting, the app makes one more cleanup pass.

- It recovers missing `gre_q` values from `gre_total` when possible.
- It removes impossible GRE and AW values.
- It standardizes timeline dates for cross-year comparison.
- It drops obvious junk rows and normalizes institution names with a rule map.

### Site sections

- `Decision timeline`: decision timing on a date axis
- `All results`: searchable raw table
- `Additional analysis`: yearly acceptance rates, nationality splits, subfield volume, and subfield-specific acceptance rates

### Dependencies

- R (>= 4.0)
- `rvest`, `httr`, `dplyr`, `tidyr`, `lubridate`, `stringr`, `plotly`, `ggplot2`, `rmarkdown`, `knitr`, `kableExtra`, `shiny`, `shinyjs`, `shinyWidgets`, `DT`

Install once:

```r
install.packages(c("rvest", "httr", "dplyr", "tidyr", "lubridate", "stringr",
                   "plotly", "ggplot2", "rmarkdown", "knitr", "kableExtra",
                   "shiny", "shinyjs", "shinyWidgets", "DT"))
```

### Data notes

- The source is self-reported GradCafe data, so missingness and reporting bias are unavoidable.
- Parsing and normalization are rule-based, so some edge cases may still remain.
- Acceptance rate is defined as `Accepted / (Accepted + Rejected)`.
- Latest data date: **April 15, 2026**
- Website rows: **4,746**. Non-school noise rows and fake institution labels are excluded from the public dashboard.
- 2026 rows: **1,030**
- The 2026 snapshot will keep moving as new posts appear.

### Credits

This repository extends the earlier GradCafe political science PhD analysis by **Martin Devaux**.
Original post: <https://www.martindevaux.com/2020/11/political-science-phd-admission-decisions/>

Martin published the original workflow clearly, and that made this extension much easier to build and maintain.

I also owe a lot to the GradCafe community and the site maintainers. Without their posts and the platform itself, there would be nothing here to analyze.

Data source: **[The GradCafe](https://www.thegradcafe.com/survey)**

### Legacy code

The previous HTML-table parser version is now grouped under `legacy_code/html_version/`. The main homepage and default refresh path use the JSON version.

Older scripts and the previous project structure are preserved in `legacy_code/`.

