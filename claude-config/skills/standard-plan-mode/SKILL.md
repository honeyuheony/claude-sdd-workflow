---
name: standard-plan-mode
description: Standard tier Plan Mode 진행 절차 — 4-Part plan.md를 [Part 1] / [Part 2] / [Part 3+4 통합] 3회 사이클로 작성. 각 사이클은 ExitPlanMode → plannotator-annotate 리뷰 → 사용자 승인 → master frontmatter `parts_reviewed` 업데이트 → EnterPlanMode 재진입. plannotator-annotate는 시스템 Plan Mode 안에서 호출이 차단되므로 매 사이클 ExitPlanMode가 필수. brainstorming 종료 직후 / Plan Mode 진입 시 / plannotator 피드백 수신 시 호출.
user-invocable: false
---

# Standard Plan Mode

Standard tier(rules/04-integration.md)에서 4-Part Plan을 작성·검토할 때 따르는 절차. 본 skill의 핵심은 **Part 단위 명시 진행**과 **본질 재정렬 강제**다. 두 가지가 같이 작동해야 ExitPlanMode 차단 hook을 통과한다.

## 0. 사전 조건

- brainstorming skill로 요구사항/제약/접근법이 합의되어 있어야 함
- Tier가 Standard로 판별됨 (Quick은 본 skill 적용 대상 아님 — 우회 키워드로 통과)
- Plan Mode 진입 직후 또는 plannotator 피드백 수신 직후

## 1. plan.md 초기화 (Part 1 작성 직전)

본 skill 운영의 핵심은 **시스템 Plan Mode 안에서는 plannotator-annotate 호출이 차단**된다는 제약이다. 따라서 매 사이클(Part 1 / Part 2 / Part 3+4)마다 ExitPlanMode → plannotator → EnterPlanMode 사이클을 돈다. ExitPlanMode 시점마다 `~/.claude/hooks/exit-plan-mode-guard.sh`가 frontmatter를 검증하므로 두 종류의 plan 파일을 사용:

| 파일 | 역할 | 위치 |
|---|---|---|
| **master plan** | 4-Part 본질·진행 추적 (parts_reviewed 누적) | `~/.claude/plans/<random>.md` (저장 후 `target_save_path`로 이동) |
| **임시 plan** | 매 사이클 ExitPlanMode 시 hook 통과용 메타 파일 (해당 사이클 본문 기록) | `~/.claude/plans/<random>-cycle-N.md` |

master plan **frontmatter 필수 필드**:

```yaml
---
type: master-plan
tier: Standard
status: 사이클 1 작성 중
created: <YYYY-MM-DD>
scope: <간결 1줄>
related_branch: <branch or develop>
parts_reviewed: []  # ← 빈 배열로 초기화. 사이클 승인마다 Part 번호 누적 추가
target_save_path: <project>/specs/NNN-<feature>/plan.md
---
```

임시 plan(사이클별) **frontmatter**:

```yaml
---
type: meta-progress
tier: Standard            # ← 본질 그대로 (Quick 거짓 표기 금지)
parts_reviewed: []        # ← 임시 plan은 항상 []
master_plan_path: <master 절대 경로>
cycle: <N>                # 1, 2, 3
---
```

hook 통과 조건은 두 가지:
- master `parts_reviewed`에 [1, 2, 3, 4] 모두 누적된 최종 ExitPlanMode (Quick tier 또는 모든 사이클 완료)
- 임시 plan에 `master_plan_path` 명시 + 그 master plan의 `parts_reviewed` 길이 ≥ 1 (사이클 운영 중)

**첫 사이클(Part 1) 처리**: master plan에 아직 parts_reviewed가 비어 있어 master_plan_path 분기로도 통과 불가 → §3.1의 "첫 사이클 부트스트랩" 절차 따름.

## 2. Part 작성 → 리뷰 → 승인 사이클

리뷰 단위는 **[Part 1] / [Part 2] / [Part 3+4 통합]** 총 3 사이클. Part 3 작성 직후에는 plannotator를 호출하지 않고, Part 4까지 작성한 뒤 두 Part를 함께 사용자에게 보여준다. 콘텐츠 작성 단위(4-Part)는 그대로 유지된다. **단축 금지**.

각 사이클에 대해 2.1 → 2.6을 순서대로 수행한다. 사이클 N의 정의:

