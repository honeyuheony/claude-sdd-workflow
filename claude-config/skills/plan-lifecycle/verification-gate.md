---
name: verification-gate
description: Phase 6 검증 단계의 3-stage gate skeleton. Stage 1 (Mechanical) → Stage 2 (Semantic LLM-as-Judge, 영문 prompt) → Stage 3 (Consensus, placeholder). Stage 1 실패 시 Stage 2 실행 차단. superpowers:verification-before-completion 위에 의미 검증 레이어 추가.
user-invocable: false
---

# Verification Gate

Phase 6 의 \"검증 증거 없이 완료 선언 금지\" 원칙 (`rules/01-principles.md` Verification) 의 자율 검증 메커니즘. **3-stage gate** 로 구성된다.

## When to Invoke

| 상황 | 호출 |
|---|---|
| Standard tier Phase 6 검증 단계 (verification-before-completion 직후) | **자동** |
| Quick tier 완료 직전 | 선택 |
| 사용자가 \"검증 강화\" 명시 | 호출 |
| Plan Mode 의 AC-실행경로 (`Acceptance Criteria — 실행 경로`) 가 명시된 작업 | 자동 |

## Stage 순서 — Strict Sequential

```
Stage 1 (Mechanical) → PASS? → Stage 2 (Semantic) → PASS? → Stage 3 (Consensus, placeholder)
                          │                            │
                       FAIL → STOP                  FAIL → STOP
```

**Stage 1 fail → Stage 2 절대 실행 금지** (AC-05). 표면적 mechanical 실패를 LLM-as-Judge 가 \"의미적으로는 ok\" 로 덮어주는 false positive 차단.

---

## Stage 1 — Mechanical

자동화 가능한 객관적 검증. 본 단계는 Claude 가 도구로 실행하고 결과만 보고.

### 검증 항목

| 항목 | 도구 | 통과 기준 |
|---|---|---|
| Type check | `mypy` / `tsc` / `cargo check` 등 | exit 0 |
| Lint | `ruff` / `eslint` / `clippy` 등 | exit 0 |
| Unit / Integration tests | `pytest` / `vitest` / `cargo test` | 모두 pass |
| Build | `npm run build` / `cargo build --release` | exit 0 |
| AC 매핑 — 각 AC 의 자동 검증 가능 부분 | grep / file existence / ad-hoc test | plan.md Part 1 의 각 AC 1:1 |

### 출력 형식

```markdown
## Verification Stage 1 — Mechanical

| 항목 | 도구 | 결과 | 근거 |
|---|---|---|---|
| Type check | mypy | PASS | exit 0 |
| Unit tests | pytest | PASS | 25/25 통과 |
| AC-01 | grep | PASS | API 응답 < 200ms 측정 (p95) |
| AC-02 | file check | FAIL | `dist/index.js` 미생성 |

- **Stage 1 결과**: FAIL (AC-02 실패)
- **다음 단계**: Stage 2 차단. AC-02 원인 분석 후 재호출
```

Stage 1 FAIL 시 즉시 응답 종료. Stage 2 호출 금지.

---

## Stage 2 — Semantic (LLM-as-Judge)

산출물의 **의미적** 검증. \"테스트는 통과했지만 사용자 의도와 맞는가?\" 질문. evaluator instructions 는 영문 (cross-lingual robustness 근거 — G-Eval, FLEURS 류 evaluator 연구 참조).

### 호출 조건

- Stage 1 PASS 상태에서만 호출
- plan.md Part 1 의 AC 와 산출물 (코드, 문서, 행동) 을 함께 evaluator 에 전달
- evaluator 는 별도 SubAgent (Agent tool, subagent_type=general-purpose) 로 호출

### Evaluator Prompt Template (영문)

