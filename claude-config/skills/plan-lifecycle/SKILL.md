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

```yaml
---
feature: NNN-feature-name
status: Draft | In-Progress | Done
created: YYYY-MM-DD
current_phase: N
current_step: N
branch: branch-name
---
```

> `Status` 필드는 `Draft → In-Progress → Done`으로 추적.
> end-session에서 Part 3 체크리스트 기반으로 동기화.

## 작성 시점

| 상황 | plan.md |
|------|---------|
| Standard 워크플로우 | brainstorming → Plan Mode → 승인 → ExitPlanMode → 즉시 저장 |
| PRD 수신 | Plan Mode에서 4-Part로 구조화 → 저장 |

저장 완료 후 `Status: In-Progress`로 변경.

---

## Failure/Success Documentation

### Failure — When to Record

아래 상황에서 실패를 기록한다:
- 3회 이상 시도 후 실패한 접근법
- 예상과 다르게 동작한 코드/도구
- 잘못된 가정으로 인한 재작업

### Success — When to Record

의미 있는 성공 패턴을 기록한다:
- 복잡한 문제를 1회 시도에 해결한 접근법
- TDD로 버그를 효과적으로 재현/수정한 사례
- 아키텍처 결정이 올바르게 작동한 경우

### Storage

| 범위 | Failure 경로 | Success 경로 |
|------|------------|-------------|
| 프로젝트 한정 | `.agent/docs/failures.md` | `.agent/docs/successes.md` |
| 크로스 프로젝트 | `~/.claude/projects/{project}/memory/failure-patterns.md` | `~/.claude/projects/{project}/memory/success-patterns.md` |

파일이 없으면 기록 시점에 생성 (미리 만들지 않음).

### Integration

- **3-failure rule** (01-principles.md Debugging): 3회 실패 → oracle-consultation + Failure Log Template으로 기록
- **start-session**: Explore Agent가 memory/ 디렉토리에서 failure-patterns.md, success-patterns.md 확인
- **end-session**: 학습 추출 단계에서 success-patterns.md 업데이트

---

For document templates (plan.md 4-Part, session-log.md, failure/success logs), see [templates.md](templates.md).