| 사이클 N | 작성 Part | 리뷰 단위 |
|---|---|---|
| 1 | Part 1 | Part 1 단독 |
| 2 | Part 2 | Part 2 단독 |
| 3 | Part 3 작성 → Part 4 작성 (plannotator는 둘 다 작성 후 1회) | Part 3+4 통합 |

> **분리 회귀 트리거**: 다음 조건 중 하나라도 충족되면 사이클 3을 [Part 3 단독] / [Part 4 단독] 2 사이클로 되돌린다.
> - Part 3 태스크 ≥ 15
> - Part 4 위험 항목 ≥ 8
> - Part 4 위험에 글로벌 시스템·보안·외부 API 의존 항목 포함
> 트리거 판정은 Part 3 작성 직후 본인이 수행하고, 트리거 충족 시 응답에 명시 후 사이클을 재구성한다.

### 2.1 Part 작성

해당 Part 본문을 plan 파일에 작성. 다른 Part는 아직 비워둠. 사이클 3에서는 Part 3 작성 → 트리거 판정 → (트리거 미충족 시) 같은 사이클 안에서 Part 4도 작성.

| Part | 내용 |
|---|---|
| 1 | Context, 사용 컨텍스트, 본질적 문제 정의(PR과 매핑), In-Scope, Out-of-Scope, Acceptance Criteria |
| 2 | Technical Design — 영향 파일/모듈, 아키텍처 결정 + 근거, 검토한 대안 |
| 3 | Tasks — Phase별 step-by-step 체크리스트, 병렬 가능 마커, 예상 파일 변경 |
| 4 | Risks & Verification — 위험 요소, 완화 전략, 검증 절차, 진행 게이트 |

### 2.2 plannotator-annotate 호출 (필수)

**전제**: plannotator-annotate는 시스템 Plan Mode 안에서 호출이 차단된다. 따라서 호출 직전에 ExitPlanMode가 선행돼야 한다 (§3 사이클 단계 5번).

```
Skill: plannotator-annotate
args: <임시 plan 파일 절대 경로>
```

호출 시점:
- 사이클 1 (Part 1 작성 직후 ExitPlanMode 통과 후): 1회
- 사이클 2 (Part 2 작성 직후 ExitPlanMode 통과 후): 1회
- 사이클 3 (Part 3+4 모두 작성 직후 ExitPlanMode 통과 후): 1회 — Part 3과 Part 4를 함께 검토

총 3회 호출. Part 3 작성 직후에는 호출하지 않는다. 사이클별 변경분은 임시 plan 파일을 사이클별로 분리(`<random>-cycle-N.md`)하여 사용자가 추가된 Part만 보는 cadence로 해결.

호출 후 `TaskOutput(task_id, block=true, timeout=600000)`으로 결과 대기. 사용자가 Send Annotations를 누르거나 빈 출력으로 닫을 때까지 대기.

### 2.3 Pre-Edit Checklist (피드백 수신 시 plan.md 수정 전 필수 자가 질의)

피드백을 받은 후 plan.md를 수정하기 **전에** 답하라. 답을 응답에 명시 작성하지 않은 채 Edit을 시도하면 절차 위반:

```
1. 이 피드백이 지적하는 부분은 plan의 어느 Part / 어느 가정인가?
2. 같은 근거가 다른 Part에도 영향을 미치는가?
   (예: Part 1 가정 변경이 Part 3 태스크를 무효화하는가? PR 단위가 바뀌는가?)
3. 피드백을 그대로 반영하면 plan의 어느 가정이 깨지는가?
4. 깨지는 가정이 있다면 → **재정렬 필요**.
   - 재정렬 = 영향 받는 Part 전체 재작성, 사용자에게 재정렬 의도 명시 후 진행
   - 코멘트 단위 patch 금지
5. 깨지는 가정이 없다면 → 국소 patch 가능.
```

5번이 "예"인데 사실은 4번이 "예"인 케이스가 가장 흔한 함정이다. 각 코멘트마다 5문항을 다시 본다. 이전 라운드 답을 재사용하지 않는다.

### 2.4 plan.md 수정 (재정렬 또는 patch)

Pre-Edit Checklist 결과대로 수정.

- 재정렬: 영향 Part 본문 재작성. frontmatter `status`에 "Part N 재정렬 중" 명시
- patch: 국소 Edit. 재정렬 신호 없음을 본인이 한 번 더 검토

수정 후 다시 plannotator-annotate(2.2)로 돌아간다. 라운드 제한 없음 — 사용자가 빈 출력(Resolved만)으로 닫거나 명시 승인할 때까지 반복.

