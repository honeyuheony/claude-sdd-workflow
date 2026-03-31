# 도구 통합 & 워크플로우

## 모드

**모든 작업은 Edit Mode에서 수행.** Plan Mode 미사용.
"계획 수립" = plan.md 작성 (Edit Mode), Plan Mode 진입이 아님.

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

---

## Quick 프로세스

```
Explore (Haiku, 1 agent)
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
Phase 3: 산출물 생성 (아래 도구 역할 분담 참조)
  - SpecKit 있으면: brainstorming 결과 → /speckit.specify → clarify → plan → tasks
  - SpecKit 없으면: brainstorming에서 AC 포함 spec 작성 → superpowers:writing-plans
  → 모든 산출물은 Obsidian Specs 폴더에 저장
  ↓
Phase 3.5: 검증
  - SpecKit 있으면: /speckit.analyze
  - 없으면: 생략
  ↓
[리뷰 게이트]
/plannotator-annotate {plan.md 경로}
  → 사용자가 시각적으로 계획 승인/수정
  ↓
[구현]
태스크 직접 구현 (TDD) → Phase 완료 시 superpowers:requesting-code-review
  ↓
verification-before-completion → Commit
```

### Step Execution Order

리뷰 게이트 승인 이후:

```
[태스크 실행 — tasks.md 각 항목]
1. 태스크 목표 확인 (tasks.md에서 읽기)
2. [TDD RED] 실패 테스트 작성 (TDD 적용 시)
3. 구현 (메인 Claude 직접 수행)
4. [TDD GREEN] 테스트 통과 확인
5. tasks.md [x] 표시 + 사용자에게 상태 보고

[Phase 리뷰 — Phase 내 모든 태스크 완료 후]
6. superpowers:requesting-code-review → 서브에이전트 코드 리뷰
7. 리뷰 피드백 반영 → 다음 Phase 진행
```

태스크 완료 시: tasks.md `[x]` 표시 + plan.md frontmatter 동기화.
문서 형식, 저장 경로, Frontmatter 상세: plan-lifecycle skill 참조.

---

## 도구 역할 분담

brainstorming → SpecKit → Superpowers 순으로 각 단계의 최적 도구를 사용한다.

| 단계 | 도구 | 역할 |
|------|------|------|
| 요구사항 탐색 | superpowers:brainstorming | 인터랙티브 설계 탐색 |
| 요구사항 구조화 | /speckit.specify + /speckit.clarify | brainstorming 결과를 구조화된 spec으로 |
| 설계 | /speckit.plan | 다중 산출물 (plan.md, research.md 등) |
| 태스크 분해 | /speckit.tasks | 병렬 마커 + 스토리 추적 |
| 정적 검증 | /speckit.analyze | 크로스-아티팩트 일관성 검증 |
| 실행 | /speckit.implement | TDD 원칙(01-principles) 적용 |
| 코드 리뷰 | superpowers:requesting-code-review | Phase 완료 후 서브에이전트 리뷰 |
| 디버깅 | superpowers:systematic-debugging | 문제 발생 시 |

### SpecKit 미설치 시 폴백

`.claude/commands/speckit.specify.md` 미존재 시:

| 단계 | 폴백 |
|------|------|
| 요구사항 | brainstorming에서 AC 포함 작성 |
| 설계 + 태스크 | superpowers:writing-plans |
| 정적 검증 | 생략 (런타임 검증으로 대체) |
| 실행 | superpowers:executing-plans |

---

## Session Flow

```
/start-session
    ↓
Tier decision
    ├─ Quick → TDD/debugging skill check → implement → verify → commit
    └─ Standard → 설계 → 리뷰 → 구현 → commit
    ↓
/end-session
```

**Debugging path:** superpowers:systematic-debugging → 3 failures → /oracle-consultation

---

## 도구 목록

| 도구 | 역할 |
|------|------|
| **superpowers** | brainstorming, TDD, debugging, verification, code review |
| **SpecKit** | 구조화된 산출물 생성 (프로젝트별) |
| **plannotator** | 시각적 문서 리뷰 |
| **context7** | 라이브러리/프레임워크 문서 조회 |
| **hookify** | 행동 방지 훅 생성/관리 |

## 산출물 경로

프로젝트 내 `specs/` 디렉토리에 저장 (git 관리):
```
{project_root}/specs/NNN-{feature}/
```
SpecKit 기본 경로와 동일. Superpowers 기본 경로 (`docs/superpowers/specs/`, `docs/superpowers/plans/`)는 이 규칙으로 오버라이드.

## 원칙

- rules/는 특정 도구를 직접 참조하지 않음 (이 파일 제외)
- 도구 비활성화 시 기본 모드로 폴백
- 유저 레벨 규칙은 프로젝트 레벨 도구에 의존하지 않음
