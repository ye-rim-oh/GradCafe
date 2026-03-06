# GradCafe 2020-2026 political science PhD trend analysis

This repository tracks self-reported GradCafe outcomes for political science PhD admissions from 2020 through 2026.

이 저장소는 2020-2026년 GradCafe 자기보고 데이터를 바탕으로 정치학 PhD 어드미션 흐름을 정리한 프로젝트입니다.

The idea is simple: scrape each cycle the same way, clean it with the same rules, and make the patterns easy to check in a Shiny dashboard.

목표도 단순합니다. 매년 같은 방식으로 수집하고, 같은 규칙으로 정제한 뒤, Shiny 대시보드에서 바로 흐름을 확인할 수 있게 만드는 것입니다.

## Quick start / 빠른 시작

### If `scraped_2020_2026_combined.Rdata` already exists / 통합 데이터가 이미 있을 때

```r
Rscript -e "shiny::runApp('app.R')"
```

### Full refresh, then run the app / 처음부터 다시 수집하고 실행할 때

```r
Rscript scrape_all_years.R
Rscript -e "shiny::runApp('app.R')"
```

## Pipeline / 파이프라인

| Step / 단계 | Script | Input / 입력 | Output / 출력 |
| ---: | --- | --- | --- |
| 1 | `scrape_all_years.R` | GradCafe search pages / GradCafe 검색 페이지 | Per-year `.Rdata` files and `scraped_2020_2026_combined.Rdata` / 연도별 `.Rdata`와 통합 데이터 |
| 2 | `app_functions.R` + `app.R` | `scraped_2020_2026_combined.Rdata` | Local or deployed Shiny dashboard / 로컬 또는 배포용 Shiny 대시보드 |

## Main files / 주요 파일

| File | Description / 설명 |
| --- | --- |
| `scrape_all_years.R` | Unified scraper for 2020-2026 with one parser flow / 2020-2026을 같은 파서 규칙으로 수집 |
| `app_functions.R` | Data loading, cleanup, normalization, and helper functions / 데이터 로딩, 정제, 정규화, 보조 함수 |
| `app.R` | Shiny UI and server logic / Shiny UI와 서버 로직 |
| `scraped_2020_2026_combined.Rdata` | Combined dataset used by the app / 앱에서 사용하는 통합 데이터 |
| `[sample] PhD Admission Analysis.md` | Sample report generated from the dataset / 데이터 기반 샘플 리포트 |
| `legacy_code/` | Older scripts and project structure / 예전 스크립트와 구조 보관본 |

## How the scraper works / 스크래퍼 동작

The scraper queries GradCafe with four broad terms: `political science`, `international relations`, `politics`, `government`.

검색은 `political science`, `international relations`, `politics`, `government` 네 개의 넓은 키워드로 시작합니다.

After that, it applies the same cleanup steps each year.

그다음에는 매년 같은 정리 규칙을 적용합니다.

- It treats GradCafe's three-row structure (main row, badge row, notes row) as one record. / GradCafe의 3행 구조(main, badge, notes)를 한 건으로 묶습니다.
- It extracts decision labels, dates, GRE, GPA, nationality tags, and notes. / 결정 유형, 날짜, GRE, GPA, 국적 태그, 노트를 추출합니다.
- It removes duplicates with `(school, decision_text, notes, added_date)`. / `(school, decision_text, notes, added_date)` 기준으로 중복을 제거합니다.
- It keeps only `degree == "PhD"`. / `degree == "PhD"`만 남깁니다.
- It normalizes `program` text and keeps only the target majors. / `program` 문자열을 정규화한 뒤 목표 전공만 남깁니다.
- It tags subfields from notes: `CP`, `IR`, `AP`, `Theory`, `Methods`, `Public Law/Policy`, `Psych/Behavior`, `Unknown`. / 노트 내용을 바탕으로 서브필드 태그를 붙입니다.

## App-side cleanup / 앱 전처리

Before plotting, the app does a second cleanup pass.

시각화에 들어가기 전 앱 단계에서 한 번 더 정리합니다.

- Recover missing `gre_q` values from `gre_total` when that is possible. / 복원 가능한 경우 `gre_total`로 `gre_q`를 되살립니다.
- Remove impossible GRE and AW values. / 비정상적인 GRE와 AW 값을 제거합니다.
- Standardize timeline dates for cross-year comparison. / 연도 간 비교가 되도록 타임라인 날짜를 표준화합니다.
- Drop obvious junk rows and normalize institution names with a rule map. / 노이즈 행을 걸러내고 학교명을 규칙 기반으로 통합합니다.

## Dashboard tabs / 대시보드 탭

- `Timeline`: dot-based decision calendar / 날짜축 위에 결과를 찍어 보는 결정 타임라인
- `Trends`: yearly acceptance rate and nationality split / 연도별 합격률과 국적 분포
- `Subfields`: subfield volume and subfield-specific acceptance rates / 서브필드별 표본 수와 합격률
- `Data`: searchable raw table with a detail view / 검색 가능한 원자료 테이블과 상세 보기

## Dependencies / 의존 패키지

- R (>= 4.0)
- `rvest`, `httr`, `dplyr`, `tidyr`, `lubridate`, `stringr`, `plotly`, `ggplot2`, `rmarkdown`, `knitr`, `kableExtra`, `shiny`, `shinyjs`, `shinyWidgets`, `DT`

Install once / 한 번만 설치:

```r
install.packages(c("rvest", "httr", "dplyr", "tidyr", "lubridate", "stringr",
                   "plotly", "ggplot2", "rmarkdown", "knitr", "kableExtra",
                   "shiny", "shinyjs", "shinyWidgets", "DT"))
```

## Data notes / 데이터 해석 시 주의

- The source is self-reported GradCafe data, so missingness and reporting bias are unavoidable. / GradCafe는 자기보고 데이터라 누락과 표본 편향이 있습니다.
- Parsing and normalization are rule-based, so a few edge cases can still slip through. / 파싱과 정규화는 규칙 기반이라 일부 예외는 남을 수 있습니다.
- Acceptance rate is defined as `Accepted / (Accepted + Rejected)`. / 합격률 계산식은 `Accepted / (Accepted + Rejected)`입니다.
- Last refresh / 최신 갱신: **March 4, 2026**
- Combined rows / 전체 표본: **3,766**
- 2026 rows / 2026 표본: **858**
- The 2026 slice is still moving as new posts come in. / 2026 수치는 이후 게시글 유입에 따라 계속 달라질 수 있습니다.

## Credits / 크레딧

This repository extends the earlier GradCafe political science PhD analysis by **Martin Devaux**:
<https://www.martindevaux.com/2020/11/political-science-phd-admission-decisions/>

Martin laid out the original workflow clearly, and that made this extension much easier to build and maintain.

초기 분석 과정을 공개해 준 Martin Devaux 덕분에 이후 확장 작업을 훨씬 수월하게 이어갈 수 있었습니다.

I also owe a lot to the GradCafe community and the site maintainers. Without their posts and the platform itself, there would be nothing here to analyze.

또한 결과를 꾸준히 남겨 준 GradCafe 커뮤니티 이용자들과 사이트 운영진에게도 감사드립니다. 그 기록과 플랫폼이 없었다면 이 프로젝트도 존재할 수 없었습니다.

Data source / 데이터 출처: **[The GradCafe](https://www.thegradcafe.com/survey)**

## Legacy code / 레거시 코드

Older scripts and the previous project structure are preserved in `legacy_code/`.

이전 스크립트와 예전 프로젝트 구조는 `legacy_code/`에 보관해 두었습니다.
