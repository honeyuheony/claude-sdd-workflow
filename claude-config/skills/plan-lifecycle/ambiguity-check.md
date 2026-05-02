---
name: ambiguity-check
description: brainstorming 종료 시점에 사용자 의도의 모호도를 4-dim 가중합으로 채점. 점수 ≤ 0.2 일 때만 Plan Mode 진입 허용. plan.md frontmatter 에 ambiguity_score 필드 stamping. Standard tier 필수, Quick tier 선택. skip 키워드 우회 가능.
user-invocable: false
---

# Ambiguity Check

**brainstorming 종료 직후 → Plan Mode 진입 사이의 표준 게이트.** 사용자 의도의 모호도를 4 차원에서 채점하고, 점수 ≤ 0.2 일 때만 Plan Mode 진입을 허용한다. 점수 자체는 plan.md frontmatter 에 stamping 해 이후 회고시 추적 가능하게 한다.

## When to Invoke

| 상황 | 호출 여부 |
|---|---|
| Standard tier brainstorming 종료 직후 (Plan Mode 진입 전) | **필수** (자동) |
| Quick tier | 선택 |
| `ambiguity-check skip` 키워드 명시 | skip |
| `meta_bypass: true` (메타-작업: 하네스 자체 self-upgrade) | skip |
| brainstorming 없이 바로 Plan Mode 진입 (PRD 수신 등) | 선택 |

우회 일때도 frontmatter 에 `ambiguity_score: skip` 으로 명시 stamping 한다 (회고 시 skip 판정 근거 추적).

## 4-dim 채점 (각 0.0–1.0, 높을수록 모호)

각 dim 을 독립적으로 채점. brainstorming 종료 직후 대화 내용만을 근거로 한다. 추측·조사 금지.

### Dim 1 — Goal Clarity (목표 명료도)

| 점수 | 조건 |
|---|---|
| 0.0 | 명시적 1줄 목표 + 성공/실패 판정 테스트 존재 |
| 0.3 | 목표는 1줄, 테스트 없음 |
| 0.6 | 목표가 여러 개 또는 모호한 표현 ("개선", "최적화") |
| 1.0 | 목표가 설명되지 않았거나 \"잘 돌아가게\" 류 |

### Dim 2 — Constraint Completeness (제약 완결성)

| 점수 | 조건 |
|---|---|
| 0.0 | 기술 제약 (언어/프레임워크/라이브러리 버전/성능 임계) 모두 명시 |
| 0.3 | 기술 제약 주요 1–2개 누락 |
| 0.6 | 제약 절반 이상 않함 |
| 1.0 | 제약 완전 부재 — 구현 결정이 주관적 |

### Dim 3 — Acceptance Criteria Specificity (수용 기준 구체성)

| 점수 | 조건 |
|---|---|
| 0.0 | 검증 가능한 AC ≥ 3개 (Given/When/Then 또는 수치 임계) |
| 0.3 | AC 1–2개, 나머지 \"잘 동작\" 류 |
| 0.6 | AC 가 \"더 빠르게\", \"더 깔끔하게\" 따위 주관적 |
| 1.0 | AC 자체가 없음 (완료 조건 불명) |

### Dim 4 — Ontology Coverage (도메인 용어 정의) — placeholder

| 점수 | 조건 |
|---|---|
| 0.0 | 핵심 도메인 용어가 brainstorming 중 1회 이상 명시 정의되거나 상호 수렴 |
| 0.5 | 도메인 용어가 등장하지만 정의 없이 사용 |
| 1.0 | 도메인 용어 정의 0 또는 서로 다른 의미로 사용 |

> **Note (Q2 결정)**: Dim 4 는 placeholder. 이후 SU 사이클에서 별도 `coverage-scan` skill 이 도입되면 Dim 4 채점은 그 skill 출력을 그대로 사용. 1단계에서는 본 skill 이 독립적으로 휴리스틱 채점.

## 가중합

```
ambiguity_score = 0.25 · D1 + 0.25 · D2 + 0.25 · D3 + 0.25 · D4
```

기본 가중치 25/25/25/25. 사이드 프로젝트에서 도메인별로 조정 가능하도록 SU 사이클에 위임. 1단계에서는 고정.

