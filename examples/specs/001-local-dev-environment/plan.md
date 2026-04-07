---
feature: 001-local-dev-environment
status: Done
created: 2026-03-15
current_phase: 5
current_step: 8
branch: feature/001-local-dev-environment
---

# 로컬 개발 환경 구성

## Part 1: Context & Requirements

### 문제 정의

Apple Silicon Mac에서 Docker Compose로 모든 서비스를 로컬에 띄워 Chat 로직을 E2E 테스트할 수 있는 환경을 구성한다.

### 범위

**In-Scope:**
- `docker-compose.local.yml`, `.env.local`, `Dockerfile.local` 신규 생성
- API, Worker, Monitor, UI, Redis 5개 서비스 로컬 기동
- 원격 DB는 SSH 포트포워딩 + `host.docker.internal`로 접근
- 소스 코드 마운트 + hot reload

**Out-of-Scope:**
- 기존 파일(`docker-compose.yml`, `.env` 등) 수정
- GPU/CUDA 관련 기능 (Apple Silicon 미지원)
- 자동화된 테스트 스크립트 작성

### Acceptance Criteria

#### AC-01: 단일 명령 서비스 기동
- **Given**: SSH 터널이 열려 있고 `.env.local`이 설정되어 있다
- **When**: `docker compose -f docker-compose.local.yml --env-file .env.local up -d` 실행
- **Then**: 모든 서비스(API, Worker, Monitor, UI, Redis)가 5분 이내에 healthy 상태로 기동된다

#### AC-02: UI E2E 테스트
- **Given**: 모든 서비스가 기동되어 있다
- **When**: UI에서 요청을 입력한다
- **Then**: 외부 ML 서비스를 경유한 응답이 정상적으로 반환된다

#### AC-03: Swagger API 테스트
- **Given**: 모든 서비스가 기동되어 있다
- **When**: FastAPI Swagger UI에서 API를 호출한다
- **Then**: 원격 DB의 데이터를 기반으로 정상 응답이 동작한다

#### AC-04: 비동기 태스크 모니터링
- **Given**: 모든 서비스가 기동되어 있다
- **When**: API 요청을 보낸다
- **Then**: 모니터링 대시보드에서 해당 태스크의 상태(PENDING -> STARTED -> SUCCESS/FAILURE)를 추적할 수 있다

#### AC-05: 코드 변경 즉시 반영
- **Given**: API가 `--reload` 모드로 실행 중이다
- **When**: `app/` 하위 소스 파일을 수정한다
- **Then**: 서버가 자동으로 리로드되고 수정사항이 반영된다

## Part 2: Technical Design

### 영향 파일/모듈

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `docker-compose.local.yml` | Create | 5개 서비스 정의 (로컬 전용) |
| `Dockerfile.local` | Create | ARM Mac용 (GPU extra 제외) |
| `.env.local` | Create | 로컬 환경변수 placeholder |

### 아키텍처 결정

1. **Dockerfile.local 분리**: 기존 Dockerfile은 GPU 패키지를 설치하지만 Apple Silicon에서는 CUDA 불가. 기존 파일 수정 금지(FR-006) → 별도 파일이 유일한 선택.

2. **네트워크 전략**: `local-dev-network` 단일 네트워크로 통합. 기존 compose 네트워크와 충돌 방지.

3. **볼륨 마운트 변경**: Mac에 절대 경로(`/data`) 없음 → `./data:/data`로 변경. DB 볼륨은 원격 사용이므로 제거.

4. **원격 DB 접근**: SSH 포트포워딩 + Docker 컨테이너에서 `host.docker.internal`로 호스트의 터널에 접근.

### 검토한 대안

| 대안 | 장점 | 단점 | 선택 여부 |
|------|------|------|----------|
| 기존 Dockerfile 수정 | 유지보수 파일 1개 | FR-006 위반, 서버 배포 영향 | 기각 |
| 로컬 DB 컨테이너 추가 | SSH 터널 불필요 | 데이터 동기화 복잡, 테스트 데이터 부재 | 기각 |
| Docker network host 모드 | 네트워크 설정 단순 | Mac Docker Desktop에서 host 모드 미지원 | 기각 |

## Part 3: Tasks

### Phase 1: Setup (파일 생성)
- [x] [T001] || `Dockerfile.local` 생성 — 기존 `Dockerfile` 기반, GPU extra 제거하여 ARM Mac 호환
- [x] [T002] || `.env.local` 생성 — `env.sample` 기반, 원격 DB placeholder 포함, SSH 포트포워딩 변수 추가

### Phase 2: Core (서비스 정의)
- [x] [T003] `docker-compose.local.yml` 생성 — 5개 서비스 정의
  - Depends on: T001, T002

### Phase 3: E2E 검증 (MVP)
- [x] [T004] 모든 서비스 healthy 상태 기동 확인 — `docker compose ps`
- [x] [T005] FastAPI Swagger 테스트 — 원격 DB 기반 정상 응답 확인
  - Depends on: T004
- [x] [T006] UI E2E 테스트 — 요청 입력 → 응답 반환 확인
  - Depends on: T004

### Phase 4: 모니터링 검증
- [x] [T007] 모니터링 대시보드 검증 — Worker 등록 + 태스크 상태 추적
  - Depends on: T004

### Phase 5: Hot Reload 검증
- [x] [T008] 코드 변경 자동 리로드 확인 — `app/` 소스 수정 → 컨테이너 로그 확인
  - Depends on: T004

## Part 4: Risks & Verification

### 기술적 위험

| 위험 | 영향 | 완화 방안 |
|------|------|----------|
| SSH 터널 끊김 | API/Worker 연결 실패 | 터널 재연결 후 자동 복구 확인 |
| 포트 충돌 | 서비스 기동 실패 | `.env.local`에서 포트 변경 가능하도록 설계 |
| ARM64 이미지 미지원 | 빌드 실패 | Dockerfile.local에서 호환 이미지만 사용 |

### 검증 기준

| 검증 항목 | 방법 | 기대 결과 |
|----------|------|----------|
| 서비스 기동 | `docker compose ps` | 5개 서비스 healthy |
| API 동작 | Swagger UI 호출 | 200 OK + 정상 데이터 |
| UI 동작 | UI 요청 전송 | 응답 수신 |
| 모니터링 | 대시보드 확인 | 태스크 상태 추적 가능 |
| Hot reload | 소스 수정 후 로그 확인 | 자동 리로드 발생 |
| 기존 파일 무결성 | `git diff` | 기존 파일 변경 없음 |
