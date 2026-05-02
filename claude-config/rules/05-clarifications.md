# Clarifications

`[NEEDS CLARIFICATION]` 마커, 3개 한도, plan.md Clarifications 섹션 컨벤션.

## 원칙

**Plan 작성 중 불확실한 항목은 "추측"이 아니라 "표시"한다.**

- 추측으로 채워 넣은 plan 은 실행 단계에서 비싸게 깨진다 — 사용자에게 명시 질문하는 비용은 항상 더 싸다
- 단 불확실 마커가 너무 많으면 (4개 이상) plan 자체의 기반이 무너진 신호 → brainstorming 으로 회귀 강제
- 마커 자체는 plan.md 에 보존 — 회고 시 어디에서 모호도가 발생하는지 추적 가능

## NEEDS CLARIFICATION 마커

### 형식

plan.md 본문 어디에서나 사용:

```markdown
[NEEDS CLARIFICATION: 짧은 질문 1줄 — 누구에게(사용자/오라클)]
```

예시:

```markdown
- API 응답 시간 목표: [NEEDS CLARIFICATION: p95 또는 p99? — 사용자]
- 캐시 TTL: [NEEDS CLARIFICATION: 5분 충분한가? — 사용자]
- DB 마이그레이션 전략: [NEEDS CLARIFICATION: blue-green 가능한가? — 오라클]
```

### 작성 규칙

- 한 마커 = 한 질문 (복합 질문 금지)
- 질문은 1줄, 누구에게 (사용자/오라클/팀) 명시
- 답변이 결정되면 마커를 제거하고 `## Clarifications` 섹션의 Resolved 에 결정 내용 옮긴다
- 절대 추측으로 채우지 않는다

## 3개 한도 (Hard Limit)

`plan.md` 본문 전체에서 unresolved `[NEEDS CLARIFICATION]` 마커는 **최대 3개**.

| 마커 수 | 행동 |
|---|---|
| 0–3개 | 정상. ExitPlanMode 통과 |
| 4개 이상 | **차단**. Plan Mode 진입 또는 ExitPlanMode 시 hook 차단 + 사용자에게 추가 brainstorming 강제 |

### 우회 (override)

극단적 상황에서 사용자가 명시 우회 시:

```yaml
---
clarifications: budget-override
clarifications_override_reason: "탐색적 PoC, 미정 항목 다수가 의도된 작업"
---
```

frontmatter 에 `clarifications: budget-override` 가 있으면 한도 초과해도 통과. **단 우회 사유(`clarifications_override_reason`) 1줄 필수**.

### 메타-작업 우회

하네스 자체의 self-upgrade (`meta_bypass: true` frontmatter) 인 경우 자동 우회. 본 1단계 plan.md 가 이 경우.

## Clarifications 섹션 (plan.md 내)

plan.md 의 Part 1 끝에 별도 `## Clarifications` 섹션을 둔다 (templates.md 의 plan.md 템플릿 참조).

### 섹션 구조

```markdown
## Clarifications

### Open (3개 이하)
- [ ] [Q1] 캐시 TTL 5분 충분한가? — 사용자
- [ ] [Q2] DB 마이그레이션 blue-green 가능? — 오라클

### Resolved
- [x] [Q3] API p95 200ms — 사용자 답변 (2026-05-03)
  - **결정**: p95 200ms 임계
  - **근거**: 사용자 SLA 명시
```

### 운영 규칙

- Open 항목은 본문의 `[NEEDS CLARIFICATION]` 마커와 1:1 매핑 (ID 일치)
- 답변 받으면 Open → Resolved 이동 + 본문 마커 제거
- Open 의 개수가 4 이상이면 hook 차단 (위 §3개 한도)
- Resolved 항목은 보존 — 회고 시 어떤 결정이 있었는지 추적

## frontmatter 필드

`templates.md` 의 plan.md 템플릿에 추가될 필드 (master plan):

```yaml
needs_clarification_count: 0    # plan.md 본문의 unresolved 마커 수. 4 이상이면 hook 차단
clarifications: ""              # \"budget-override\" 명시 시 한도 우회. 비어 있으면 정상
clarifications_override_reason: ""  # 우회 사유 1줄. budget-override 일 때 필수
```

`needs_clarification_count` 는 plan 작성·수정 시 본인이 본문 마커를 grep 해 stamping 한다. 자동화 hook 은 SU 사이클에서 도입.

## 통합 지점

- **ambiguity-check skill**: brainstorming 종료 직후 채점. ambiguity_score 의 D3 (AC Specificity) 가 NEEDS CLARIFICATION 마커 수와 음의 상관 관계
- **standard-plan-mode skill**: 매 사이클 ExitPlanMode 직전 본인이 마커 수를 frontmatter 에 stamping
- **exit-plan-mode-guard hook (SU 사이클)**: hook 자체가 plan.md 마커 수 검증 (1단계는 Claude 본인 검증)

## 안티패턴

- "마커 4개라 한도 초과 → 일부 추측으로 채우자" → 추측 금지. budget-override 가 아니면 brainstorming 으로 회귀
- "Resolved 로 옮기면서 본문 마커는 안 지움" → 1:1 매핑 유지
- "override 사유가 막연하게 \"필요\"" → 구체적 사유 1줄. \"PoC 단계, 사용자 의도 일부 미정 의도적\" 같은 형태
- "메타-작업이라 한도 무시" → meta_bypass 플래그 명시 + 본문에 우회 근거 작성
