---
name: plan-lifecycle
description: Plan 문서 관리 — 4-Part plan.md/session-log 형식, 저장 경로, Frontmatter 추적, 실패/성공 기록 템플릿. 산출물 생성, /start-session, /end-session 시 참조.
user-invocable: false
---

# Plan Lifecycle

## 문서 종류와 역할

| 파일 | 생성 시점 | 작성 방식 | 역할 |
|------|----------|----------|------|
| `plan.md` | Plan Mode 승인 후 저장 | 4-Part 구조 원문 그대로 | 설계 + 태스크의 SSOT |
| `session-log.md` | `/end-session` | 세션별 진행 기록 | 세션 간 컨텍스트 전달 |
| `research.md` | Plan 작성 중 (필요 시) | 기술적 미지수 해결 기록 | 의사결정 근거 |

> **spec.md, tasks.md 독립 파일 제거.** plan.md Part 1이 AC 역할, Part 3이 체크리스트 역할.

프로젝트 내 `specs/` 디렉토리에 함께 저장 (git 관리):
```
{project_root}/specs/NNN-{feature}/
├── plan.md           ← 4-Part 통합 계획 (SSOT)
├── session-log.md    ← 세션 추적
└── research.md       ← 기술 미지수 해결 (필요 시)
```

> Superpowers 기본 경로 (`docs/superpowers/specs/`, `docs/superpowers/plans/`)는 이 규칙으로 오버라이드.

## plan.md 저장 원칙 — Plan Mode 원문 그대로

**절대 규칙: Plan Mode에서 작성된 4-Part 계획을 요약하거나 재작성하지 않는다.**

- ExitPlanMode 직후 → frontmatter만 추가하여 원문 그대로 저장
- PRD/계획 원문을 받으면 → Plan Mode에서 4-Part로 구조화 후 저장
- Claude가 "더 낫게" 재구성하는 것은 금지

## 메타데이터 형식

### master plan (specs/NNN-feature/plan.md — 4-Part 본질·진행 추적)

```yaml
---
type: master-plan
feature: NNN-feature-name
status: Draft | In-Progress | Done
tier: Standard                         # 또는 Quick
created: YYYY-MM-DD
parts_reviewed: []                     # 사이클 승인 시마다 [1], [1,2], [1,2,3,4] 누적
current_phase: N
current_step: N
branch: branch-name
target_save_path: <project>/specs/NNN-feature/plan.md   # ExitPlanMode 후 이동 경로
steering: [product, tech, structure]   # 옵션. steering-load skill이 로드한 _steering/ 파일 목록 (없으면 생략)
---
```

### 임시 plan (`~/.claude/plans/<random>-cycle-N.md` — 매 사이클 ExitPlanMode hook 통과용 메타 파일)

```yaml
---
type: meta-progress
tier: Standard            # 본질 그대로 (Quick 거짓 표기 금지)
parts_reviewed: []        # 임시 plan은 항상 []
master_plan_path: <master 절대 경로>
cycle: 1                  # 1, 2, 3 — 첫 사이클(cycle: 1)은 hook 부트스트랩 예외 대상
---
```

> `Status` 필드는 `Draft → In-Progress → Done`으로 추적.
> end-session에서 Part 3 체크리스트 기반으로 동기화.
> 사이클 운영 절차 상세: `~/.claude/skills/standard-plan-mode/SKILL.md` 참조.

## 작성 시점

| 상황 | plan.md |
|------|---------|
| Standard 워크플로우 | brainstorming → Plan Mode → 승인 → ExitPlanMode → 즉시 저장 |
| PRD 수신 | Plan Mode에서 4-Part로 구조화 → 저장 |

저장 완료 후 `Status: In-Progress`로 변경.

---

## Failure/Success Documentation

> **Auto Dream 활성화 상태**: 메모리 정리는 Auto Dream이 담당.
> 기록은 간결하게 하고, 일회성/프로젝트 종속 패턴은 기록하지 않는다.

### Failure — When to Record

아래 **모두** 충족 시에만 기록:
- 3회 이상 시도 후 실패한 접근법
- **다른 프로젝트에서도 재발 가능한** 범용 패턴
- 코드 수정만으로 방지할 수 없는 판단/사고방식 오류

기록하지 않는 것:
- 일회성 환경 설정 문제 (이미 코드에 반영)
- 특정 외부 API/도구의 quirk (해당 코드에 주석으로 충분)
- CLAUDE.md 규칙 위반 (규칙 자체가 방지 역할)

### Success — When to Record

의미 있는 성공 패턴을 기록한다:
- 복잡한 문제를 1회 시도에 해결한 접근법
- TDD로 버그를 효과적으로 재현/수정한 사례
- 아키텍처 결정이 올바르게 작동한 경우

### Storage

| 범위 | Failure 경로 | Success 경로 |
|------|------------|-------------|
| 크로스 프로젝트 | `~/.claude/projects/{project}/memory/failure-patterns.md` | `~/.claude/projects/{project}/memory/success-patterns.md` |

파일이 없으면 기록 시점에 생성 (미리 만들지 않음).

### 기록 형식

간결한 형식 사용 (Auto Dream이 정리하기 쉽도록):

```markdown
### {제목}
- {교훈 1줄}
- **Why:** {근본 원인 1줄}
```

상세 Failure Log Template(Date, Attempted, Expected, Actual 등)은 **session-log.md에 기록**하고,
failure-patterns.md에는 교훈만 남긴다.

### Integration

- **3-failure rule** (01-principles.md Debugging): 3회 실패 → oracle-consultation + session-log에 상세 기록 + failure-patterns에 교훈
- **start-session**: Explore Agent가 memory/ 디렉토리에서 failure-patterns.md, success-patterns.md 확인
- **end-session**: 학습 추출 단계에서 success-patterns.md 업데이트

---

For document templates (plan.md 4-Part, session-log.md, failure/success logs), see [templates.md](templates.md).
