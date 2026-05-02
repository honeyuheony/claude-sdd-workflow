# Harness v2 — Quick Wins & Strategic Upgrades 보고서

> 본 문서는 `claude-sdd-workflow` 하네스의 self-upgrade 를 위한 SOT(Source of Truth) 리서치 보고서다.
> 1단계 Quick wins (QW1–5) 한 사이클 → 검증 → 2단계 Strategic upgrades (SU1–6) 한 사이클로 끊어 진행한다.
> 이렇게 끊으면 본인이 만든 게이트가 실제로 작동하는지 첫 사이클에서 확인하고, 두 번째 사이클부터 자기 자신의 ambiguity-check 를 사용할 수 있다 (self-bootstrap).

---

## 0. 메타-작업 개요

- **대상**: `~/.claude/` 디렉토리와 본 레포의 `claude-config/` 디렉토리
- **산출물**: 거의 모두 markdown (skills / rules / commands)
- **운영 원칙**: prompt-only · markdown-only. Python 스크립트나 외부 의존성 추가 금지
- **플러그인 제약**: 기존 superpowers / plannotator / context7 / hookify 4개 외 추가 금지
- **언어 정책**: 한국어 우선, 영문 기술용어 병기. metric 이름과 threshold 는 영문 유지

---

## 1단계 — Quick Wins (QW1–5)

### QW1. Ambiguity Score skill (4-dim 가중합, ≤0.2 게이트)
- **위치**: `skills/plan-lifecycle/ambiguity-check.md` 신설
- **목적**: brainstorming 종료 시 사용자 의도의 모호도를 4-dim 가중합으로 산출하고 ≤0.2 게이트를 통과해야 Plan Mode 진입 허용
- **4-dim 후보**:
  1. Goal clarity (목표 명료도)
  2. Constraint completeness (제약 완결성)
  3. Acceptance criteria specificity (수용 기준 구체성)
  4. Ontology coverage (도메인 용어 정의 커버리지)
- **가중치**: 추후 brainstorming 에서 결정 (default 25/25/25/25 또는 30/30/25/15)

### QW2. [NEEDS CLARIFICATION] 마커 + 3개 한도 + Clarifications 섹션
- **위치**:
  - `rules/01-principles/clarification-budget.md` 신설
  - `skills/plan-lifecycle/templates.md` 의 `plan.md` 템플릿 수정
- **규칙**: `[NEEDS CLARIFICATION]` 마커가 4개 이상이면 Plan Mode 진입 차단, 추가 질문 강제
- **결정 필요**: hard limit vs soft warning (brainstorming Q5)

