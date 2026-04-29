# Document Templates

## plan.md 4-Part 템플릿 (master plan)

```markdown
---
type: master-plan
feature: NNN-feature-name
status: Draft
tier: Standard                         # 또는 Quick
created: YYYY-MM-DD
parts_reviewed: []                     # 사이클 승인마다 [1], [1,2], [1,2,3,4] 누적
current_phase: 0
current_step: 0
branch: ""
target_save_path: <project>/specs/NNN-feature/plan.md   # ExitPlanMode 후 이동 경로
steering: []   # 옵션. steering-load skill이 로드한 _steering/ 파일 목록 (예: [product, tech])
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

조건/동작 형식 (권장) 또는 Given/When/Then 형식. 둘 다 또는 혼용 가능.

#### AC-01: {제목} — 조건/동작 형식
- **WHEN** {조건/이벤트} / **THE SYSTEM SHALL** {기대 동작}

#### AC-02: {제목} — Given/When/Then 형식
- **Given**: {전제 조건}
- **When**: {동작}
- **Then**: {기대 결과}

### Acceptance Criteria — 실행 경로 (옵션, 자율 작업 단위가 큰 Standard에서 권장)

agent loop 경로 자체에 대한 합격 조건. final-output AC와 별개:

- 도구 호출 횟수 ≤ {N}
- 동일 파일 편집 횟수 ≤ {M}
- 금지 도구 0회: {목록 — 예: git push, rm -rf, 패키지 install}
- 필수 검증 step: {예: pytest 1회 이상}
- 사용자 승인 게이트: {자율성 등급별}

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

## 임시 plan 템플릿 (사이클별, hook 통과용 메타 파일)

매 사이클(1, 2, 3) ExitPlanMode 직전에 `~/.claude/plans/<random>-cycle-N.md`로 생성:

```markdown
---
type: meta-progress
tier: Standard            # 본질 그대로 (Quick 거짓 표기 금지)
parts_reviewed: []        # 임시 plan은 항상 []
master_plan_path: <master 절대 경로>
cycle: 1                  # 1, 2, 3
---

# 사이클 N — {Part N 또는 Part 3+4 통합}

해당 사이클의 본문(Part 1 / Part 2 / Part 3+4)을 작성.
사이클 종료 시 본문을 master plan으로 sync 후 master `parts_reviewed`에 Part 번호 추가.
```

> 사이클 1(`cycle: 1`)은 master `parts_reviewed`가 비어 있어도 hook 통과(부트스트랩 예외).
> 사이클 2 이상에서 `cycle: 1` 거짓 표기는 본질 거짓 표기 안티패턴.

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

## Failure Log Template (session-log용 상세)

session-log.md 발견사항 섹션에 상세 기록:

```markdown
### Failure: {title}
- **Date**: YYYY-MM-DD
- **Attempted**: 시도한 방법
- **Expected**: 예상했던 결과
- **Actual**: 실제 결과
- **Root Cause**: 실패 원인
- **Lesson**: 재사용 가능한 통찰
```

failure-patterns.md에는 교훈만 간결하게:

```markdown
### {title}
- {교훈 1줄}
- **Why:** {근본 원인 1줄}
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
