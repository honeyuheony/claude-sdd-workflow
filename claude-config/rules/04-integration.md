# 도구 통합 & 워크플로우

## 모드

**기본은 Edit Mode. 질문형은 Answer Mode, 설계가 필요하면 Plan Mode.**

- Answer Mode: 질문·탐색 — 읽기 도구만, 상태 변경(Edit/Write/git 변경/MCP write) 금지
- Plan Mode: 설계 탐색 및 계획 구조화 (Standard 필수, Quick 선택)
- Edit Mode: 구현, 디버깅, 검증, 코드 리뷰

### 모드 판별

| 신호 | 모드 |
|------|------|
| `?`, `~까?`, `~할까`, `~해볼까`, `어때`, `어떻게`, `왜`, `can/should/how/why` | Answer Mode |
| 명령 동사: `만들어`, `수정해`, `추가해`, `실행해`, `삭제해`, `고쳐` | Edit Mode |
| 다중 파일 변경·아키텍처 결정 필요 | Plan Mode |
| 애매 | Answer Mode 시작 → 제안 → 사용자 승인 후 Edit |

## 용어

| 단위 | 설명 |
|------|------|
| **Task** | 전체 목표 (여러 Phase로 구성) |
| **Phase** | PR 단위 작업 (여러 Step으로 구성) |
| **Step** | Commit 단위 작업 |

---

## Tier 판별

모든 조건 충족 시 **Quick**:
- 1~2파일 변경
- 요건이 한 문장
- 기존 패턴 따름
- 새 아키텍처 결정 없음

그 외 모두 **Standard**:
- 가설 검증이 필요하면 **/dev-experiment** (30분 time-box)

| | Quick | Standard |
|---|---|---|
| Skill checks | TDD/debugging만 | 모든 skill 확인 |
| Explore agents | 1 (Haiku) | 1~3 |
| Plan Mode | 선택 (자유 형식) | 필수 (4-Part 구조) |

---

## Quick 프로세스

```
Explore (Haiku, 1 agent)
  ↓
[Plan Mode — 선택적, 간단한 계획이 필요할 때]
  - brainstorming 생략, 바로 Plan Mode 진입
  - 4-Part 전체 불필요, 자유 형식
  ↓
[TDD if behavioral change]
  ↓
verification-before-completion → Commit
```

---

## Standard 프로세스

```
[설계]
Phase 1: Explore Agent(s) [1~3, parallel, Haiku]
  - 코드베이스 탐색 + memory/ 확인 (failure-patterns, success-patterns)
  ↓
Phase 2: superpowers:brainstorming
  - 인터랙티브 설계 탐색 + 접근법 결정
  ↓
Phase 3: Plan Mode 진입
  - **standard-plan-mode skill 로드 (필수)** — 사이클 단위 진행 절차 강제
  - brainstorming 결과를 4-Part 구조로 정리. 리뷰 단위는 [Part 1] / [Part 2] / [Part 3+4 통합] 3사이클
  - plannotator-annotate가 시스템 Plan Mode 안에서 차단되므로 매 사이클마다 ExitPlanMode → plannotator → EnterPlanMode 사이클 운영
  - 각 사이클: 임시 plan(`master_plan_path` 명시) 작성 → ExitPlanMode → plannotator-annotate 리뷰 → 사용자 승인(피드백 시 Pre-Edit Checklist 5문항 적용) → 임시 plan 변경분을 master로 sync → master frontmatter parts_reviewed에 Part 번호 추가 → EnterPlanMode 재진입
  - 사이클 3 진입 직후 분리 회귀 트리거(태스크 ≥15 / 위험 ≥8 / 글로벌·보안·외부 API 의존)를 판정. 트리거 발동 시 [Part 3 단독] / [Part 4 단독] 2사이클로 회귀
  - master parts_reviewed: [1,2,3,4] 모두 충족된 마지막 ExitPlanMode → master plan을 specs/NNN-{feature}/plan.md로 즉시 저장 (PreToolUse hook이 검증/차단)
  - 추가 리뷰 옵션:
    - /ultraplan (git repo 내, 가용 시) → 브라우저 팀 리뷰
    - 터미널 직접 승인 (소규모 작업)
  ↓
[구현 준비]
Phase 4: 브랜치 + 워크트리 생성
  - 브랜치: feature/{NNN-feature-name} (plan.md feature 필드와 일치)
  - 워크트리: superpowers:using-git-worktrees로 격리 환경 생성 (선택)
  - plan.md frontmatter branch 필드 업데이트
  ↓
[구현]
Phase 5: Edit Mode -- TDD 구현
  - superpowers:test-driven-development (Red -> Green -> Refactor)
  - superpowers:systematic-debugging (문제 발생 시)
  - superpowers:dispatching-parallel-agents (독립 태스크 병렬 시)
  - oracle-consultation (3-failure rule 또는 아키텍처 결정)
  → Phase 완료 시 superpowers:requesting-code-review
  ↓
[마무리]
Phase 6: 최종 품질 + 검증
  - /simplify — 전체 변경 코드 품질 리뷰 (중복, 재사용, 효율)
  - superpowers:verification-before-completion — plan.md Part 1 AC 기반 최종 검증
  - superpowers:finishing-a-development-branch — merge/PR/cleanup 결정
  → Commit
  ↓
Phase 6.5: Reflect
  - 잘된 것 → success-patterns.md 후보
  - 개선할 것 → failure-patterns.md 후보
  - 다음 작업에 가져갈 것 → active_context.md "다음 단계" 갱신
  → end-session skill의 Reflect 수집 단계와 1:1 매핑 (자동 기록 X, 사용자 명시 후 append)
```

