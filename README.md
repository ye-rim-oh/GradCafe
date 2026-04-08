# GradCafe 2020-2026 political science PhD trend analysis

[한국어](#한국어) | [English](#english)

---

## 한국어

2020년부터 2026년까지의 GradCafe 자기보고 데이터를 바탕으로 정치학 PhD 어드미션 흐름을 정리한 프로젝트입니다.

해마다 같은 방식으로 데이터를 모으고, 같은 규칙으로 정리한 뒤, Shiny 대시보드에서 결과를 바로 확인할 수 있게 했습니다.

이제 저장소 안에는 **GitHub Pages용 정적 React 대시보드**도 함께 들어 있습니다. Shiny를 서버에 올리지 않아도 `site/` 폴더만으로 브라우저에서 필터링과 탭 전환이 가능한 웹 버전을 배포할 수 있습니다.

### 빠른 시작

#### GitHub Pages용 정적 사이트 갱신

```r
Rscript scripts/export_dashboard_data.R
```

그 다음 `site/index.html`을 기준으로 GitHub Pages에 배포하면 됩니다. 저장소의 Actions 탭에서 `Deploy GitHub Pages` 워크플로가 자동으로 정적 사이트를 올립니다.

#### `scraped_2020_2026_combined.Rdata`가 이미 있을 때

```r
Rscript -e "shiny::runApp('app.R')"
```

#### 처음부터 다시 수집하고 실행할 때

```r
Rscript scrape_all_years.R
Rscript -e "shiny::runApp('app.R')"
```

### 파이프라인

| 단계 | 스크립트 | 입력 | 출력 |
| ---: | --- | --- | --- |
| 1 | `scrape_all_years.R` | GradCafe 검색 페이지 | 연도별 `.Rdata` 파일과 `scraped_2020_2026_combined.Rdata` |
| 2 | `app_functions.R` + `app.R` | `scraped_2020_2026_combined.Rdata` | 로컬 또는 배포용 Shiny 대시보드 |
| 3 | `scripts/export_dashboard_data.R` + `site/` | 정제된 `data` 객체 | GitHub Pages용 정적 React 대시보드 |

### 주요 파일

| 파일 | 설명 |
| --- | --- |
| `scrape_all_years.R` | 2020-2026 데이터를 같은 파서 규칙으로 수집 |
| `app_functions.R` | 데이터 로딩, 정제, 정규화, 보조 함수 |
| `app.R` | Shiny UI와 서버 로직 |
| `scripts/export_dashboard_data.R` | 정제된 데이터를 `site/data/gradcafe.json`으로 내보냄 |
| `site/` | GitHub Pages에 배포되는 정적 React 대시보드 |
| `scraped_2020_2026_combined.Rdata` | 앱에서 사용하는 통합 데이터 |
| `[sample] PhD Admission Analysis.md` | 데이터 기반 샘플 리포트 |
| `legacy_code/` | 예전 스크립트와 이전 구조 보관본 |

### 스크래퍼 동작 방식

스크래퍼는 `political science`, `international relations`, `politics`, `government` 네 가지 검색어로 GradCafe를 조회합니다.

그다음 아래 규칙으로 정리합니다.

- GradCafe의 3행 구조(main, badge, notes)를 한 건으로 묶습니다.
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

### 대시보드 탭

- `Timeline`: 날짜축 위에서 결과 시점을 확인하는 탭
- `Trends`: 연도별 합격률과 국적 분포를 보는 탭
- `Subfields`: 서브필드별 표본 수와 합격률을 보는 탭
- `Data`: 검색 가능한 원자료 테이블과 상세 보기

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
- 최신 갱신 기준은 **2026-03-04**입니다.
- 전체 표본은 **3,747건**입니다.
- 2026 표본은 **847건**입니다.
- 2026 수치는 이후 게시글이 더 들어오면 달라질 수 있습니다.

### 크레딧

이 프로젝트는 **Martin Devaux**의 기존 GradCafe 정치학 PhD 분석을 바탕으로 확장했습니다.
원문: <https://www.martindevaux.com/2020/11/political-science-phd-admission-decisions/>

초기 워크플로를 공개해 준 Martin Devaux 덕분에 이후 확장 작업을 훨씬 수월하게 이어갈 수 있었습니다.

또한 결과를 꾸준히 남겨 준 GradCafe 커뮤니티 이용자들과 사이트 운영진에게도 감사드립니다. 그 기록과 플랫폼이 없었다면 이 프로젝트도 성립하지 않았을 것입니다.

데이터 출처: **[The GradCafe](https://www.thegradcafe.com/survey)**

### 레거시 코드

이전 스크립트와 예전 프로젝트 구조는 `legacy_code/`에 보관되어 있습니다.

---

## English

This repository tracks self-reported GradCafe outcomes for political science PhD admissions from 2020 through 2026.

The point is straightforward: scrape each cycle the same way, clean it with the same rules, and make the results easy to inspect in a Shiny dashboard.

The repository now also includes a **GitHub Pages-ready static React dashboard** in `site/`. That version keeps the shared filters and tabs in the browser, so it can be deployed for free without running a Shiny server.

### Quick start

#### Refresh the static GitHub Pages snapshot

```r
Rscript scripts/export_dashboard_data.R
```

After that, deploy the contents of `site/` to GitHub Pages. The repository includes a `Deploy GitHub Pages` workflow for this static site.

#### If `scraped_2020_2026_combined.Rdata` already exists

```r
Rscript -e "shiny::runApp('app.R')"
```

#### If you want a full refresh first

```r
Rscript scrape_all_years.R
Rscript -e "shiny::runApp('app.R')"
```

### Pipeline

| Step | Script | Input | Output |
| ---: | --- | --- | --- |
| 1 | `scrape_all_years.R` | GradCafe search pages | Per-year `.Rdata` files and `scraped_2020_2026_combined.Rdata` |
| 2 | `app_functions.R` + `app.R` | `scraped_2020_2026_combined.Rdata` | Local or deployed Shiny dashboard |
| 3 | `scripts/export_dashboard_data.R` + `site/` | Cleaned `data` object | Static React dashboard for GitHub Pages |

### Main files

| File | Description |
| --- | --- |
| `scrape_all_years.R` | Scrapes 2020-2026 data with one parser flow |
| `app_functions.R` | Data loading, cleanup, normalization, and helper functions |
| `app.R` | Shiny UI and server logic |
| `scripts/export_dashboard_data.R` | Exports the cleaned dataset to `site/data/gradcafe.json` |
| `site/` | Static React dashboard deployed to GitHub Pages |
| `scraped_2020_2026_combined.Rdata` | Combined dataset used by the app |
| `[sample] PhD Admission Analysis.md` | Sample report generated from the dataset |
| `legacy_code/` | Older scripts and the previous project structure |

### How the scraper works

The scraper queries GradCafe with four broad terms: `political science`, `international relations`, `politics`, and `government`.

It then applies the same cleanup rules each year.

- It treats GradCafe's three-row structure (main row, badge row, notes row) as a single record.
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

### Dashboard tabs

- `Timeline`: decision timing on a date axis
- `Trends`: yearly acceptance rates and nationality splits
- `Subfields`: subfield volume and subfield-specific acceptance rates
- `Data`: searchable raw table with a detail view

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
- Last refresh: **March 4, 2026**
- Combined rows: **3,747**
- 2026 rows: **847**
- The 2026 snapshot will keep moving as new posts appear.

### Credits

This repository extends the earlier GradCafe political science PhD analysis by **Martin Devaux**.
Original post: <https://www.martindevaux.com/2020/11/political-science-phd-admission-decisions/>

Martin published the original workflow clearly, and that made this extension much easier to build and maintain.

I also owe a lot to the GradCafe community and the site maintainers. Without their posts and the platform itself, there would be nothing here to analyze.

Data source: **[The GradCafe](https://www.thegradcafe.com/survey)**

### Legacy code

Older scripts and the previous project structure are preserved in `legacy_code/`.
