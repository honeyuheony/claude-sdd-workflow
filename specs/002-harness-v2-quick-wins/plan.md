---
type: master-plan
feature: 002-harness-v2-quick-wins
status: Done
tier: Standard
created: 2026-05-03
parts_reviewed: [1, 2, 3, 4]
current_phase: 8
current_step: 12
branch: ""
target_save_path: claude-sdd-workflow/specs/002-harness-v2-quick-wins/plan.md
steering: []
meta_bypass: true   # ← 메타-작업 우회: self-bootstrap mutual lock 방지. ambiguity-check / clarification-budget hard-limit 적용 대상 외
---

# Harness v2 — Quick Wins (QW1–5) 도입

## Part 1: Context & Requirements

### 문제 정의

`claude-sdd-workflow` 하네스가 다음 3가지 한계를 가진다:

1. **brainstorming → Plan Mode 진입 시 모호도 측정 부재**: 사용자 의도가 불명확한 채로 4-Part 작성에 진입하면 후반에 재정렬 비용이 커짐
2. **디버깅 oscillation 자율 감지 부재**: 동일 가설로 반복 시도해도 3-failure rule 트리거 전까지 본인이 못 멈춤
3. **verification 의 의미적 검증 부재**: "테스트 통과 = 완료" 외 LLM-as-Judge 류 의미 검증이 없음

본 1단계는 위 3가지를 한 번에 해소하는 **Quick wins 5개** (QW1–5) 만 도입한다. SU1–6 은 다음 사이클(`specs/003-harness-v2-strategic/`).

**왜 지금**: self-bootstrap. 본인이 만든 게이트가 실전에서 작동하는지 첫 사이클에서 확인하고, 두 번째 사이클부터 자기 자신의 ambiguity-check 를 사용.

### 범위

**In-Scope**:
- 5개 markdown 신설 (QW1–5)
- `templates.md` 의 plan.md 템플릿 frontmatter 에 `ambiguity_score`, `needs_clarification_count` 추가 + Clarifications 섹션 추가
- `rules/05-clarifications.md` 신설 (QW2) — flat 컨벤션 유지
- `rules/04-integration.md` 에 새 skill 들의 호출 위치 1줄씩 추가
- `CLAUDE.md` 규칙 인덱스에 `rules/05-clarifications.md` 추가
- 회귀 테스트: 기존 6개 skill (plan-lifecycle, dev-experiment, oracle-consultation, agent-handbook, standard-plan-mode, steering-load) 의 SKILL.md frontmatter 무변경 검증

**Out-of-Scope**:
- SU1–6 (다음 사이클: drift-monitor, escalation-router, info-gain, test-strength, panel-judge, model-split)
- coverage-scan skill 본격 구현 (placeholder dim 만)
- Stage 3 consensus 본격 구현 (verification-gate.md 의 placeholder section 만)
- 신규 hook 추가 (1단계는 prompt-only · markdown-only)
- Python 스크립트, 외부 의존성

### Acceptance Criteria

#### AC-01: 5 신설 + 6 수정 파일 활성화
- **Given**: `claude-config/` 에 신설·수정 파일이 모두 작성됨
- **When**: `~/.claude/` 로 sync 후 `claude` 재시작
- **Then**: 5개 새 skill / rule markdown 이 SKILL.md frontmatter 인식 단계에서 활성화된다

#### AC-02: ambiguity_score frontmatter stamping
- **Given**: 사이드 프로젝트에서 brainstorming 으로 새 작업을 시작
- **When**: brainstorming 종료 → Plan Mode 진입
- **Then**: 생성된 plan.md frontmatter 에 `ambiguity_score: 0.X` 필드가 stamping 되어 있다 (skip 키워드 미사용 시)

#### AC-03: NEEDS CLARIFICATION 마커 4개 이상이면 Plan Mode 차단
- **Given**: plan.md 본문에 `[NEEDS CLARIFICATION: ...]` 마커가 4개 이상 존재
- **When**: ExitPlanMode 시도
- **Then**: 차단되며 추가 질문이 강제된다 (단 `clarifications: budget-override` frontmatter 필드가 있으면 우회)

#### AC-04: oscillation 감지 시 페르소나 추천
- **Given**: dev-experiment 또는 디버깅 흐름에서 동일 가설로 2번 재시도
- **When**: loop-detector 호출
- **Then**: oscillation 으로 판정 + 5 personas 중 1개 (예: Contrarian) 의 이름이 출력된다