### 2.5 사용자 승인 받기

plannotator 출력이 빈 출력(annotation 없음)으로 닫히거나, 사용자가 명시적 승인 키워드를 사용해야 다음 단계 진입:

- "Part N 승인" / "Part N OK" / "Part N 통과" / "다음 파트" 류
- 빈 plannotator 출력은 "묵시적 승인"으로 해석 가능하지만 frontmatter 업데이트 전 사용자에게 한 번 더 확인 권장

### 2.6 frontmatter 업데이트 (필수, hook 통과 조건)

사이클 승인 직후, **다음 사이클 진입 전에** plan.md frontmatter `parts_reviewed`에 해당 Part 번호 추가:

```yaml
parts_reviewed: [1]              # 사이클 1 (Part 1) 승인 후
parts_reviewed: [1, 2]           # 사이클 2 (Part 2) 승인 후
parts_reviewed: [1, 2, 3, 4]     # 사이클 3 (Part 3+4 통합) 승인 후 — ExitPlanMode 가능
```

사이클 3 승인 시 [3, 4]가 한 번에 추가된다. 분리 회귀 트리거가 발동돼 사이클 3을 [Part 3 단독] / [Part 4 단독]으로 나눈 경우는 [1,2,3] → [1,2,3,4] 두 단계로 누적.

`status` 필드도 함께 갱신:

```yaml
status: 사이클 N 승인 (사이클 N+1 작성 중)
```

## 3. 사이클 운영 절차 (단일 방식)

매 사이클(1, 2, 3)은 다음 단계를 순서대로 수행. plannotator-annotate가 시스템 Plan Mode 안에서 호출 차단되므로 ExitPlanMode → plannotator → EnterPlanMode 사이클이 필수.

### 3.1 일반 사이클 (사이클 2, 3)

```
1. EnterPlanMode (또는 시스템이 자동 진입 상태)
2. master plan에서 임시 plan(`~/.claude/plans/<random>-cycle-N.md`)으로 사이클 베이스 생성
   - 사이클 N 임시 plan frontmatter:
       type: meta-progress
       tier: Standard
       parts_reviewed: []
       master_plan_path: <master 절대 경로>
       cycle: <N>
3. 해당 사이클의 Part 본문을 임시 plan에 작성 (사이클 3은 Part 3+4 둘 다)
4. (사이클 3 한정) 분리 회귀 트리거 판정 (§2 참조). 트리거 발동 시 사이클 3을 [3] / [4] 두 사이클로 재구성
5. ExitPlanMode 호출
   → exit-plan-mode-guard hook이 master_plan_path를 따라 master parts_reviewed 길이 ≥ 1 검증 후 통과
6. plannotator-annotate <임시 plan 절대 경로> 호출
7. 사용자가 plannotator UI에서 approve / 빈 출력으로 닫음 (피드백 시 §2.3 Pre-Edit Checklist → §2.4 수정 → 6번 재호출 반복)
8. 임시 plan에 작성된 사이클 본문을 master plan으로 sync (해당 Part 본문 추가/덮어쓰기)
9. master frontmatter `parts_reviewed`에 해당 Part 번호 추가 (사이클 3 통합 승인 시 [3, 4] 동시 추가)
10. EnterPlanMode 재진입 → 다음 사이클로 진행
```

### 3.2 첫 사이클 부트스트랩 (사이클 1, Part 1)

`exit-plan-mode-guard.sh`는 임시 plan frontmatter에 `cycle: 1`이 명시되고 master_plan_path 분기에 진입한 경우, master parts_reviewed가 비어 있어도 통과시킨다 (첫 사이클 예외 — master 누적 시작 직전 상태).

```
1. master plan 생성 — frontmatter:
     type: master-plan
     tier: Standard
     parts_reviewed: []
     ...
   본문은 Part 1만 placeholder 또는 빈 상태
2. 임시 plan(`~/.claude/plans/<random>-cycle-1.md`) 생성 — frontmatter:
     type: meta-progress
     tier: Standard
     parts_reviewed: []
     master_plan_path: <master 절대 경로>
     cycle: 1
3. Part 1 본문을 임시 plan에 작성
4. 이후 §3.1의 5번(ExitPlanMode) → 10번(EnterPlanMode 재진입) 동일 순서로 진행
5. 사이클 1 종료 시 master로 sync + master `parts_reviewed: [1]` 추가
6. 사이클 2부터는 일반 사이클 (§3.1) — `cycle: 2`/`cycle: 3` 명시
```

