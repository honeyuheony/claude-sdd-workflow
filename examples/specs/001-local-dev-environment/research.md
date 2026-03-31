# Research: 로컬 개발 환경 구성

**Date**: 2026-03-15 | **Plan**: [plan.md](./plan.md)

## 1. ARM64 Docker 이미지 호환성

### Decision: 모든 이미지 ARM64 호환 확인

| 이미지 | ARM64 | 근거 |
|--------|:-----:|------|
| `python:3.11-slim` | O | 공식 multi-arch |
| `redis:6-alpine` | O | 공식 multi-arch |
| `postgres:16-alpine` | O | 공식 multi-arch |

### Alternatives considered
- 에뮬레이션(Rosetta) 사용 → 성능 저하, 불안정

## 2. Dockerfile 분리 전략

### Decision: `Dockerfile.local` 별도 생성 (GPU extra 제거)

### Rationale
- 기존 Dockerfile은 GPU 패키지 설치 → Apple Silicon 비호환
- 기존 Dockerfile 수정 금지 (FR-006) → 별도 파일이 유일한 선택

### Alternatives considered
- **Build arg 방식** (`ARG EXTRAS`): 기존 Dockerfile 수정 필요 → FR-006 위반
- **Multi-stage 빌드**: 과도한 복잡성, 이점 없음

## 3. Docker 네트워크 전략

### Decision: 단일 `local-dev-network` 사용

### Rationale
- 기존: 서비스별 네트워크 분리 → 서로 다른 compose 파일
- 로컬: 단일 compose에 모든 서비스 → 하나의 네트워크로 충분

### Alternatives considered
- **다중 네트워크 유지**: 불필요한 복잡성

## 4. host.docker.internal 지원

### Decision: Docker Desktop for Mac 기본 지원 활용

### Rationale
- Docker Desktop for Mac은 `host.docker.internal`을 자동 DNS 해석
- Linux Docker에서는 `extra_hosts` 설정 필요 → 이식성을 위해 로컬에서도 유지
