# Document Templates

## plan.md 4-Part 템플릿

```markdown
---
feature: NNN-feature-name
status: Draft
created: YYYY-MM-DD
current_phase: 0
current_step: 0
branch: ""
---

# {Feature Name}

## Part 1: Context & Requirements

### 문제 정의
{Problem Statement}

### 범위
**In-Scope:**
- ...

**Out-of-Scope:**
- ...

### Acceptance Criteria

#### AC-01: {제목}
- **Given**: {전제 조건}
- **When**: {동작}
- **Then**: {기대 결과}

## Part 2: Technical Design

### 영향 파일/모듈
| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| ... | Create/Modify | ... |

### 아키텍처 결정
{결정 + 근거}

### 검토한 대안
| 대안 | 장점 | 단점 | 선택 여부 |
|------|------|------|----------|
| ... | ... | ... | 선택/기각 |

## Part 3: Tasks

### Phase 1: {Phase 이름}
- [ ] [T001] {Step 설명} — `{대상 파일}`
- [ ] [T002] {Step 설명} — `{대상 파일}`
  - Depends on: T001

### Phase 2: {Phase 이름}
- [ ] [T003] || {병렬 가능 Step} — `{파일}`
- [ ] [T004] || {병렬 가능 Step} — `{파일}`

## Part 4: Risks & Verification

### 기술적 위험
| 위험 | 영향 | 완화 방안 |
|------|------|----------|
| ... | ... | ... |

### 검증 기준
| 검증 항목 | 방법 | 기대 결과 |
|----------|------|----------|
| ... | ... | ... |
```

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