> **주의**: `cycle: 1` 예외는 사이클 1에 한정. 사이클 2 이상에서 `cycle: 1`로 거짓 표기하면 본질 거짓 표기 안티패턴(§4 주의)에 해당.

### 3.3 마지막 ExitPlanMode (사이클 3 완료 후)

- master `parts_reviewed: [1, 2, 3, 4]` 충족 상태
- master plan에 대한 ExitPlanMode 호출 → hook 통과 (master 자체 검증 분기)
- ExitPlanMode 직후 첫 액션: master plan을 `target_save_path`로 이동
- 임시 plan(cycle-1.md, cycle-2.md, cycle-3.md)은 사이클 종료 후 정리 가능

## 4. Quick tier 우회 (Standard 절차 부적합 시)

본 skill은 Standard tier 작업에만 적용. Quick tier(1~2파일 변경, 한 문장 요건)는 다음 키워드로 우회:

- "Quick tier 진행" / "Quick 진행" / "Quick으로 진행"
- "tier=Quick"
- "skip plannotator"

이 키워드가 transcript에 있으면 ExitPlanMode hook이 통과시킨다.

> **주의**: Standard 작업을 진행하면서 ExitPlanMode hook 통과만을 위해 임시 plan을 `tier: Quick`으로 표기하는 것은 **금지** — 본질을 거짓 표기. 매 사이클 ExitPlanMode 운영을 위해서는 `master_plan_path` 패턴(§3.1)을 사용한다.

## 5. 자가 점검 체크리스트

### 5.1 매 사이클 ExitPlanMode 직전

- [ ] 임시 plan에 `master_plan_path` + `cycle: N` + `tier: Standard`가 정직하게 표기됐는가?
- [ ] 해당 사이클 본문(Part N 또는 Part 3+4)이 임시 plan에 작성 완료됐는가?
- [ ] 사이클 3이라면, 분리 회귀 트리거(태스크 ≥15 / 위험 ≥8 / 글로벌·보안·외부 API 의존)를 판정했는가?

### 5.2 사이클 종료 직전 (plannotator 승인 후)

- [ ] 임시 plan 변경분을 master로 sync했는가?
- [ ] master `parts_reviewed`에 해당 Part 번호를 추가했는가? (사이클 3 통합 승인 시 [3, 4] 동시)
- [ ] Pre-Edit Checklist를 매 피드백마다 적용했는가? (응답에 5문항 답변 텍스트 존재)

### 5.3 마지막 ExitPlanMode 직전 (사이클 3 완료 후)

- [ ] master `parts_reviewed: [1, 2, 3, 4]`인가?
- [ ] 사이클 1·2·3 모두에서 사용자 명시/묵시 승인을 받았는가?
- [ ] master plan이 `target_save_path`로 이동될 준비가 됐는가?

위 항목 모두 yes일 때만 다음 단계로 진입.

## 6. 안티패턴 — 절차 위반 신호

다음 행동을 하려는 충동이 들면 본인이 단축을 시도하는 중이다. 즉시 본 skill로 돌아온다.

- "Part 1, 2 같이 쓰면 빠를 텐데" → 사이클 1·2는 분리 작성 + 분리 리뷰 (통합 금지)
- "Part 3까지 plannotator 호출하자" → 사이클 3은 Part 4까지 작성 후 통합 호출. Part 3 단독 호출은 분리 회귀 트리거가 발동된 경우에만
- "사이클 3 분리 트리거 판정 안 하고 그냥 통합" → Part 3 작성 직후 태스크 수·위험 수·도메인 점검을 응답에 명시
- "plannotator를 Plan Mode 안에서 호출하면 되겠지" → 시스템이 차단함. 매 사이클 ExitPlanMode 선행 필수
- "임시 plan에 tier: Quick으로 표기하면 hook 통과" → 본질 거짓 표기 금지. master_plan_path 패턴(§3.1) 사용
- "이 피드백은 작아서 patch만 하자" → Pre-Edit Checklist 5문항 다시 적용
- "사용자 승인은 묵시적으로 가능" → master frontmatter 업데이트 전 명시 확인
- "사이클 3 끝나기 전에 master로 sync 안 하고 다음 사이클로" → 매 사이클 종료 시 임시 → master sync + parts_reviewed 추가가 같은 단계