#### AC-05: verification-gate Stage 1 실패 시 Stage 2 미실행
- **Given**: verification-gate 호출
- **When**: Stage 1 (mechanical: lint/test/build) 이 실패 상태로 보고됨
- **Then**: Stage 2 (semantic LLM-as-Judge) 가 실행되지 않고 즉시 차단된다

#### AC-06: 기존 6개 skill 회귀 0
- **Given**: 1단계 완료 후
- **When**: 6개 기존 skill 의 SKILL.md frontmatter (`name`, `description`, `user-invocable`) 를 grep 비교
- **Then**: oracle-consultation 외 5개 skill 의 frontmatter 가 1글자도 변경되지 않았다. oracle-consultation 은 frontmatter 보존 + 본문에 router 섹션 추가만 됐다

#### AC-07: 보고서·실제 레포 4개 불일치 처리 명시
- **Given**: 보고서(research.md) 와 실제 레포 사이 식별된 4개 불일치
- **When**: master plan Part 2 의 "보고서 vs 실제 레포" 섹션을 읽는다
- **Then**: 4개 불일치가 모두 (a)/(b)/...로 결정 명시되어 있다

### Acceptance Criteria — 실행 경로

- 도구 호출 횟수 ≤ 60 (Edit/Write 합산)
- 동일 파일 편집 횟수 ≤ 5
- 금지 도구 0회: `git push`, `rm -rf`, 패키지 install
- 필수 검증: 기존 6개 skill SKILL.md frontmatter grep 1회
- 사용자 승인 게이트: master plan 작성 직후 사용자 명시 OK 받기

---

## Part 2: Technical Design

### 보고서 vs 실제 레포 — 4개 불일치 처리 (AC-07)

| 보고서 | 실제 | 결정 |
|---|---|---|
| `rules/01-principles/clarification-budget.md` (서브디렉토리) | `rules/`는 flat 파일 (01–04) | **(A) flat 유지** — `rules/05-clarifications.md` 신설. 새 도메인이므로 신규 파일이 cleaner. CLAUDE.md 규칙 인덱스도 갱신 |
| `rules/03-integration.md` 의 "3-failure rule" | 실제로 `rules/01-principles.md:74-78` | 보고서 기록 오류 — 본 plan / verification-gate.md / personas 들에서 정확한 경로(`01-principles.md`) 사용 |
| 4개 plugin 외 추가 금지 | settings.json 에 정확히 4개 등록됨 | 일치, 변경 불요 |
| 기존 4개 skill | 실제 6개 skill (위 4개 + standard-plan-mode + steering-load) | AC-06 회귀 검사 시 6개 모두 검증 |

### 영향 파일/모듈

| 파일 | 변경 유형 | 설명 |
|---|---|---|
| `claude-config/skills/plan-lifecycle/ambiguity-check.md` | Create | QW1. 4-dim 가중합 채점 + ≤0.2 게이트 |
| `claude-config/skills/plan-lifecycle/verification-gate.md` | Create | QW5. 3-stage skeleton (1+2 본격, 3 placeholder) |
| `claude-config/skills/plan-lifecycle/templates.md` | Modify | plan.md frontmatter 에 ambiguity_score / needs_clarification_count + Clarifications 섹션 |
| `claude-config/rules/05-clarifications.md` | Create | QW2. NEEDS CLARIFICATION 마커 + 3개 한도 + Clarifications 섹션 컨벤션 |
| `claude-config/skills/dev-experiment/loop-detector.md` | Create | QW4. oscillation 감지 (직전·N-2 diff hash) |
| `claude-config/skills/oracle-consultation/SKILL.md` | Modify | router 섹션 추가, 기존 본문 보존 |
| `claude-config/skills/oracle-consultation/personas/simplifier.md` | Create | QW3-1 |
| `claude-config/skills/oracle-consultation/personas/hacker.md` | Create | QW3-2 |
| `claude-config/skills/oracle-consultation/personas/contrarian.md` | Create | QW3-3 |
| `claude-config/skills/oracle-consultation/personas/researcher.md` | Create | QW3-4 |
| `claude-config/skills/oracle-consultation/personas/architect.md` | Create | QW3-5 |
| `claude-config/rules/04-integration.md` | Modify | 새 skill 들의 호출 위치 1줄씩 추가 |
| `claude-config/CLAUDE.md` | Modify | 규칙 인덱스에 05-clarifications.md 추가 |

