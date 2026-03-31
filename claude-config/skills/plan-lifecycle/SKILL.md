---
name: plan-lifecycle
description: Plan 문서 관리 — spec/plan/tasks/session-log 형식, 저장 경로, Frontmatter 추적, 실패/성공 기록 템플릿. 산출물 생성, /start-session, /end-session 시 참조.
user-invocable: false
---

# Plan Lifecycle

## 문서 종류와 역할

| 파일 | 생성 시점 | 작성 방식 | 역할 |
|------|----------|----------|------|
| `spec.md` | 설계 단계 | AC 기반 요구사항 명세 (Given/When/Then) | 완료 기준의 SSOT |
| `plan.md` | 설계 단계 또는 PRD 수신 시 | **원문 그대로** (요약/재작성 금지) | 기술 설계의 SSOT |
| `tasks.md` | plan 작성 후 | 실행 가능한 태스크 분해 (체크리스트) | 진행 추적의 SSOT |
| `research.md` | plan 작성 중 (필요 시) | 기술적 미지수 해결 기록 | 의사결정 근거 |
| `session-log.md` | `/end-session` | 세션별 진행 기록 | 세션 간 컨텍스트 전달 |

프로젝트 내 `specs/` 디렉토리에 함께 저장 (git 관리):
```
{project_root}/specs/NNN-{feature}/
├── spec.md           ← AC 기반 명세
├── plan.md           ← 기술 설계
├── tasks.md          ← 태스크 분해
├── research.md       ← 기술 미지수 해결 (필요 시)
└── session-log.md    ← 세션 추적
```

> Superpowers 기본 경로 (`docs/superpowers/specs/`, `docs/superpowers/plans/`)는 이 규칙으로 오버라이드.

## plan.md 저장 원칙 — 원문 그대로

**절대 규칙: plan.md는 요약하거나 재작성하지 않는다.**

- PRD/계획 원문을 받으면 → frontmatter만 추가하여 그대로 저장
- 도구로 작성한 내용 → 작성된 내용 그대로 저장
- Claude가 "더 낫게" 재구성하는 것은 금지

## Frontmatter 상태 필드

```yaml
---
feature: NNN-feature-name
status: draft          # draft → in-progress → done
created: YYYY-MM-DD
current_phase: 1       # tasks.md Phase 기반 자동 계산
current_step: 0        # tasks.md 완료 태스크 수 기반 자동 계산
branch: ""             # 현재 작업 브랜치
---
```

> `current_phase`, `current_step`은 tasks.md의 체크리스트 상태에서 자동 계산.
> 수동 업데이트 금지 — end-session에서 tasks.md 기반으로 동기화.

## 작성 시점

| 상황 | spec.md | plan.md | tasks.md |
|------|---------|---------|----------|
| Standard | brainstorming 후 작성 (도구: rules/03-integration.md) | brainstorming 후 작성 | plan.md 기반 작성 |
| PRD 수신 | 해당 없음 | PRD 원문 + frontmatter → 즉시 저장 | plan.md 기반 수동 작성 |

저장 완료 후 `status: in-progress`로 변경.

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
- **end-session**: 3C 학습 추출 단계에서 success-patterns.md 업데이트

---

For document templates (spec.md, tasks.md, session-log.md, failure/success logs), see [templates.md](templates.md).
