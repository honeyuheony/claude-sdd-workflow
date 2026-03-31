# Tasks: 로컬 개발 환경 구성

**Input**: Design documents from `/specs/001-local-dev-environment/`
**Prerequisites**: plan.md, spec.md, research.md
**Tests**: 인프라 구성 작업이므로 자동화 테스트 없음. 수동 E2E 검증으로 대체.
**Organization**: 파일 의존성 순서로 구성. User Story는 Phase 3 검증 단계에서 매핑.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (파일 생성)

**Purpose**: docker-compose.local.yml의 의존 파일들을 먼저 생성

- [x] T001 [P] Create `Dockerfile.local` — 기존 `Dockerfile` 기반, GPU extra 제거하여 ARM Mac 호환
- [x] T002 [P] Create `.env.local` — `env.sample` 기반, 원격 DB placeholder 포함, SSH 포트포워딩 변수 추가

---

## Phase 2: Core (서비스 정의)

**Purpose**: 5개 서비스를 포함하는 로컬 전용 Docker Compose 파일 생성

**CRITICAL**: Phase 1 완료 후 시작

- [x] T003 Create `docker-compose.local.yml` — 5개 서비스 정의 (API, Worker, Monitor, UI, Redis). 기존 `docker-compose.yml` 참조. `Dockerfile.local` 사용, DB depends_on 제거, 단일 `local-dev-network`, `host.docker.internal` extra_hosts 설정

**Checkpoint**: 3개 파일 생성 완료. 서비스 기동 검증 가능.

---

## Phase 3: User Story 1 — 로컬 E2E 테스트 (Priority: P1) MVP

**Goal**: SSH 터널 + 로컬 서비스 기동 후 UI/Swagger에서 핵심 기능이 동작하는지 검증

**Independent Test**: `docker compose -f docker-compose.local.yml --env-file .env.local up -d` → UI에서 요청 전송 → 응답 수신

- [x] T004 [US1] Verify: 모든 서비스가 healthy 상태로 기동되는지 확인 (`docker compose ps`)
- [x] T005 [US1] Verify: FastAPI Swagger (`/docs`)에서 API 호출 → 원격 DB 데이터 기반 정상 응답 확인
- [x] T006 [US1] Verify: UI에서 요청 입력 → 정상 응답 반환 확인

**Checkpoint**: E2E 동작 확인 — MVP 완료.

---

## Phase 4: User Story 2 — 비동기 태스크 모니터링 (Priority: P2)

**Goal**: 모니터링 대시보드에서 Worker와 태스크 상태를 확인할 수 있는지 검증

- [x] T007 [US2] Verify: 모니터링 대시보드에서 Worker 등록 확인 + API 요청 시 태스크 상태 추적

---

## Phase 5: User Story 3 — 코드 변경 즉시 반영 (Priority: P3)

**Goal**: API 소스 수정 시 자동 리로드되는지 검증

- [x] T008 [US3] Verify: `app/` 소스 파일 수정 → API 컨테이너 로그에서 자동 리로드 확인

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Core)**: Depends on Phase 1 — T001 (Dockerfile.local) 필수
- **Phase 3 (US1)**: Depends on Phase 2 + SSH 터널 + 원격 DB 가용 — MVP
- **Phase 4 (US2)**: Phase 3 이후
- **Phase 5 (US3)**: Phase 3 이후

### Parallel Opportunities

Phase 1:
```
T001: Dockerfile.local
  └── [parallel] T002: .env.local
```

Phase 3~5 검증:
```
T004: 서비스 기동 확인 (먼저)
  ├── T005: Swagger 테스트
  ├── T006: UI 테스트
  ├── [parallel] T007: 모니터링 확인
  └── [parallel] T008: Hot reload 확인
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Phase 1: Setup → 의존 파일 생성
2. Phase 2: Core → docker-compose.local.yml 생성
3. Phase 3: US1 → **STOP and VALIDATE**: E2E 동작 확인
4. 문제 발생 시 Phase 1~2 파일 수정 후 재검증

### Incremental Delivery

1. Setup + Core → 파일 생성 완료
2. US1 (E2E) → 핵심 기능 검증 → MVP
3. US2 (Monitor) → 디버깅 환경 확보
4. US3 (Hot reload) → 개발 편의성 확인

---

## Notes

- 이 작업은 인프라 구성이므로 TDD 불적용
- 검증(Phase 3~5)은 SSH 터널 + 원격 서버 가용 상태에서만 가능
- [P] tasks = different files, no dependencies
