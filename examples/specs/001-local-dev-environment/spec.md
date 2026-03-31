# Feature Specification: 로컬 개발 환경 구성

**Feature Branch**: `001-local-dev-environment`
**Created**: 2026-03-15
**Status**: Done
**Input**: User description: "Apple Silicon Mac에서 Docker Compose로 모든 서비스를 로컬에 띄워 Chat 로직을 E2E 테스트할 수 있는 환경을 구성한다."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 로컬 E2E 테스트 (Priority: P1)

개발자가 Apple Silicon Mac에서 단일 명령으로 전체 서비스를 로컬에 띄우고, UI 또는 Swagger를 통해 핵심 기능을 직접 테스트한다.

**Why this priority**: 이 기능의 핵심 목적. 로컬에서 실제 데이터와 외부 서비스를 연동해 검증할 수 있어야 개발 사이클이 빨라진다.

**Independent Test**: `docker compose -f docker-compose.local.yml up -d` 실행 후 UI에서 요청을 보내고 응답을 받으면 성공.

**Acceptance Scenarios**:

1. **Given** SSH 터널이 열려 있고 `.env.local`이 설정되어 있다, **When** `docker compose -f docker-compose.local.yml --env-file .env.local up -d` 실행, **Then** 모든 서비스(API, Worker, Monitor, UI, Redis)가 healthy 상태로 기동된다.
2. **Given** 모든 서비스가 기동되어 있다, **When** UI에서 요청을 입력한다, **Then** 외부 ML 서비스를 경유한 응답이 정상적으로 반환된다.
3. **Given** 모든 서비스가 기동되어 있다, **When** FastAPI Swagger UI에서 API를 호출한다, **Then** 원격 DB의 데이터를 기반으로 정상 응답이 동작한다.

---

### User Story 2 - 비동기 태스크 모니터링 (Priority: P2)

개발자가 테스트 중 Celery 비동기 태스크의 상태를 모니터링 대시보드에서 실시간 확인하여 디버깅한다.

**Why this priority**: 비동기 처리 흐름을 모니터링할 수 있어야 디버깅이 가능하다.

**Independent Test**: 모니터링 대시보드에서 실행 중인 worker와 태스크 목록을 확인할 수 있으면 성공.

**Acceptance Scenarios**:

1. **Given** 모든 서비스가 기동되어 있다, **When** API 요청을 보낸다, **Then** 모니터링 대시보드에서 해당 태스크의 상태(PENDING → STARTED → SUCCESS/FAILURE)를 추적할 수 있다.

---

### User Story 3 - 코드 변경 즉시 반영 (Priority: P3)

개발자가 로컬 소스 코드를 수정하면 API 서버가 자동으로 리로드되어 재시작 없이 변경사항을 테스트할 수 있다.

**Why this priority**: 빠른 개발 반복을 위해 코드 변경이 즉시 반영되어야 한다.

**Independent Test**: `app/` 하위 Python 파일을 수정한 후 API가 자동 리로드되는지 확인.

**Acceptance Scenarios**:

1. **Given** API가 `--reload` 모드로 실행 중이다, **When** `app/` 하위 소스 파일을 수정한다, **Then** 서버가 자동으로 리로드되고 수정사항이 반영된다.

---

### Edge Cases

- SSH 터널이 끊어졌을 때 서비스는 어떻게 되는가? → API/Worker가 연결 실패 에러를 반환하지만, 터널 재연결 후 자동 복구된다.
- 원격 DB 포트와 로컬 서비스 포트가 충돌하면? → `.env.local`에서 포트를 자유롭게 변경할 수 있다.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `docker-compose.local.yml`은 API, Worker, Monitor, UI, Redis 5개 이상의 서비스를 정의해야 한다.
- **FR-002**: 모든 서비스는 단일 Docker Compose 명령으로 기동되어야 한다.
- **FR-003**: `.env.local`은 원격 접속 정보를 placeholder로 제공하고, 사용자가 값만 채워 넣으면 동작해야 한다.
- **FR-004**: Docker 컨테이너에서 호스트의 SSH 터널에 접근하기 위해 `host.docker.internal`을 사용해야 한다.
- **FR-005**: API 서비스는 소스 마운트 + `--reload` 모드로 실행되어 코드 변경이 자동 반영되어야 한다.
- **FR-006**: 기존 파일(`docker-compose.yml`, `.env` 등)은 수정하지 않아야 한다.
- **FR-007**: 모든 Docker 이미지는 ARM64(Apple Silicon) 호환이어야 한다.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 단일 명령 실행 후 5분 이내에 모든 서비스가 healthy 상태로 기동된다.
- **SC-002**: UI에서 요청을 보내고 정상 응답을 받을 수 있다.
- **SC-003**: FastAPI Swagger UI에서 API를 호출하고 정상 응답을 확인할 수 있다.
- **SC-004**: 모니터링 대시보드에서 비동기 태스크 실행 상태를 확인할 수 있다.
- **SC-005**: `app/` 소스 수정 시 API가 자동 리로드된다.
- **SC-006**: 기존 docker-compose.yml로 서버 환경 배포 시 영향이 없다 (기존 파일 미수정 확인).

## Assumptions

- 개발자의 Mac에 Docker Desktop이 설치되어 있고 `host.docker.internal`이 지원된다.
- 원격 서버에 대한 SSH 접근 권한이 있고, 포트포워딩이 가능하다.
- 원격 DB에는 테스트에 필요한 데이터가 미리 준비되어 있다.
