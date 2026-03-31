# Document Templates

## tasks.md 형식

```markdown
# Implementation Tasks: {Feature Name}

## Phase 1: Setup
- [ ] [T001] 프로젝트 스캐폴드 생성 — `src/index.py`
- [ ] [T002] 테스트 환경 구성 — `tests/conftest.py`

## Phase 2: Core (US1)
- [ ] [T003] [US1] 인증 서비스 — `src/services/auth.py`
  - Depends on: T001
- [ ] [T004] [US1] 인증 테스트 — `tests/test_auth.py`
```

각 태스크는:
- `[TaskID]` 필수 (T001, T002...)
- `[USn]` User Story 태그 (해당 시)
- 정확한 파일 경로 포함
- 의존성 명시 (Depends on)

---

## session-log.md 형식

```markdown
## Session: YYYY-MM-DD HH:MM

### 완료
- [T003] 인증 서비스 구현 — 테스트 5/5 통과
- [T004] 인증 테스트 — 통과

### 미완료/이월
- [T005] 권한 관리 — 사유: Redis 연결 이슈

### 발견사항
- Redis 타임아웃 1초 → 5초로 변경 필요

### 다음 세션 TODO
- [ ] T005 재개
- [ ] T006 시작
```

---

## spec.md 템플릿 (기본 모드)

```markdown
---
feature: {feature-name}
status: draft
created: {YYYY-MM-DD}
---

# Spec: {기능명}

## 목적 / 배경
{왜 필요한가, 어떤 문제를 해결하는가}

## 사용자 스토리
As a {사용자 유형}, I want to {목표}, so that {이유}.

## Acceptance Criteria

### AC-01: {시나리오 이름}
- **Given**: {전제 조건}
- **When**: {행동/이벤트}
- **Then**: {기대 결과}

### AC-02: ...

## Out of Scope
- {이번 구현에 포함하지 않는 것}

## 기술 제약
- {성능, 플랫폼, 의존성 등}
```

---

## tasks.md 템플릿 (기본 모드)

```markdown
# Implementation Tasks: {Feature Name}

## Phase 1: Setup
- [ ] [T001] {설명} — `{파일 경로}`
- [ ] [T002] {설명} — `{파일 경로}`

## Phase 2: Core
- [ ] [T003] {설명} — `{파일 경로}`
  - Depends on: T001
- [ ] [T004] {설명} — `{파일 경로}`

## Phase 3: Integration
- [ ] [T005] {설명} — `{파일 경로}`
```

각 태스크는:
- `[TaskID]` 필수 (T001, T002...)
- 정확한 파일 경로 포함
- 의존성 명시 (Depends on)

---

## Failure Log Template

```markdown
### Failure: {title}
- **Date**: YYYY-MM-DD
- **Attempted**: 시도한 방법
- **Expected**: 예상했던 결과
- **Actual**: 실제 결과
- **Root Cause**: 실패 원인
- **Lesson**: 재사용 가능한 통찰
```

---

## Success Log Template

```markdown
### Success: {title}
- **Date**: YYYY-MM-DD
- **What worked**: 성공한 접근법
- **Why it worked**: 성공 요인
- **Pattern**: 재사용 가능한 패턴
```
