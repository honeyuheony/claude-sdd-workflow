# 도구 통합 & 워크플로우

## 모드

**기본은 Edit Mode. 설계가 필요하면 Plan Mode.**

- Plan Mode: 설계 탐색 및 계획 구조화 (Standard 필수, Quick 선택)
- Edit Mode: 구현, 디버깅, 검증, 코드 리뷰

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
  - brainstorming 결과를 4-Part 구조로 정리 (아래 참조)
  - git repo 내: /ultraplan 사용 가능 → 브라우저 팀 리뷰
  - git repo 외: 터미널에서 직접 승인
  → ExitPlanMode → specs/NNN-{feature}/plan.md로 즉시 저장
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
  - Acceptance Criteria (Given/When/Then)

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
| 구조화 | Plan Mode | brainstorming 결과 → 4-Part 계획 |
| 리뷰 | Ultraplan / 터미널 | 팀 리뷰 또는 직접 승인 |

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
| **Ultraplan** | Plan 리뷰를 브라우저로 확장 (git repo 내, 가용 시) |
| **superpowers** | brainstorming, TDD, debugging, verification, code review, worktree, branch |
| **/simplify** | 전체 구현 완료 후 코드 품질 최종 리뷰 |
| **context7** | 라이브러리/프레임워크 문서 조회 |
| **hookify** | 행동 방지 훅 생성/관리 |

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
