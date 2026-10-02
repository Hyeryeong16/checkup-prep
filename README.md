# 건강검진 준비 플래너

## 프로젝트 소개

사용자가 검진일, 검사 항목, 성별 및 임신·수유 여부를 입력하면 검사별 준비사항을 통합해 **개인별 준비 일정과 사전 확인 항목을 제공하는 웹 서비스**입니다.

React 프론트엔드에서 입력한 정보를 FastAPI 백엔드로 전달하고, PostgreSQL에 저장된 준비사항에 조건 및 통합 규칙을 적용해 D-day와 실제 날짜로 보여줍니다. 현재 로컬 환경에서 실행하는 프로젝트이며, 외부 배포는 진행하지 않았습니다.

## 개발 배경

건강검진은 검사 종류에 따라 금식, 식사 조절, 약물 복용 등 준비사항이 다릅니다. 여러 검사를 함께 받으면 사용자가 각 검사 안내를 확인하고 중복되거나 서로 다른 기준을 직접 정리해야 합니다.

이 불편을 줄이기 위해 흩어진 준비사항을 하나의 일정으로 통합하고, 병원이나 담당의에게 확인해야 하는 내용은 별도로 제공하도록 개발했습니다.

## 사용 흐름

1. 검진일을 선택합니다.
2. 성별 및 임신·수유 여부 등 사용자 조건을 선택합니다.
3. 받을 검사 항목을 선택합니다.
4. 조건이 적용된 준비 타임라인과 사전 확인 목록을 확인합니다.

## 기술 스택

- Frontend: React, Vite, JavaScript, CSS
- Backend: Python, FastAPI, Uvicorn
- PostgreSQL, psycopg
- Pydantic: 요청·응답 데이터 모델 및 입력 검증
- python-dotenv: 환경변수 설정

## 주요 기능

- 선택한 검사와 공통 준비사항 조회
- 중복 준비사항 통합 및 관련 검사 태그 유지
- 금식 시작일과 제목에 명시된 시간을 비교해 대표 금식 안내 선정
- 검진일을 기준으로 D-day와 실제 준비 날짜 계산
- 검사 취소·변경, 인슐린 등 사전 확인 항목 분리
- 임신·수유 선택에 따른 안내 표시
- 검사 후 안내 별도 반환
- 검사 조합에 따른 충돌 경고 및 PET-CT 단독·조합 규칙 처리

지원 검사: PET-CT/특수 CT, 대장내시경, 방광/골반초음파, 복부초음파, 위내시경, 유방촬영/유방초음파, 혈액검사. `common`은 내부 공통 규칙으로 사용하며 검사 선택 목록에서는 제외합니다.

## 프로젝트 구조

아래는 GitHub 업로드 시 사용할 정리 구조입니다. 실행 명령도 이 구조를 기준으로 작성했습니다.

```text
health-checkup-prep-planner/
├── backend/
│   ├── .env.example
│   ├── db.py
│   ├── main.py
│   ├── models.py
│   ├── queries.py
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── api.js
│   │   ├── App.css
│   │   ├── App.jsx
│   │   ├── index.css
│   │   └── main.jsx
│   ├── index.html
│   ├── package.json
│   ├── package-lock.json
│   └── vite.config.js
├── database/
│   └── checkup_prep.sql
├── data_sample/
│   ├── cau_prep_crawler.py
│   ├── cau_prep_raw.txt
│   └── cau_petct_prep_data.json
├── screenshots/
├── .gitignore
└── README.md
```

기존 `checkup-prep-api`, `checkup-prep-web` 이름을 유지할 경우 아래 명령의 `backend`, `frontend`를 해당 폴더명으로 바꿉니다.

## 데이터 수집 및 구축

Playwright와 BeautifulSoup을 활용해 의료기관에서 공개한 검사 준비사항 원문을 수집하고 TXT 파일로 저장했습니다. 이후 Claude를 활용해 원문을 검사별 준비사항, 적용 조건, 날짜 기준 등의 필드를 가진 JSON 형식으로 구조화했습니다.

구조화한 데이터를 서비스에서 조회하고 조건을 적용할 수 있도록 PostgreSQL에 저장했습니다. 검사별 안내뿐 아니라 여러 검사에 적용되는 공통 준비사항도 함께 관리합니다.

`data_sample/`에는 중앙대학교병원 PET-CT 준비사항의 수집 과정을 대표 예시로 포함합니다.

| 파일 | 내용 |
| --- | --- |
| `cau_prep_crawler.py` | 준비사항 수집 코드 |
| `cau_prep_raw.txt` | 수집한 원본 텍스트 |
| `cau_petct_prep_data.json` | Claude를 활용해 구조화한 JSON 예시 |

원문 수집 → TXT 저장 → Claude를 활용한 JSON 구조화 → DB 구축 → API 조회의 흐름으로 데이터를 서비스에 연결했습니다. 수집 코드는 TXT 저장까지 수행하며, Claude를 활용한 구조화는 별도로 진행했습니다. 샘플은 수집 과정의 예시이며, 전체 서비스 실행에는 `database/`의 테이블과 데이터가 필요합니다. 원문 출처 URL 및 수집 시점은 샘플 파일에 함께 기록합니다.

