# Implementation Plan: 로컬 개발 환경 구성

**Branch**: `001-local-dev-environment` | **Date**: 2026-03-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-local-dev-environment/spec.md`

## Summary

Apple Silicon Mac에서 핵심 로직을 E2E 테스트할 수 있는 로컬 Docker 환경을 구성한다. `docker-compose.local.yml`, `.env.local`, `Dockerfile.local` 3개 파일을 신규 생성하며, 기존 파일은 일체 수정하지 않는다. 원격 DB는 SSH 포트포워딩 + `host.docker.internal`로 접근한다.

## Technical Context

**Language/Version**: N/A (인프라 구성 파일, 애플리케이션 코드 변경 없음)
**Primary Dependencies**: Docker Compose, Docker Desktop for Mac
**Storage**: PostgreSQL (원격, SSH 터널), Redis (로컬 컨테이너)
**Testing**: 수동 E2E (UI, FastAPI Swagger)
**Target Platform**: macOS (Apple Silicon ARM64) + Docker Desktop
**Project Type**: Infrastructure configuration
**Performance Goals**: 전체 서비스 기동 5분 이내
**Constraints**: ARM64 호환 이미지, 기존 파일 수정 금지
**Scale/Scope**: 단일 개발자 로컬 환경

## Project Structure

### Documentation (this feature)

```text
specs/001-local-dev-environment/
├── spec.md              # Feature specification
├── plan.md              # This file
├── tasks.md             # Implementation tasks
└── research.md          # Technical research
```

### Source Code (repository root)

```text
(기존 구조 유지 — 신규 파일만 추가)

docker-compose.local.yml     # 신규 — 로컬 전용 서비스 정의
Dockerfile.local             # 신규 — ARM Mac용 (GPU extra 제외)
.env.local                   # 신규 — 로컬 환경변수 (placeholder)
```

**Structure Decision**: 기존 프로젝트 루트에 `.local` 접미사 파일만 추가. 디렉토리 구조 변경 없음.

## Key Design Decisions

### 1. Dockerfile.local 필요성

기존 Dockerfile은 GPU 관련 패키지를 설치하지만 Apple Silicon에서는 CUDA가 불가하므로 GPU extra 없이 빌드하는 별도 Dockerfile이 필요하다.

- GPU/ML extra 제거: ARM 비호환 패키지 제외
- 나머지(apt 패키지, 사용자 설정 등)는 동일
- 기존 Dockerfile 수정 금지 (FR-006) → 별도 파일이 유일한 선택

### 2. 네트워크 전략

기존 compose는 별도 네트워크를 사용한다. 로컬 compose는 `local-dev-network` 단일 네트워크로 통합하여 충돌 방지.

### 3. 볼륨 마운트

| 기존 | 로컬 | 이유 |
|------|------|------|
| `/data:/data` | `./data:/data` | Mac에 절대 경로 없음 |
| DB 볼륨 | 제거 | DB는 원격 |
| `./app:/app` | `./app:/app` | 동일 (소스 마운트, hot reload) |

### 4. 서비스별 구성

| 서비스 | 변경사항 |
|--------|----------|
| API | Dockerfile.local 사용, DB depends_on 제거 |
| Worker | autoscale 축소 (로컬 리소스 절약) |
| Monitor | 동일 |
| UI | 동일 |
| Redis | 동일 |

## Complexity Tracking

> 인프라 구성 작업으로 코드 변경 없음. 복잡도 낮음.
