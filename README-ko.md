# GradCafe 2020-2026 정치학 박사과정 트렌드 분석

[English](README.md)

이 저장소는 2020-2026 GradCafe 자기보고 데이터를 바탕으로,
정치학 PhD 어드미션 흐름을 한눈에 볼 수 있게 정리한 프로젝트입니다.

핵심은 복잡하지 않습니다. 매년 같은 규칙으로 스크랩하고,
같은 정제 로직을 거친 뒤, Shiny 대시보드에서 바로 확인하는 구조입니다.

## 빠른 시작

### `scraped_2020_2026_combined.Rdata`가 이미 있을 때

```r
Rscript -e "shiny::runApp('app.R')"
```

### 데이터까지 새로 갱신해서 실행할 때

```r
Rscript scrape_all_years.R
Rscript -e "shiny::runApp('app.R')"
```

## 파이프라인

| 단계 | 스크립트 | 입력 | 출력 |
| ---: | --- | --- | --- |
| 1 | `scrape_all_years.R` | GradCafe 검색 페이지 | 연도별 `.Rdata` + `scraped_2020_2026_combined.Rdata` |
| 2 | `app_functions.R` + `app.R` | `scraped_2020_2026_combined.Rdata` | 로컬/배포용 Shiny 대시보드 |

## 파일 안내

| 파일 | 역할 |
| --- | --- |
| `scrape_all_years.R` | 2020-2026을 하나의 파서 규칙으로 수집 |
| `app_functions.R` | 데이터 로딩, 정제, 학교명 정규화, 보조 함수 |
| `app.R` | 대시보드 UI/서버 로직 |
| `scraped_2020_2026_combined.Rdata` | 분석용 통합 데이터 |
| `[sample] PhD Admission Analysis.md` | 데이터 기반 영문 샘플 리포트 |
| `README.md` | 영문 문서 |

## 스크래퍼 동작 요약 (`scrape_all_years.R`)

검색 키워드는 아래 4개를 사용합니다.
`political science`, `international relations`, `politics`, `government`

수집 후에는 다음 순서로 정리합니다.

- GradCafe 3행 구조(main/badge/notes)를 한 건으로 합칩니다.
- 결정 유형, 날짜, GRE, GPA, 국적 태그, 노트를 추출합니다.
- `(school, decision_text, notes, added_date)` 기준으로 중복 제거합니다.
- `degree == "PhD"`만 남깁니다.
- `program` 문자열을 정규화한 뒤,
  Political Science / IR / Politics / Government(및 직접 조합)만 유지합니다.
- 노트 기반으로 서브필드 태그(`CP`, `IR`, `AP`, `Theory`, `Methods`, `Public Law/Policy`, `Psych/Behavior`, `Unknown`)를 붙입니다.

## 앱 전처리 요약 (`app_functions.R`)

앱에서 시각화하기 전에 추가로 다음 정제를 합니다.

- `gre_total`로 복원 가능한 `gre_q`를 복원합니다.
- 비정상 GRE/AW 값을 제거합니다.
- 연도 비교가 가능하도록 타임라인 날짜를 표준화합니다.
- 노이즈 행을 제거하고 학교명을 규칙 기반으로 통합합니다.

## 대시보드 탭 구성 (`app.R`)

- `Timeline`: 날짜축 기준 결정 시점 분포
- `Trends`: 연도별 합격률 + 국적별 합격률
- `Subfields`: 서브필드 신고량 + 서브필드 합격률
- `Data`: 검색/정렬 가능한 원자료 테이블

## 의존 패키지

- R (>= 4.0)
- `rvest`, `httr`, `dplyr`, `tidyr`, `lubridate`, `stringr`, `plotly`, `ggplot2`, `rmarkdown`, `knitr`, `kableExtra`, `shiny`, `shinyjs`, `shinyWidgets`, `DT`

```r
install.packages(c("rvest", "httr", "dplyr", "tidyr", "lubridate", "stringr",
                   "plotly", "ggplot2", "rmarkdown", "knitr", "kableExtra",
                   "shiny", "shinyjs", "shinyWidgets", "DT"))
```

## 데이터 해석 시 주의

- GradCafe는 자기보고 데이터라 누락과 표본 편향이 있습니다.
- 파싱/정규화는 규칙 기반이라 일부 예외는 남을 수 있습니다.
- 합격률 계산식은 `Accepted / (Accepted + Rejected)`입니다.
- 최신 갱신 기준은 **2026-03-04**입니다.
  - 전체 표본: **3,766건**
  - 2026 표본: **858건**
- 2026 수치는 이후 게시글 유입에 따라 변할 수 있습니다.

## 크레딧

이 프로젝트는 **Martin Devaux**의 기존 분석을 바탕으로 확장했습니다.
원문: <https://www.martindevaux.com/2020/11/political-science-phd-admission-decisions/>

초기 분석 과정을 공개해 준 Martin Devaux에게 진심으로 감사드립니다.
덕분에 이후 확장 작업을 훨씬 안정적으로 이어갈 수 있었습니다.

또한 꾸준히 결과를 공유해 준 GradCafe 커뮤니티 사용자들과
플랫폼을 운영해 온 The GradCafe 팀에도 깊이 감사드립니다.

데이터 출처: **[The GradCafe](https://www.thegradcafe.com/survey)**

## 레거시 코드

이전 구조와 스크립트는 `legacy_code/`에 보관되어 있습니다.