## 주요 문제 해결

### 공통 준비사항 누락

선택한 검사 데이터만 조회하면 공통 준비사항이 빠질 수 있었습니다. 선택 검사와 함께 내부 공통 그룹인 `common`을 조회하도록 수정했습니다. `common`은 사용자에게 선택할 검사로 표시하지 않습니다.

### 여러 검사 선택 시 중복 안내

동일하거나 유사한 식사·금식 안내가 여러 번 표시되는 문제를 정리했습니다. 예를 들어 전날 저녁 식사 안내와 이후 금식 안내를 통합하고, 관련 검사 태그를 유지해 어떤 검사에 해당하는지 알 수 있도록 했습니다.

### 검사별 금식 기준 차이

검사마다 금식 기준이 달라 대표 안내를 선정하는 규칙이 필요했습니다. 금식 시작일과 제목에 명시된 시간을 비교해 더 긴 준비가 필요한 기준을 대표 안내로 선택하도록 처리했습니다.

### 사용자 조건과 확인 필요 항목 분리

임신·수유 여부에 따라 관련 안내가 표시되도록 조건을 적용했습니다. 검사 취소·변경이나 약물 관련 상담처럼 병원 및 담당의의 확인이 필요한 내용은 일반 준비 일정과 분리했습니다.

## 서비스 화면

GitHub에 웹 서비스 화면 캡처를 추가하면 실행하지 않아도 입력 과정과 결과를 확인할 수 있습니다. 캡처를 `screenshots/`에 저장한 뒤 아래 예시의 주석을 해제하고 실제 파일명과 맞춥니다.

<!-- 실제 서비스 캡처 추가 후 주석을 해제하세요.
### 검진 정보 입력
![검진 정보 입력](screenshots/input.png)

### 개인별 준비 일정 및 확인 목록
![준비 일정 결과](screenshots/result.png)
-->

## 실행 준비

Python, Node.js/npm, PostgreSQL이 설치된 환경이 필요합니다.

### 백엔드 의존성 설치

저장소 루트에서 `cd backend`로 이동합니다. 프로젝트의 Python 가상환경을 활성화하고, `main.py`와 `requirements.txt`가 있는 백엔드 폴더에서 실행합니다.

```bash
python -m pip install -r requirements.txt
```

### PostgreSQL 준비

PostgreSQL 서버를 실행하고 프로젝트 DB의 테이블과 데이터를 준비해야 합니다. 코드를 복사하는 것만으로 DB가 이전되지는 않습니다.

다른 컴퓨터에서 실행할 경우 제공된 SQL 백업을 복원합니다. 아래 명령은 백업에 DB 생성 명령이 없는 경우, 새로 만든 빈 DB를 대상으로 사용하는 예시입니다. `checkup_prep`와 백업 경로를 실제 값으로 바꿉니다.

```bash
createdb -h localhost -p 5432 -U postgres checkup_prep
psql -h localhost -p 5432 -U postgres -d checkup_prep -f "백업파일.sql"
```

`createdb`, `psql` 명령을 찾을 수 없다면 PostgreSQL 설치 폴더의 `bin` 경로를 사용합니다. SQL 백업에 DB 생성 또는 연결 변경 명령이 포함돼 있다면 해당 백업 구조에 맞춰 복원해야 합니다.

### 환경변수 설정

`.env.example`이 있다면 복사해 `.env`를 만듭니다.

Mac/Linux:

```bash
cp .env.example .env
```

Windows 명령 프롬프트(cmd):

```cmd
copy .env.example .env
```

예제 파일이 없다면 백엔드 폴더에 `.env`를 직접 생성합니다. PostgreSQL 접속 정보에 맞게 다음 값을 입력합니다.

```env
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/checkup_prep
```

- `postgres`: PostgreSQL 사용자 이름
- `YOUR_PASSWORD`: 해당 컴퓨터의 PostgreSQL 계정 비밀번호
- `5432`: PostgreSQL 포트
- `checkup_prep`: 복원한 DB 이름

비밀번호에 `@`, `#`, `%` 등 URL 특수문자가 있으면 URL 인코딩이 필요합니다. 실제 비밀번호가 포함된 `.env`는 공개 저장소나 제출 자료에 포함하지 않습니다.

### API 실행

```bash
python -m uvicorn main:app --reload --port 8000
```

- Swagger UI: http://localhost:8000/docs
- 상태 확인: http://localhost:8000/health

`/health`는 API 실행 상태를 확인하는 용도이며 DB 연결까지 검증하지 않습니다. DB 연결은 `/exams` 조회로 확인할 수 있습니다.

## 프론트엔드 실행 및 연결

백엔드를 실행한 상태에서 새 터미널을 열고 저장소 루트에서 실행합니다.

```bash
cd frontend
npm install
npm run dev
```

터미널에 표시된 Vite 주소(기본 `http://localhost:5173`)를 브라우저에서 엽니다. `node_modules/`는 업로드하지 않으며, 의존성은 `package.json`과 `package-lock.json`을 이용해 설치합니다.