총 신설 8 + 수정 4 = **12 파일**.

### 아키텍처 결정 (Q1–Q6 확정)

- **D1 (Q1, specs 위치)**: `claude-sdd-workflow/specs/002-harness-v2-quick-wins/`
- **D2 (Q2, ambiguity-check ↔ coverage-scan)**: 독립. 4-dim 중 'Ontology coverage' dim 을 placeholder. SU 사이클에서 coverage-scan 으로 교체
- **D3 (Q3, oracle-consultation 5분할)**: 인터페이스만, router 보존. 5 페르소나 SKILL.md 신설 + `oracle-consultation/SKILL.md` 는 frontmatter 보존, 본문에 router 섹션 추가만. 라우팅 로직 본격 구현은 SU2
- **D4 (Q4, ambiguity 채점 시점)**: brainstorming 종료 시 자동 채점. `ambiguity-check skip` 키워드로 Quick tier 처럼 우회
- **D5 (Q5, clarification budget)**: hard limit (4개 이상 차단). frontmatter `clarifications: budget-override` 로 명시 우회
- **D6 (Q6, evaluator prompt 언어)**: 영문 evaluator instructions, 한국어 evaluation target. 근거: G-Eval/FLEURS 류 cross-lingual robustness. CLAUDE.md '응답은 한국어' 는 user-facing 한정 → internal evaluator 는 예외 명시

### 검토한 대안

| 대안 | 장점 | 단점 | 선택 |
|---|---|---|---|
| QW2 (B): 01-principles.md 한 섹션 | 파일 수 최소 | 새 도메인을 기존 파일에 끼워넣으면 응집도 저하 | 기각 |
| Q3 (a) backward-compat shim | 1단계 라우팅 작동 | SU2 와 중복 작업 | 기각 |
| Q3 (b) hard cut | 단순 | 1단계 범위 초과 + 회귀 위험 | 기각 |
| Q5 (b) soft warning | 마찰 적음 | self-bootstrap 시 무시 가능 | 기각 |
| Q6 한국어 evaluator | CLAUDE.md 일관성 | cross-lingual robustness 손실 | 기각 |

---

## Part 3: Tasks

### Phase 1: 기초
- [x] [T001] 사용자 결정 (Q1–Q6) 확정 → 본 master plan Part 2 에 기록 완료
- [x] [T002] master plan 초기화 — 본 파일 생성 완료

### Phase 2: QW1 (Ambiguity Check)
- [x] [T003] `claude-config/skills/plan-lifecycle/ambiguity-check.md` — 4-dim 가중합 + ≤0.2 게이트 + skip 키워드

### Phase 3: QW2 (Clarification Budget)
- [x] [T004] || `claude-config/rules/05-clarifications.md` — NEEDS CLARIFICATION 마커 컨벤션 + 3개 한도 + Clarifications 섹션 정의
- [x] [T005] || `claude-config/skills/plan-lifecycle/templates.md` — plan.md 템플릿에 frontmatter 필드 + Clarifications 섹션 추가

### Phase 4: QW3 (5 Personas)
- [x] [T006] || `claude-config/skills/oracle-consultation/personas/{simplifier,hacker,contrarian,researcher,architect}.md` 5 파일 작성 (병렬)
- [x] [T007] `claude-config/skills/oracle-consultation/SKILL.md` 에 router 섹션 추가 (frontmatter 보존, +38 line, body-only)

### Phase 5: QW4 (Loop Detector)
- [x] [T008] `claude-config/skills/dev-experiment/loop-detector.md` — 직전·N-2 시도 diff hash 비교 + 페르소나 1개 추천

### Phase 6: QW5 (Verification Gate)
- [x] [T009] `claude-config/skills/plan-lifecycle/verification-gate.md` — Stage 1 mechanical, Stage 2 semantic 영문 prompt, Stage 3 placeholder

### Phase 7: 통합
- [x] [T010] `claude-config/rules/04-integration.md` — 새 skill 호출 위치 1줄씩 추가 (Phase 2 / Phase 5 / Phase 6 / 도구 목록)
- [x] [T011] `claude-config/CLAUDE.md` — 규칙 인덱스에 `rules/05-clarifications.md` 추가