### brainstorming과 Plan Mode의 관계

brainstorming은 대화를 통해 요구사항/제약/성공기준을 **탐색**한다.
Plan Mode 4-Part는 그 탐색 결과를 **구조화하여 기록**한다.
탐색 ≠ 기록이므로 겹치지 않는다.

### requesting-code-review vs /simplify

- `requesting-code-review`: Phase 완료 시마다 — plan 준수 여부, 로직 정합성 확인
- `/simplify`: 전체 구현 완료 후 1회 — 코드 품질 (중복 제거, 재사용성, 효율) 최종 정리

### verification-before-completion의 AC 검증 방식

plan.md Part 1의 Acceptance Criteria (Given/When/Then)를 순회하며 각 항목을 검증.
plan.md는 ExitPlanMode 직후 specs/ 디렉토리에 파일로 저장되므로,
검증 시점에 Read 도구로 plan.md Part 1을 읽어 AC 항목별 pass/fail 판정.
검증 증거: 테스트 결과, 빌드 출력, 런타임 확인 등 객관적 근거 첨부.

### Step Execution Order

리뷰 게이트(Phase 3) 승인 이후:

```
[태스크 실행 — plan.md Part 3 각 항목]
1. 태스크 목표 확인 (plan.md Part 3에서 읽기)
2. [TDD RED] 실패 테스트 작성 (TDD 적용 시)
3. 구현 (메인 Claude 직접 수행)
4. [TDD GREEN] 테스트 통과 확인
5. plan.md Part 3 [x] 표시 + 사용자에게 상태 보고

[Phase 리뷰 — Phase 내 모든 태스크 완료 후]
6. superpowers:requesting-code-review → 서브에이전트 코드 리뷰
7. 리뷰 피드백 반영 → 다음 Phase 진행
```

태스크 완료 시: plan.md Part 3 `[x]` 표시 + frontmatter 동기화.
문서 형식, 저장 경로, Frontmatter 상세: plan-lifecycle skill 참조.

---

## Plan Mode 4-Part 구조

Standard Plan Mode에서 작성하는 계획은 다음 구조를 따른다:

```
Part 1: Context & Requirements (brainstorming 결과 정형화)
  - 문제 정의 (Problem Statement)
  - 범위: In-Scope / Out-of-Scope
  - Acceptance Criteria (조건/동작 형식 권장: WHEN [조건] / THE SYSTEM SHALL [동작]; Given/When/Then 호환)
  - Acceptance Criteria — 실행 경로 (Part 1 부속, 옵션, 자율 작업 단위가 큰 Standard에서 권장):
    도구 호출 횟수 상한 / 동일 파일 편집 횟수 상한 / 금지 도구 / 필수 검증 step / 사용자 승인 게이트

Part 2: Technical Design (기술 설계)
  - 영향 파일/모듈 목록
  - 아키텍처 결정 + 근거
  - 검토한 대안

Part 3: Tasks (태스크)
  - [ ] Step-by-step 체크리스트
  - 병렬 가능 마커 (|| 표시)
  - Step별 예상 파일 변경

Part 4: Risks & Verification (위험/검증)
  - 기술적 위험 요소
  - 검증 기준 (어떻게 동작을 확인하는가)
```

**사이클별 진행 의무 (Standard, standard-plan-mode skill 참조)**:
- 리뷰 사이클 단위: [Part 1] / [Part 2] / [Part 3+4 통합] 총 3사이클
- 매 사이클: 임시 plan(`master_plan_path` 명시) 작성 → ExitPlanMode → plannotator-annotate 호출 → 피드백 수신 시 Pre-Edit Checklist 5문항 적용 → 사용자 승인 → 임시 plan 변경분을 master로 sync → master frontmatter `parts_reviewed`에 Part 번호 추가 → EnterPlanMode 재진입
- 사이클 3 통합 승인 시 `parts_reviewed`에 [3, 4] 동시 추가. 분리 회귀 트리거 발동 시는 [Part 3] / [Part 4] 두 사이클로 분리
- master `parts_reviewed: [1, 2, 3, 4]` 상태에서 마지막 ExitPlanMode 호출 → master plan을 specs로 저장
- PreToolUse hook(`~/.claude/hooks/exit-plan-mode-guard.sh`)이 매 ExitPlanMode 시점에 frontmatter 검증 (master_plan_path 분기로 사이클 운영 통과)
- Quick tier(1~2 파일, 한 문장 요건)는 plan.md frontmatter에 `tier: Quick` 명시로 hook 우회