프론트엔드의 API 기본 주소를 `http://localhost:8000`으로 설정하고 백엔드와 프론트엔드를 각각 실행합니다.

현재 CORS 허용 주소는 다음과 같습니다.

- `http://localhost:5173`
- `http://127.0.0.1:5173`

프론트엔드가 다른 포트나 주소에서 실행되면 `main.py`의 `allow_origins`에 해당 주소를 추가합니다.

## 엔드포인트

| 메서드 | 경로 | 설명 |
| --- | --- | --- |
| GET | `/exams` | 선택 가능한 검사 목록 |
| GET | `/medication-flags` | 약물 복용 여부 선택에 사용하는 플래그 목록 |
| GET | `/exams/{exam_id}/medications` | 해당 검사와 관련된 약물 목록 |
| POST | `/prep-plan` | 검진 준비 플랜 계산 |
| GET | `/health` | API 실행 상태 확인 |

### POST /prep-plan 요청 예시

```json
{
  "exam_ids": ["colonoscopy", "gastroscopy", "pet_ct"],
  "exam_date": "2026-10-19",
  "sex": "female",
  "pregnant": false,
  "breastfeeding": false
}
```

| 필드 | 필수 여부 | 설명 |
| --- | --- | --- |
| `exam_ids` | 필수 | 검사 ID 목록, 최소 1개 |
| `exam_date` | 필수 | 검진일, YYYY-MM-DD |
| `sex` | 필수 | `male` 또는 `female` |
| `pregnant` | 선택 | 임신 관련 안내 선택 여부, 기본값 false |
| `breastfeeding` | 선택 | 수유 중 여부, 기본값 false |

약물 복용 플래그를 선택한 경우 `/medication-flags`에서 반환된 ID를 `exam_ids`에 함께 포함합니다.

### 응답 필드

| 필드 | 설명 |
| --- | --- |
| `exam_date` | 입력한 검진일 |
| `timeline` | D-day 순으로 정리된 검사 전 준비사항 |
| `physician_consult_items` | 검사 기관·담당의에게 사전 확인이 필요한 항목 |
| `aftercare_items` | 검사 후 안내 |
| `conflict_warnings` | 검사 조합에서 발생하는 충돌 경고 |
| `rule_variant_notes` | 검사 단독·조합에 따른 추가 규칙 안내 |

타임라인 항목에는 `earliest_offset`(검진일 기준 날짜 차이), `start_date`(실제 준비 날짜), `title`, `description`, `exam_ids`, `confirmed_by_sources` 등이 포함됩니다. 전체 요청·응답 모델은 `models.py` 및 Swagger UI에서 확인할 수 있습니다.

## 백엔드 주요 파일

| 파일 | 역할 |
| --- | --- |
| `main.py` | API 라우트, 안내 통합·분류 및 날짜 계산 |
| `queries.py` | 검사·준비사항·상담 항목·충돌 규칙 조회 |
| `models.py` | 요청·응답 데이터 모델 |
| `db.py` | 환경변수 로딩 및 PostgreSQL 연결 |
| `requirements.txt` | Python 의존성 목록 |

## 실행 중 오류 확인

- `Could not import module "main"`: 백엔드 `main.py`가 있는 폴더인지 확인합니다. `python -c "import main"`으로 내부 모듈 오류를 확인할 수 있습니다.
- PostgreSQL 비밀번호 인증 실패: `.env`의 사용자·비밀번호가 현재 컴퓨터의 DB 계정과 일치하는지 확인합니다.
- 테이블을 찾을 수 없음: 연결한 DB에 SQL 백업의 테이블과 데이터가 복원됐는지 확인합니다.
- `422 Unprocessable Content`: 필수 요청 값과 자료형을 확인합니다. 응답의 `detail`에서 실패한 필드를 확인할 수 있습니다.
- 브라우저 `Failed to fetch`: 백엔드 실행 여부, API 기본 주소, 프론트엔드 주소의 CORS 허용 여부를 확인합니다.

## 프로젝트를 통해 배운 점

수집한 내용을 그대로 보여주는 것만으로는 여러 검사의 준비사항을 하나의 일정으로 제공하기 어려웠습니다. 공통 항목, 사용자 조건, 중복 안내, 서로 다른 기준을 데이터 구조와 처리 규칙에 함께 반영해야 했습니다.

데이터 수집과 DB 구축부터 API 및 화면 연결까지 진행하며, 결과 화면에서 발견한 누락과 중복을 다시 데이터와 백엔드 로직에 반영하는 경험을 했습니다.

## 향후 개선

- 사용자가 검진받을 의료기관을 선택하면 해당 기관의 준비사항 제공
- 실제 복용 약물 정보를 입력받아 관련 준비사항 필터링
- 제목 기반 안내 분류를 검사 전·당일·후 구분 및 행동 유형 데이터로 구조화

## 안내

이 플랜은 참고용입니다. 최종 준비사항과 약물 중단·재개 시점은 예약한 병원 및 담당의의 안내를 따릅니다.