```
You are a strict semantic evaluator. Your job is to judge whether the produced
artifact actually fulfills the user's intent expressed in the Acceptance Criteria.

# Note
The Acceptance Criteria and the produced artifact may be in Korean. Read them
as-is — do not translate. Reason and emit your verdict in English.

# Inputs
1. Acceptance Criteria (from plan.md Part 1):
   <<AC>>

2. Produced Artifact:
   <<ARTIFACT>>

3. Mechanical Stage 1 result (already PASS):
   <<STAGE1_SUMMARY>>

# Rubric (score each 0–5)

- intent_match: Does the artifact address the *stated* intent of each AC, not just
  pass tests that happen to be related?
- completeness: Are all AC items addressed? Is anything silently dropped?
- side_effects: Does the artifact introduce changes outside the AC scope (feature
  creep, unrequested refactors)?
- robustness: Does the artifact handle the obvious failure modes the AC implies
  (missing input, boundary values, concurrent access)?

# Output (JSON)

{
  "intent_match": <0-5>,
  "completeness": <0-5>,
  "side_effects": <0-5, where 5 = no creep, 0 = heavy creep>,
  "robustness": <0-5>,
  "weakest_dim": "<dim name>",
  "weakest_dim_evidence": "<one sentence pointing to a specific line/AC>",
  "verdict": "PASS" | "WARN" | "FAIL",
  "rationale": "<two sentences max>"
}

# Decision rule
- All four dims >= 4 → PASS
- Any dim == 3 → WARN (report to user, do not block)
- Any dim <= 2 → FAIL (block completion)
```

### 출력 형식 (한국어 사용자-facing)

```markdown
## Verification Stage 2 — Semantic (영문 evaluator → 한국어 보고)

- **intent_match**: 5
- **completeness**: 4
- **side_effects**: 5
- **robustness**: 3 ← weakest
- **weakest_dim_evidence**: \"plan.md Part 1 AC-04 의 '동시 접속 100명' 시나리오 미검증\"
- **verdict**: WARN
- **rationale**: 핵심 의도는 충족하지만 robustness dim 의 동시성 검증 누락

- **다음 단계**: Stage 3 호출 (consensus) — 1단계는 placeholder
```

### 안티패턴

- \"한국어로 evaluator prompt 작성\" → cross-lingual robustness 손실. evaluator instructions 는 영문 고정. 산출물(target) 은 원어 유지
- \"verdict 자체를 Claude 본인이 판단\" → evaluator 는 SubAgent 로 분리. 본인이 채점하면 self-judging bias
- \"Stage 1 fail 인데 의미적으론 괜찮으니 Stage 2 진행\" → AC-05 위반. 절대 금지

---

## Stage 3 — Consensus (Placeholder)

> **1단계 범위 외**. SU5 `panel-judge` 에서 본격 구현.

### 예고 인터페이스

SU5 에서 도입될 3 페르소나 panel:

- **Conservative Reviewer**: 가장 보수적 입장. \"이거 prod 에 올릴 수 있나?\" 관점
- **Performance Critic**: 성능·자원 관점. \"latency, memory, throughput 영향은?\"
- **Edge-case Hunter**: 경계·실패 모드. \"NULL, 빈 입력, race condition, retry storm 은?\"

3 페르소나 각각 verdict 산출 → meta-judge 가 다수결 + tie-breaking. CoT-resistant prompt (E6 — \"don't reason out loud, give only verdict\") 적용해 페르소나 간 chain-of-thought 오염 방지.

### 1단계의 placeholder 구현

Stage 2 PASS 또는 WARN 시 본 단계는:

```markdown
## Verification Stage 3 — Consensus (placeholder, SU5 에서 구현)

- 1단계는 본 단계를 skip
- Stage 2 verdict 를 final verdict 로 사용
- final: PASS / WARN / (FAIL 은 Stage 2 에서 이미 차단)
```

---

## 통합

- **rules/01-principles.md** Verification 의 \"검증 증거 없이 완료 선언 금지\" 원칙의 자율 적용 메커니즘
- **superpowers:verification-before-completion** 위에 의미적 layer 를 얹는 형태. superpowers 호출 후 본 skill 호출
- **plan.md Part 1 AC** 가 evaluator 의 입력. AC 가 모호하면 본 skill 은 의미 있게 동작 못함 → ambiguity-check skill 의 D3 (AC Specificity) 가 사전 게이트
- **04-integration.md** Phase 6 에 본 skill 호출 위치 명시

## 안티패턴

- \"Stage 1, 2 모두 PASS 했으니 Stage 3 placeholder 도 PASS 로 stamping\" → SU5 까지는 final verdict 가 Stage 2 결과. \"placeholder PASS\" 라는 false signal 만들기 금지
- \"evaluator 가 한국어 못 읽어서 PASS 처리\" → evaluator prompt 의 # Note 섹션 (\"may be in Korean, read as-is\") 으로 처리. 그래도 못 읽으면 evaluator 자체가 broken — 사용자에게 보고
- \"산출물이 너무 커서 evaluator 에 일부만 전달\" → AC 와 1:1 매핑되는 부분만 발췌해도 OK. 단 \"발췌됨\" 명시 + 발췌 기준 1줄