**피드백 받았을 때의 본질 재정렬 원칙**:
- 코멘트 단위 patch만 붙이지 말 것. 피드백이 상위 가정을 깨면 영향 받는 Part 전체 재정렬
- standard-plan-mode skill의 Pre-Edit Checklist 5문항으로 매 라운드 자가 점검

---

## Plan 저장 규칙

ExitPlanMode 이후 **첫 번째 행동**은 plan을 파일로 저장:
```
{project_root}/specs/NNN-{feature}/plan.md
```
Plan Mode 컨텍스트는 대화 종료 시 소멸하므로 반드시 즉시 저장.
형식: plan-lifecycle skill의 frontmatter + Plan 원문 그대로.

---

## 브랜치/워크트리 규칙

```
브랜치 생성: Plan 승인(ExitPlanMode) 후, 구현 시작 전
  - 명명: feature/{NNN-feature-name}
  - plan.md frontmatter branch 필드 = 브랜치명
  - 워크트리: 격리 필요 시 superpowers:using-git-worktrees 사용 (선택)
  - Quick Plan Mode 사용 시에도 동일 명명 규칙
```

---

## 도구 역할 분담

**설계 단계:**

| 단계 | 도구 | 역할 |
|------|------|------|
| 요구사항 탐색 | superpowers:brainstorming | 인터랙티브 설계 탐색 |
| Standard 절차 강제 | standard-plan-mode | 사이클 단위 진행 (Part 1 / Part 2 / Part 3+4) + Pre-Edit Checklist + master frontmatter parts_reviewed 추적 |
| 구조화 | Plan Mode | brainstorming 결과 → 4-Part 계획 |
| 사이클 리뷰 | plannotator-annotate | 매 사이클 ExitPlanMode 후 인터랙티브 리뷰 (Standard 필수, 총 3회) |
| 통합 리뷰 (선택) | Ultraplan / 터미널 | 팀 리뷰 또는 직접 승인 |
| 절차 강제 | PreToolUse hook (exit-plan-mode-guard.sh) | 매 ExitPlanMode 시 frontmatter 검증 (master_plan_path 분기로 사이클 운영 통과) |

**구현 단계:**

| 단계 | 도구 | 역할 |
|------|------|------|
| 브랜치/워크트리 | superpowers:using-git-worktrees | 격리 환경 생성 (선택) |
| TDD 구현 | superpowers:test-driven-development | Red -> Green -> Refactor |
| 병렬 실행 | superpowers:dispatching-parallel-agents | 독립 태스크 동시 진행 |
| 디버깅 | superpowers:systematic-debugging | 문제 발생 시 |
| 코드 리뷰 | superpowers:requesting-code-review | Phase 완료 후 |
| 코드 품질 | /simplify | 전체 구현 완료 후 최종 정리 |
| 검증 | superpowers:verification-before-completion | 완료 선언 전 |
| 브랜치 마무리 | superpowers:finishing-a-development-branch | merge/PR/cleanup |
| 에스컬레이션 | oracle-consultation | 3-failure rule 또는 아키텍처 결정 |

---

## Session Flow

```
/start-session
    ↓
Tier decision
    ├─ Quick → [Plan Mode 선택] → TDD/debugging → verify → commit
    └─ Standard → brainstorming → Plan Mode 설계 → 리뷰 게이트 → Edit Mode 구현 → commit
    ↓
/end-session
```

**Debugging path:** superpowers:systematic-debugging → 3 failures → /oracle-consultation

---

## 도구 목록

| 도구 | 역할 |
|------|------|
| **Plan Mode** | brainstorming 결과를 4-Part 구조로 정리 (Standard 필수, Quick 선택) |
| **standard-plan-mode** | Standard tier 사이클 단위 진행(Part 1 / Part 2 / Part 3+4) + Pre-Edit Checklist 강제 (skill) |
| **plannotator-annotate** | 사이클 단위 인터랙티브 리뷰 (Standard 매 사이클 1회, 총 3회 / Quick 선택) |
| **Ultraplan** | Plan 리뷰를 브라우저로 확장 (git repo 내, 가용 시) |
| **superpowers** | brainstorming, TDD, debugging, verification, code review, worktree, branch |
| **/simplify** | 전체 구현 완료 후 코드 품질 최종 리뷰 |
| **context7** | 라이브러리/프레임워크 문서 조회 |
| **hookify** | 행동 방지 훅 생성/관리 |
| **exit-plan-mode-guard hook** | ExitPlanMode 시 plan.md frontmatter parts_reviewed 검증 (~/.claude/hooks/) |

## 산출물 경로

프로젝트 내 `specs/` 디렉토리에 저장 (git 관리):
```
{project_root}/specs/NNN-{feature}/
```
Superpowers 기본 경로 (`docs/superpowers/specs/`, `docs/superpowers/plans/`)는 이 규칙으로 오버라이드.

## 원칙

- rules/는 특정 도구를 직접 참조하지 않음 (이 파일 제외)
- 도구 비활성화 시 기본 모드로 폴백
- 유저 레벨 규칙은 프로젝트 레벨 도구에 의존하지 않음