점수 범위: 0.0 (완전 명료) – 1.0 (완전 모호).

## 게이트

| 점수 | 행동 |
|---|---|
| `≤ 0.2` | **PASS** — Plan Mode 진입 허용. plan.md frontmatter 에 점수 stamping |
| `0.2 < score ≤ 0.4` | **WARN** — 사용자에게 고위험 dim 1–2개 명시 보고 + \"그래도 진행?\" 확인. 명시 승인 시 PASS 처리, frontmatter 는 원 점수로 stamping |
| `> 0.4` | **BLOCK** — Plan Mode 진입 차단. 고위험 dim 근거 제시 + 추가 brainstorming 강제 |

우회 경로 (§ When to Invoke 참조):
- `ambiguity-check skip` 키워드 명시 → 채점 자체를 건너뛰고 frontmatter 에 `ambiguity_score: skip` stamping
- `meta_bypass: true` (메타-작업) → 동일

## frontmatter Stamping

PASS 또는 WARN 명시 승인 시 Plan Mode 진입 직후, master plan frontmatter 에 다음 필드 추가 (`plan-lifecycle/templates.md` 참조):

```yaml
ambiguity_score: 0.15           # ≤ 0.2 (PASS) 또는 0.2 < x ≤ 0.4 (WARN, 동의)
ambiguity_dims: [0.1, 0.2, 0.1, 0.2]   # [D1, D2, D3, D4] 소수점 1자리
ambiguity_check: pass           # pass | warn-accepted | skip
```

BLOCK 이면 frontmatter 를 작성하지 않은다 (Plan Mode 진입 자체 차단).

## 사용 절차

```
1. brainstorming 종료 시점 판정 — 사용자가 \"다음 단계\", \"plan 착수\", \"설계 시작\" 류 명시
2. 우회 키워드 검사 (위 표)
3. 해당 없으면 4-dim 채점 — 각 dim 채점 근거 1줄씩 응답에 명시
4. 가중합 계산 → 점수 출력
5. 게이트 판정 (PASS / WARN / BLOCK)
6. PASS 또는 WARN 승인 시 → standard-plan-mode skill 로 흐름 이양 + Plan Mode 진입 직후 frontmatter stamping
7. BLOCK 이면 → 고위험 dim 근거 + 구체 질문 1–2개 더 프롬프트 → brainstorming 재개
```

채점 절차 자체는 응답에 명시:

```markdown
## Ambiguity Check (brainstorming 종료 시점)

- D1 Goal Clarity: 0.1 — \"X 클래스에 cache 추가\" 명시 + 벤치마크 AC 존재
- D2 Constraint Completeness: 0.2 — 언어/라이브러리 명시, 성능 임계 누락
- D3 AC Specificity: 0.1 — 수치 AC 3개 명시
- D4 Ontology Coverage (placeholder): 0.2 — \"cache\" 용어 정의 없이 사용
- 가중합: 0.25·0.1 + 0.25·0.2 + 0.25·0.1 + 0.25·0.2 = **0.15**
- 게이트: PASS (≤ 0.2)
- 다음 단계: Plan Mode 진입 + frontmatter stamping
```

## standard-plan-mode 와의 통합

- standard-plan-mode skill 은 brainstorming 종료 시점을 이미 감지하고 Plan Mode 진입을 제안한다
- 본 skill 은 그 제안 직전에 호출되어 게이트 역할
- BLOCK 일 때 standard-plan-mode skill 의 사이클 1 (Part 1 작성) 자체를 차단

## 안티패턴

- "채점 없이 그냥 다음으로" → 자동 호출 명싈 위반. 우회 키워드 명시 없이 건너뛰기 금지
- "PASS 면 되서 skip 으로 표기" → 회고 시 근거 손실. 원 점수로 stamping
- "WARN 잠금 자동 승인" → WARN 은 반드시 사용자 명시 확인 이후만 PASS 처리
- "BLOCK 이지만 쿨다고 키워드 우회" → `ambiguity-check skip` 은 사용자 명시 명령일 때만 적용. Claude 자체 판단으로 우회 금지