### QW3. 5 Lateral Personas as skills
- **위치**: `skills/oracle-consultation/` 을 5개 sub-skill 디렉토리로 재구성
- **5 페르소나**:
  1. Simplifier (단순화 지향)
  2. Hacker (해커 사고 / unconventional)
  3. Contrarian (반대 관점 / devil's advocate)
  4. Researcher (조사 / evidence-first)
  5. Architect (아키텍처 관점)
- **호환성**: 기존 oracle-consultation 의미 보존하되 페르소나 분리. 기존 호출자(`rules/03-integration.md` 의 "3-failure rule")와 backward-compat 여부는 brainstorming Q3 에서 결정

### QW4. Oscillation 감지 (직전·N-2 시도 diff hash 비교)
- **위치**: `skills/dev-experiment/loop-detector.md` 신설
- **로직**: 같은 가설로 2번 재시도 시 diff hash 비교 → 동일하면 oscillation 으로 판정 → 5 personas 중 하나 추천

### QW5. 3-stage gate skeleton (Mechanical → Semantic → Consensus 분리)
- **위치**: `skills/plan-lifecycle/verification-gate.md` 신설
- **3 stage**:
  - **Stage 1 — Mechanical**: lint / type / test / build 등 자동화 가능한 검증
  - **Stage 2 — Semantic**: LLM-as-Judge 의 의미적 검증 (prompt 는 영문 권장 — robust)
  - **Stage 3 — Consensus**: 다중 페르소나 panel + meta-judge (이번 사이클은 placeholder 만, SU5 에서 본격 구현)
- **순서 보장**: Stage 1 실패 시 Stage 2 실행 금지

---

## 2. Phase 2 Brainstorming 필수 질문 6개

1. **specs/ 디렉토리 위치**: `claude-sdd-workflow` 레포 vs 다른 레포 vs `~/.claude/specs`
2. **skill 간 호출 관계**: `ambiguity-check` 가 `coverage-scan`(추후 추가) 을 호출하는 형태인가, 독립인가
3. **oracle-consultation 5분할 시 기존 "3-failure rule" 트리거 통합 방식**: 페르소나 라우팅과 어떻게 묶을지 (실제 라우팅 구현은 SU2, 이번엔 인터페이스만 미리 정의)
4. **ambiguity score 채점 시점**: 매 brainstorming 종료 시점에 강제 vs 사용자 명시 호출
5. **clarification-budget 3개 한도**: hard limit vs soft warning
6. **verification-gate Stage 2 LLM-as-Judge prompt 언어**: 한국어 vs 영문 (산출물은 한국어, 평가 prompt 는 영문이 일반적으로 robust — 함정 질문, 근거 같이 적을 것)

---

## 3. 본 작업의 Tier 와 워크플로우

- **Tier**: Standard
- **Phases**: 6-Phase 모두 (Explore → Brainstorm → Plan Mode → Branch → TDD-style → Verify)
- **TDD 변형 (markdown-only 작업이므로)**:
  - **Red**: 새 skill 의 사용 시나리오를 `plan.md` Part 4 에 명시 후, 아직 skill 이 없으면 어떻게 실패하는지 기술
  - **Green**: skill markdown 작성
  - **Refactor**: 기존 skills / rules / commands 와의 충돌 · 중복 제거 (핵심 단계)
- **Plan Mode 진입 후 ExitPlanMode 직전**: plannotator 로 시각 리뷰 요청

---

## 4. 제약 사항

- 한국어 우선, 영문 기술용어 병기. metric 이름과 threshold 는 영문 유지
- prompt-only · markdown-only. Python 스크립트나 외부 의존성 추가 금지
- `~/.claude/` 변경 전 반드시 `claude-config/` 레포에 먼저 commit
- 기존 superpowers / plannotator / context7 / hookify 4개 plugin 외에 추가 금지
- Plan Mode 진입 후 ExitPlanMode 직전에 plannotator 로 시각 리뷰 요청

---

## 5. 1단계 수용 기준 (Acceptance Criteria)

`plan.md` Part 1 에 정형화할 것.

- **AC1**: 5개 새 skill / rules markdown 이 `claude-config/` 에 추가되고 `~/.claude/` 로 복사된 뒤 `claude` 재시작 후 활성화된다.
- **AC2**: 새 prompt 한 건을 brainstorming 으로 시작하면 ambiguity-check 가 자동으로 4-dim 채점을 산출하고 `plan.md` Part 1 frontmatter 에 `ambiguity_score` 필드가 stamping 된다.
- **AC3**: `plan.md` Part 1 에 `[NEEDS CLARIFICATION]` 마커가 4개 이상이면 Plan Mode 진입이 차단되고 추가 질문이 강제된다.
- **AC4**: 디버깅 시뮬레이션(같은 가설로 2번 재시도)을 하면 loop-detector 가 oscillation 을 감지하고 5 personas 중 하나를 추천한다.
- **AC5**: verification-gate 가 Stage 1 (mechanical) → Stage 2 (semantic LLM judge) 순서로 작동하고, Stage 1 실패 시 Stage 2 가 실행되지 않는다.
- **AC6**: 기존 plan-lifecycle / dev-experiment / oracle-consultation / agent-handbook 4개 skill 의 동작에 회귀가 없다.

---

## 6. 1단계 운영 팁

1. **brainstorming Q6 (한국어 vs 영문 prompt)** 는 살짝 함정 — 한국어 우선 컨벤션이 있어도 LLM-as-Judge prompt 는 영문이 안정적이라는 게 연구 결과. 답변에 근거 같이 적을 것.
2. **Plan Mode 산출 직후 plannotator 시각 리뷰** — `plan.md` Part 3 의 task 의존성(`Depends on:`)이 정확한지 확인. 본인 하네스 메타작업이라 의존성이 자기-참조되기 쉬움.
3. **Phase 5 Refactor 단계가 핵심** — 기존 oracle-consultation 5분할 시 기존 호출자(`rules/03-integration.md` 의 "3-failure rule")가 깨지지 않도록 backward-compat shim 을 둘지 hard cut 할지 결정. brainstorming Q3 에서 미리 정함.
4. **이번 사이클 끝나고 반드시 한 번 다른 사이드 프로젝트에 새 ambiguity-check skill 을 실전 시운전** — SAI 작업에 바로 적용 금지. 이게 self-bootstrap 검증.

---

## 2단계 — Strategic Upgrades (SU1–6)

> 1단계 모든 AC가 PASS 되고 한 번 이상 실전 시운전 후 진입한다.
> 회고를 `specs/003-harness-v2-strategic/retrospective.md` 에 먼저 작성한 후 도입.

### SU1. 3-component Drift 측정
- **위치**: `skills/plan-lifecycle/drift-monitor.md` 신설
- **가중치**: Goal 50% / Constraint 30% / Ontology 20%
- **threshold**: 0.3
- **연결**: hookify 의 `PostToolUse(Write|Edit)` hook 에 연결

### SU2. 자동 페르소나 라우팅
- **위치**: `skills/dev-experiment/escalation-router.md` 신설
- **라우팅 매트릭스**:
  - oscillation → Contrarian
  - no-drift → Researcher
  - diminishing returns → Simplifier
  - spinning (방향 못 잡음) → Hacker
- **연결**: 1단계의 loop-detector 와 5 personas 를 라우터로 묶음

### SU3. Trajectory-level metric
- **위치**: `skills/dev-experiment/info-gain.md` 신설
- **metric**:
  - Info-gain (per attempt)
  - Tool Success %
  - Stuck-in-Loop ratio
- **강제**: `session-log.md` 의 `## Attempts` 섹션을 정형 4-field 로 강제

### SU4. Property-based AC + Mutation strength check
- **위치**:
  - `plan.md` 템플릿의 Part 1 AC 를 "Examples (Gherkin)" + "Invariants (PBT)" 두 섹션으로 분리
  - `skills/plan-lifecycle/test-strength.md` 신설 (옵션 호출)

### SU5. Diverse-persona panel + meta-judge (Stage 3 본격 구현)
- **위치**: 1단계의 `verification-gate.md` 의 Stage 3 placeholder 채우기
- **3 페르소나**:
  - Conservative Reviewer
  - Performance Critic
  - Edge-case Hunter
- **CoT-resistant prompt (E6)** 적용

### SU6. Architect/Editor 모델 분리
- **위치**: `CLAUDE.md` 와 `settings.json` 에 매트릭스 명시
- **매트릭스**:
  - Plan Mode = Opus high effort
  - Code Mode = Sonnet 기본

---

## 7. 2단계 진입 전 회고 작성 (retrospective)

`specs/003-harness-v2-strategic/retrospective.md` 에 1주일간의 운영 데이터 기반 작성:

1. ambiguity-check 가 실제로 brainstorming 조기종료를 방지했는지
2. oscillation 감지가 false positive 가 얼마나 많았는지
3. verification-gate Stage 1+2 가 어느 단계에서 false negative 를 냈는지

회고 작성 후 Phase 1 (Explore) 부터 진행. verification 시 자기 자신의 Stage 3 panel-judge 를 사용해야 한다 (self-bootstrap 의 두 번째 단계).

---

## 8. 전체 흐름 요약 (Ouroboros)

```
1단계 (QW1–5)
   ↓ markdown 작성 + 회귀 테스트
   ↓ AC1–AC6 검증
   ↓ 한 사이드 프로젝트 실전 시운전 (1주일+)
   ↓
회고 (retrospective.md)
   ↓
2단계 (SU1–6)
   ↓ 자기 자신의 Stage 3 panel-judge 로 verification
   ↓ self-bootstrap 완성
```

본인 하네스의 진화 자체를 본인 하네스로 관리하는 구조. 사람 승인 게이트가 사이마다 끼어 있어 enterprise-safe.

---

## 부록 A — 1단계 시작 프롬프트 (보존용)

```
작업 컨텍스트
─────────────
이번 작업은 내가 운영 중인 Claude Code SDD 하네스(claude-sdd-workflow)
자체의 self-upgrade다. 즉 작업 대상이 ~/.claude/ 디렉토리와 이 레포의
claude-config/ 디렉토리이며, 산출물은 거의 모두 markdown(skills/rules/commands).

선행 리서치는 specs/002-harness-v2-quick-wins/research.md 에 저장되어 있다.
이 보고서가 SOT(Source of Truth)다. 보고서를 먼저 읽고 작업을 시작해.

작업 목표 — Quick wins 5개만 이번 사이클에 도입한다
─────────────────────────────────────────────────
QW1. Ambiguity Score skill (4-dim 가중합, ≤0.2 게이트)
     → skills/plan-lifecycle/ambiguity-check.md 신설
QW2. [NEEDS CLARIFICATION] 마커 + 3개 한도 + Clarifications 섹션
     → rules/01-principles/clarification-budget.md 신설
     → skills/plan-lifecycle/templates.md 의 plan.md 템플릿 수정
QW3. 5 Lateral Personas as skills (Simplifier/Hacker/Contrarian/Researcher/Architect)
     → skills/oracle-consultation/ 을 5개 sub-skill 디렉토리로 재구성
       (기존 oracle-consultation 의미 보존하되 페르소나 분리)
QW4. Oscillation 감지 (직전·N-2 시도 diff hash 비교)
     → skills/dev-experiment/loop-detector.md 신설
QW5. 3-stage gate skeleton (Mechanical → Semantic → Consensus 분리)
     → skills/plan-lifecycle/verification-gate.md 신설
     → 이번 사이클은 Stage 1+2 까지만 구현, Stage 3 는 placeholder 만

[Tier / brainstorming / 제약 / AC 는 본문 참조]

지금 할 것
─────────
Phase 1 (Explore) 부터 시작해. 먼저 research.md 를 정독하고,
~/.claude/ 와 claude-config/ 의 현재 상태를 파악한 후,
이 작업이 기존 skill/rule 들과 어떻게 충돌·통합될지 매핑해줘.

그리고 Phase 2 brainstorming 으로 넘어가서 위 6개 질문을 하나씩 던져.
```

## 부록 B — 2단계 시작 프롬프트 (보존용)

```
작업 컨텍스트
─────────────
specs/002-harness-v2-quick-wins 가 완료되어 1주일 이상 실전 운영했다.
실전 운영 회고를 specs/003-harness-v2-strategic/retrospective.md 에
작성한 후, Strategic upgrades 6개를 도입한다.

선행 리서치: specs/002-harness-v2-quick-wins/research.md 동일 보고서 사용
회고: specs/003-harness-v2-strategic/retrospective.md (먼저 작성)

작업 목표 — Strategic upgrades 6개
──────────────────────────────────
[SU1–SU6 본문 참조]

이번 사이클 Tier 는 Standard. 단 verification 시 자기 자신의 Stage 3
panel-judge 를 사용해야 한다 (self-bootstrap 의 두 번째 단계).

지금 할 것
─────────
1. 먼저 retrospective.md 를 작성: 1단계 도입 후 1주일간의 운영 데이터를
   기반으로 — ambiguity-check 가 실제로 brainstorming 조기종료를
   방지했는지, oscillation 감지가 false positive 가 얼마나 많았는지,
   verification-gate Stage 1+2 가 어느 단계에서 false negative 를
   냈는지.
2. retrospective 작성 후 Phase 1 부터 진행.
```