### Phase 8: 검증 (AC 순회)
- [x] [T012] AC1–AC7 1건씩 grep 검증 — 모두 PASS. ~/.claude/ sync 는 사용자 명시 후 진행

---

## Part 4: Risks & Verification

### 기술적 위험

| 위험 | 영향 | 완화 |
|---|---|---|
| oracle-consultation/SKILL.md 수정 시 기존 frontmatter (name, description) 변경 | 3-failure rule (01-principles.md:75-79) 호출 실패 + AC-06 위반 | T007 에서 frontmatter 라인 그대로 보존 + 본문 끝에 `## Routing to Personas` 섹션만 추가 |
| ambiguity-check 4-dim 가중치 default 가 사이드 프로젝트에서 부적합 | 채점 결과 의미 없음 | default 25/25/25/25 + 사이드 프로젝트 시운전 후 회고에서 조정 (SU 사이클로 위임) |
| hard limit (D5) 가 본 1단계 plan.md 자체에 적용 시 mutual lock | 1단계 작업 자체가 차단 | master plan frontmatter `meta_bypass: true` 명시 + ambiguity-check.md / 05-clarifications.md 본문에 meta-bypass 우회 명시 |
| Stage 2 영문 prompt 가 한국어 산출물과 mismatch | evaluator 가 한국어 못 읽음 | verification-gate.md 의 evaluator prompt template 에 `# Note: evaluation target may be in Korean. Read it as-is and reason in English.` 명시 |
| QW3 페르소나 라우팅이 1단계에서 미작동 | AC-04 의 "5 personas 중 하나를 추천" 이 placeholder 수준 | AC-04 를 narrow: "loop-detector 가 추천 페르소나 이름 1개 출력" 으로 정확히 매핑. 실제 자동 라우팅은 SU2 |
| Windows 환경에서 ~/.claude/ sync 시 path 불일치 | T012 검증 실패 | T012 의 sync 는 사용자 명시 동작 후 진행. plan 단독으로는 claude-config/ 에만 작성 |
| `rules/05-clarifications.md` 신설로 CLAUDE.md 규칙 인덱스 mismatch | 문서 정합성 깨짐 | T011 에서 인덱스 갱신 + AC-01 검증 시 인덱스도 확인 |

### 검증 기준 (AC 매핑)

| AC | 검증 방법 | 기대 결과 |
|---|---|---|
| AC-01 | `claude-config/` 의 5 신설 파일 + 4 수정 파일 모두 존재 + frontmatter parsable | 9 파일 정상 |
| AC-02 | `ambiguity-check.md` 본문에 "frontmatter stamping 절차" 가 명시 | 절차 1개 이상 |
| AC-03 | `05-clarifications.md` + `templates.md` 가 hard limit (4 이상 차단) 을 명시 | 양쪽 일치 |
| AC-04 | `loop-detector.md` 가 "페르소나 1개 이름 출력" 절차를 명시 | 절차 1개 이상 |
| AC-05 | `verification-gate.md` 에 "Stage 1 fail → Stage 2 미실행" 가 명시 | 명시 1개 |
| AC-06 | 기존 6개 skill SKILL.md grep 비교 (T007 직전 백업과) | oracle-consultation 외 0 변경 |
| AC-07 | 본 plan.md Part 2 의 "보고서 vs 실제 레포" 표 4행 모두 결정 명시 | 4행 모두 ✅ |

### 다음 사이클로 위임

- **SU1 drift-monitor**: 3-component drift (Goal 50/Constraint 30/Ontology 20) + threshold 0.3
- **SU2 escalation-router**: oscillation→Contrarian, no-drift→Researcher, diminishing→Simplifier, spinning→Hacker 자동 라우팅
- **SU3 info-gain**: trajectory-level metric (info-gain, tool success%, stuck-in-loop) + session-log.md 4-field 강제
- **SU4 test-strength**: PBT + mutation strength check
- **SU5 panel-judge**: Stage 3 본격 (Conservative Reviewer / Performance Critic / Edge-case Hunter + CoT-resistant)
- **SU6 model-split**: Plan Mode = Opus high effort, Code Mode = Sonnet 매트릭스
