# Claude Development Workflow

Claude Code 기반 **Plan Mode 중심 개발 워크플로우** 설정 패키지.

요구사항을 brainstorming으로 탐색하고, Plan Mode에서 4-Part 계획(Context, Design, Tasks, Risks)으로 구조화한 뒤, TDD로 구현하는 전체 흐름을 Claude Code가 따르도록 구성합니다.

---

## 목차

1. [이 워크플로우가 해결하는 문제](#1-이-워크플로우가-해결하는-문제)
2. [아키텍처](#2-아키텍처)
3. [설치 가이드](#3-설치-가이드)
4. [워크플로우 가이드](#4-워크플로우-가이드)
5. [Plan Mode 4-Part 구조 & 사이클 운영](#5-plan-mode-4-part-구조--사이클-운영)
6. [세션 관리](#6-세션-관리)
7. [프로젝트별 산출물 경로](#7-프로젝트별-산출물-경로)
8. [예시](#8-예시)
9. [선택 사항](#9-선택-사항)
10. [FAQ](#10-faq)

---

## 1. 이 워크플로우가 해결하는 문제

### 문제

구두 지시나 즉석 설명으로 개발을 진행하면:
- 맥락 누락 → 의도와 다른 구현
- 요건 변경 추적 불가 → 재작업
- 완료 기준 불명확 → "됐나?" 반복
- Plan을 작성해도 검토 없이 흘러가 가정이 깨진 채로 구현 진입

### 해결

**요구사항을 대화로 탐색하고, 구조화된 계획을 사이클 단위로 검토·승인한 뒤 구현한다.**

```
요구사항 대화 (brainstorming)
  ↓
Plan Mode → plan.md (4-Part: Context, Design, Tasks, Risks)
  ↓ 사이클 1 [Part 1]   → ExitPlanMode → plannotator 리뷰 → 승인
  ↓ 사이클 2 [Part 2]   → ExitPlanMode → plannotator 리뷰 → 승인
  ↓ 사이클 3 [Part 3+4] → ExitPlanMode → plannotator 리뷰 → 승인
  ↓
TDD 구현 (Red → Green → Refactor)
  ↓
검증 (plan.md Part 1 Acceptance Criteria 기반) + Reflect
```

Claude Code가 이 흐름을 자동으로 따르도록 rules/skills/hooks/plugins로 구성한 것이 이 워크플로우입니다.

---

## 2. 아키텍처

### `~/.claude/` 디렉토리 구조

```
~/.claude/
├── CLAUDE.md          ← 메인 지침 (항상 로딩)
├── settings.json      ← 플러그인, hooks, 언어 설정
├── rules/             ← 원칙과 제약 (항상 로딩)
│   ├── 01-principles.md   ← TDD, Verification, Debugging, Tidy First
│   ├── 02-architecture.md ← 모듈/클래스 설계, 의존성, LLM 안티패턴
│   ├── 03-coding.md       ← Python 코딩 컨벤션
│   └── 04-integration.md  ← Tier 판별, 도구 역할 분담, 산출물 경로
├── skills/            ← 워크플로우 (필요 시 로딩)
│   ├── plan-lifecycle/    ← plan.md 4-Part 형식, frontmatter, 실패/성공 기록
│   ├── standard-plan-mode/← Standard tier 사이클 운영 절차 강제
│   ├── steering-load/     ← 프로젝트별 영구 정보(_steering/) 로드
│   ├── dev-experiment/    ← 30분 time-box 가설 검증
│   ├── oracle-consultation/ ← 복잡한 문제, 디버깅 3회 실패 시 escalation
│   └── agent-handbook/    ← SubAgent 위임 시 프롬프트 템플릿
├── commands/          ← /명령어로 직접 호출
│   ├── start-session.md   ← 진행 중 작업 탐지, active_context.md 복원
│   └── end-session.md     ← 작업 정리, 학습 추출, Reflect
├── hooks/             ← PreToolUse 훅 (자동 절차 검증)
│   └── exit-plan-mode-guard.sh ← ExitPlanMode 시 사이클 진행 상태 검증
├── scripts/           ← 유틸리티 스크립트 (선택)
│   └── context-bar.sh     ← 컨텍스트 사용량 상태 바
├── memory/            ← 대화 간 학습 내용 (자동 관리)
│   └── active_context.md  ← 진행 중 작업 단일 스냅샷
└── plugins/           ← 외부 실행 엔진 (별도 설치)
```

### 로딩 규칙

| 요소 | 로딩 시점 | 역할 |
|------|----------|------|
| **CLAUDE.md** | 항상 | 절대 규칙 6개, 아키텍처 안내, 충돌 해결 |
| **rules/** | 항상 | TDD 원칙, 모듈 설계, Python 컨벤션, 워크플로우 흐름 |
| **skills/** | Claude가 필요 시 | plan 문서 관리, 사이클 절차 강제, 디버깅 escalation, SubAgent 위임 |
| **commands/** | `/명령어` 입력 시 | `/start-session`, `/end-session` |
| **hooks/** | 도구 호출 시 자동 | ExitPlanMode 호출 직전 절차 검증 + 차단 |
| **plugins** | 설정에 따라 | superpowers, plannotator, context7, hookify |
| **memory/** | 항상 (인덱스) | 프로젝트 컨텍스트, 피드백 기록, 진행 중 작업 스냅샷 |

### 플러그인

| 플러그인 | 역할 |
|---------|------|
| **superpowers** | brainstorming, TDD, debugging, verification, code review, worktree 관리 |
| **plannotator** | plan.md를 웹 UI로 띄워 시각적 리뷰/어노테이션 (사이클 단위 호출) |
| **context7** | 라이브러리/프레임워크 공식 문서 조회 |
| **hookify** | 행동 방지 훅 생성/관리 (실수 반복 방지) |

### 사이클 운영의 핵심

Standard tier에서 4-Part Plan은 **3 사이클**로 검토·승인됩니다:

| 사이클 | 작성/리뷰 단위 | plannotator 호출 |
|---|---|---|
| 1 | Part 1 (Context & Requirements) | 1회 |
| 2 | Part 2 (Technical Design) | 1회 |
| 3 | Part 3+4 (Tasks + Risks 통합) | 1회 |

`plannotator-annotate`는 시스템 Plan Mode 안에서 호출이 차단되므로, 매 사이클 **ExitPlanMode → plannotator → EnterPlanMode** 순환을 거칩니다. `exit-plan-mode-guard` hook이 매 사이클의 진행 상태(`master_plan_path` + `parts_reviewed`)를 검증해 절차 위반을 자동 차단합니다.

> 사이클 3 진입 직후 **분리 회귀 트리거**(태스크 ≥15 / 위험 ≥8 / 글로벌·보안·외부 API 의존)를 판정해 [Part 3] / [Part 4] 두 사이클로 회귀할 수 있습니다.

---

## 3. 설치 가이드

### 사전 요구사항

- Claude Code CLI 설치 완료 ([공식 문서](https://docs.anthropic.com/en/docs/claude-code/overview))
- `jq` 설치 (`exit-plan-mode-guard.sh` 및 `context-bar.sh`에 필요: `brew install jq`)

### Step 1: 레포 클론

```bash
git clone https://github.com/honeyuheony/claude-sdd-workflow.git
cd claude-sdd-workflow
```

### Step 2: 기존 설정 백업

```bash
# ~/.claude/가 이미 있으면 백업 (없으면 이 단계 건너뛰기)
if [ -d ~/.claude ]; then
  backup_dir=~/.claude/backups/$(date +%Y%m%d_%H%M%S)
  mkdir -p "$backup_dir"
  cp ~/.claude/CLAUDE.md "$backup_dir/" 2>/dev/null
  cp -r ~/.claude/rules "$backup_dir/" 2>/dev/null
  cp -r ~/.claude/skills "$backup_dir/" 2>/dev/null
  cp -r ~/.claude/commands "$backup_dir/" 2>/dev/null
  cp -r ~/.claude/hooks "$backup_dir/" 2>/dev/null
  cp ~/.claude/settings.json "$backup_dir/" 2>/dev/null
  echo "백업 완료: $backup_dir"
fi
```

### Step 3: 설정 파일 복사

```bash
# 디렉토리 생성
mkdir -p ~/.claude/rules ~/.claude/skills ~/.claude/commands \
         ~/.claude/scripts ~/.claude/hooks

# CLAUDE.md (메인 지침)
cp claude-config/CLAUDE.md ~/.claude/CLAUDE.md

# rules/ (원칙과 제약 — 4개 파일)
cp claude-config/rules/01-principles.md ~/.claude/rules/
cp claude-config/rules/02-architecture.md ~/.claude/rules/
cp claude-config/rules/03-coding.md ~/.claude/rules/
cp claude-config/rules/04-integration.md ~/.claude/rules/

# skills/ (워크플로우 — 6개 디렉토리)
cp -r claude-config/skills/plan-lifecycle ~/.claude/skills/
cp -r claude-config/skills/standard-plan-mode ~/.claude/skills/
cp -r claude-config/skills/steering-load ~/.claude/skills/
cp -r claude-config/skills/dev-experiment ~/.claude/skills/
cp -r claude-config/skills/oracle-consultation ~/.claude/skills/
cp -r claude-config/skills/agent-handbook ~/.claude/skills/

# commands/ (세션 관리 — 2개 파일)
cp claude-config/commands/start-session.md ~/.claude/commands/
cp claude-config/commands/end-session.md ~/.claude/commands/

# hooks/ (PreToolUse 훅 — 1개 파일, 실행 권한 필요)
cp claude-config/hooks/exit-plan-mode-guard.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/exit-plan-mode-guard.sh

# scripts/ (유틸리티 — 선택사항)
cp claude-config/scripts/context-bar.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/context-bar.sh
```

**복사 결과 확인:**
```bash
echo "=== 복사된 파일 확인 ==="
ls -la ~/.claude/CLAUDE.md
ls ~/.claude/rules/
ls ~/.claude/skills/
ls ~/.claude/commands/
ls ~/.claude/hooks/
ls ~/.claude/scripts/
```

예상 출력:
```
=== 복사된 파일 확인 ===
~/.claude/CLAUDE.md
01-principles.md  02-architecture.md  03-coding.md  04-integration.md
agent-handbook  dev-experiment  oracle-consultation  plan-lifecycle  standard-plan-mode  steering-load
start-session.md  end-session.md
exit-plan-mode-guard.sh
context-bar.sh
```

### Step 4: settings.json 설정

**기존 settings.json이 없는 경우** (신규 설치):

```bash
cp claude-config/settings.json ~/.claude/settings.json
```

이 파일의 내용:
```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "plannotator@plannotator": true,
    "context7@claude-plugins-official": true,
    "hookify@claude-plugins-official": true
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/exit-plan-mode-guard.sh",
            "timeout": 10
          }
        ]
      }
    ]
  },
  "language": "korean",
  "effortLevel": "high"
}
```

**기존 settings.json이 있는 경우** (수동 병합):

기존 `permissions` 등은 유지하면서 `enabledPlugins` + `hooks` + `language` + `effortLevel`을 병합하세요. 특히 `hooks.PreToolUse` 항목이 누락되면 ExitPlanMode 절차 검증이 동작하지 않습니다.

> `permissions`는 개인별로 다르므로 포함하지 않았습니다. Claude Code 사용 중 권한 요청이 오면 그때 허용하세요.

**context-bar.sh 활성화** (선택사항):

settings.json에 아래를 추가하면 Claude Code 하단에 컨텍스트 사용량 바가 표시됩니다:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/context-bar.sh"
  }
}
```

### Step 5: 플러그인 설치

```bash
# 1. Superpowers (핵심 워크플로우 엔진)
claude plugins install superpowers@claude-plugins-official

# 2. Context7 (라이브러리 문서 조회)
claude plugins install context7@claude-plugins-official

# 3. Hookify (행동 방지 훅)
claude plugins install hookify@claude-plugins-official

# 4. Plannotator (시각적 plan 리뷰)
#    CLI 바이너리를 먼저 설치한 뒤 플러그인 추가
curl -fsSL https://plannotator.ai/install.sh | bash
claude plugins marketplace add backnotprop/plannotator
claude plugins install plannotator@plannotator
```

### Step 6: 설치 확인

```bash
# 플러그인 목록 확인 — 4개 모두 표시되어야 함
claude plugins list

# hook 동작 확인 — 실행 권한 + syntax OK
ls -l ~/.claude/hooks/exit-plan-mode-guard.sh
bash -n ~/.claude/hooks/exit-plan-mode-guard.sh && echo "hook syntax OK"
```

**Claude Code를 재시작**하면 설치가 완료됩니다.

### 설치 요약

| 단계 | 명령어 | 결과 |
|------|--------|------|
| 1 | `git clone` | 레포 클론 |
| 2 | `cp` (백업) | 기존 설정 보존 |
| 3 | `cp` (파일 복사) | CLAUDE.md, rules/4, skills/6, commands/2, hooks/1, scripts/1 |
| 4 | `cp` 또는 수동 병합 | settings.json (plugins + hooks + language + effortLevel) |
| 5 | `claude plugins install` x4 | superpowers, context7, hookify, plannotator |
| 6 | `claude plugins list` + hook 검증 | 4개 enabled + hook 권한/syntax 확인 |

---

## 4. 워크플로우 가이드

### Tier 판별: Quick vs Standard

**Quick** — 아래 조건을 **모두** 충족:
- 1~2 파일 변경
- 요건이 한 문장
- 기존 패턴 따름
- 새 아키텍처 결정 없음

**Standard** — Quick이 아닌 모든 것

| | Quick | Standard |
|---|---|---|
| 스킬 확인 | TDD/debugging만 | 모든 스킬 |
| 탐색 에이전트 | 1개 (Haiku) | 1~3개 |
| Plan Mode | 선택 (자유 형식) | 필수 (4-Part 구조 + 사이클 운영) |
| plannotator 리뷰 | 선택 | 사이클 1·2·3 각 1회 (총 3회) |

> Quick과 Standard 사이에서 "될지 안 될지 모르는" 기술 검증이 필요하면 `/dev-experiment` (30분 time-box)를 사용합니다.

### Quick 흐름

```
코드베이스 탐색 (Haiku 에이전트 1개)
  ↓
[Plan Mode — 선택적, 간단한 계획이 필요할 때]
  ↓
TDD (동작 변경 시)
  ↓
검증 → 커밋
```

Quick tier는 plan.md frontmatter에 `tier: Quick`을 명시하면 `exit-plan-mode-guard` hook을 우회합니다.

### Standard 흐름 (Phase 1 ~ 6.5)

```
[설계]
Phase 1: 코드베이스 탐색
  - Explore Agent 1~3개 (병렬, Haiku)
  - memory/ 실패/성공 패턴 + active_context.md 확인
  ↓
Phase 2: brainstorming
  - superpowers:brainstorming 스킬 사용
  - Claude가 질문을 하나씩 던지며 요구사항/제약/성공기준 탐색
  - 2~3개 접근법 제안 → 설계를 섹션별로 제시/승인
  ↓
Phase 3: Plan Mode 진입 (사이클 운영)
  - standard-plan-mode skill 로드 (필수)
  - steering-load skill 호출 → {project_root}/specs/_steering/ 로드 (있으면)
  - 사이클 1 [Part 1]: 임시 plan에 cycle: 1 + master_plan_path 명시 → 작성
    → ExitPlanMode → plannotator-annotate → 사용자 승인 → master parts_reviewed: [1]
    → EnterPlanMode 재진입
  - 사이클 2 [Part 2]: 위와 동일, parts_reviewed: [1, 2]
  - 사이클 3 [Part 3+4 통합]: 분리 회귀 트리거 판정 후 통합/분리 결정
    → ExitPlanMode → plannotator → 승인 → parts_reviewed: [1, 2, 3, 4]
  - 마지막 ExitPlanMode → master plan을 specs/NNN-{feature}/plan.md로 저장
  ↓
[구현 준비]
Phase 4: 브랜치 + 워크트리 생성
  - 브랜치: feature/{NNN-feature-name}
  - 필요 시 superpowers:using-git-worktrees로 격리 환경 생성
  ↓
[구현]
Phase 5: TDD 구현 (Edit Mode)
  - plan.md Part 3의 태스크를 순서대로 구현
  - 각 태스크: 실패 테스트 → 구현 → 통과 확인 → [x] 표시
  - Phase 완료 시: superpowers:requesting-code-review
  ↓
[마무리]
Phase 6: 최종 품질 + 검증
  - /simplify — 코드 품질 최종 리뷰
  - plan.md Part 1 AC 기반 최종 검증 (verification-before-completion)
  - merge/PR/cleanup 결정 (finishing-a-development-branch)
  → 커밋
  ↓
Phase 6.5: Reflect
  - 잘된 것 → success-patterns.md 후보
  - 개선할 것 → failure-patterns.md 후보
  - 다음 작업에 가져갈 것 → active_context.md "다음 단계" 갱신
  → /end-session의 Reflect 수집 단계와 1:1 매핑 (자동 기록 X, 사용자 명시 후 append)
```

### brainstorming과 Plan Mode의 관계

- **brainstorming**: 대화를 통해 요구사항/제약/성공기준을 **탐색** (Phase 2)
- **Plan Mode**: 탐색 결과를 4-Part 구조로 **기록**하고 사이클 단위로 **검토** (Phase 3)
- 탐색 ≠ 기록이므로 겹치지 않는다

### 도구 역할 분담

**설계 단계:**

| 단계 | 도구 | 역할 |
|------|------|------|
| 요구사항 탐색 | superpowers:brainstorming | 인터랙티브 설계 탐색 |
| 절차 강제 | standard-plan-mode | 사이클 단위 진행 + Pre-Edit Checklist + master frontmatter 추적 |
| 영구 정보 로드 | steering-load | _steering/product,tech,structure.md를 read-only 로드 |
| 구조화 | Plan Mode | brainstorming 결과 → 4-Part 계획 |
| 사이클 리뷰 | plannotator-annotate | 매 사이클 ExitPlanMode 후 인터랙티브 리뷰 |
| 통합 리뷰 (선택) | Ultraplan / 터미널 | 팀 리뷰 또는 직접 승인 |
| 자동 검증 | exit-plan-mode-guard hook | 매 ExitPlanMode 시 frontmatter 검증 + 차단 |

**구현 단계:**

| 단계 | 도구 | 역할 |
|------|------|------|
| 브랜치/워크트리 | superpowers:using-git-worktrees | 격리 환경 생성 (선택) |
| TDD 구현 | superpowers:test-driven-development | Red → Green → Refactor |
| 병렬 실행 | superpowers:dispatching-parallel-agents | 독립 태스크 동시 진행 |
| 디버깅 | superpowers:systematic-debugging | 문제 발생 시 |
| 코드 리뷰 | superpowers:requesting-code-review | Phase 완료 후 |
| 코드 품질 | /simplify | 전체 구현 완료 후 최종 정리 |
| 검증 | superpowers:verification-before-completion | 완료 선언 전 |
| 브랜치 마무리 | superpowers:finishing-a-development-branch | merge/PR/cleanup |
| 에스컬레이션 | oracle-consultation | 3-failure rule 또는 아키텍처 결정 |

---

## 5. Plan Mode 4-Part 구조 & 사이클 운영

Standard 워크플로우에서 작성하는 계획은 다음 4-Part 구조를 따릅니다. 작성 단위는 4-Part로 유지하되, **리뷰 단위는 3 사이클**입니다.

### Part 1: Context & Requirements (사이클 1)

brainstorming 결과를 정형화:
- **문제 정의** (Problem Statement)
- **범위**: In-Scope / Out-of-Scope
- **Acceptance Criteria** — 두 형식 모두 호환:
  - 권장: `WHEN [조건] / THE SYSTEM SHALL [동작]` (조건/동작 명시 형식)
  - 호환: Given/When/Then BDD 시나리오
- **(옵션) Acceptance Criteria — 실행 경로** — 자율 작업 단위가 큰 Standard에서 권장:
  - 도구 호출 횟수 상한
  - 동일 파일 편집 횟수 상한
  - 금지 도구
  - 필수 검증 step
  - 사용자 승인 게이트

> Part 1의 AC가 완료 기준의 SSOT(Single Source of Truth). 검증 시 이 항목들을 순회하며 pass/fail 판정.

### Part 2: Technical Design (사이클 2)

기술 설계:
- 영향 파일/모듈 목록
- 아키텍처 결정 + 근거
- 검토한 대안

### Part 3: Tasks (사이클 3 — Part 4와 통합 리뷰)

실행 체크리스트:
- `[ ]` Step-by-step 체크리스트
- `||` 병렬 가능 마커
- Step별 예상 파일 변경
- `Depends on: T00N` 의존성

> Part 3가 tasks.md 역할. 구현 중 `[x]`로 표시, frontmatter 자동 동기화.

### Part 4: Risks & Verification (사이클 3 — Part 3과 통합 리뷰)

위험과 검증:
- 기술적 위험 요소 + 완화 방안
- 검증 기준 (어떻게 동작을 확인하는가)
- 무효화 신호 (즉시 롤백 트리거)

> 사이클 3 진입 직후 분리 회귀 트리거(태스크 ≥15 / 위험 ≥8 / 글로벌·보안·외부 API 의존)를 판정. 트리거 충족 시 [Part 3] / [Part 4] 두 사이클로 분리.

### plan.md 메타데이터 (Frontmatter)

**master plan** — 4-Part 본질·진행 추적:
```yaml
---
type: master-plan
feature: NNN-feature-name
status: Draft | In-Progress | Done
created: YYYY-MM-DD
tier: Standard
parts_reviewed: []   # 사이클 승인 시마다 [1], [1,2], [1,2,3,4] 누적
current_phase: N
current_step: N
branch: feature/NNN-feature-name
target_save_path: <project>/specs/NNN-{feature}/plan.md
steering: [product, tech, structure]   # 옵션 — _steering/에서 로드한 파일 목록
---
```

**임시 plan** (사이클별, hook 통과용 메타 파일):
```yaml
---
type: meta-progress
tier: Standard            # 본질 그대로 (Quick 거짓 표기 금지)
parts_reviewed: []
master_plan_path: <master 절대 경로>
cycle: 1                  # 1, 2, 3
---
```

> 전체 템플릿: `claude-config/skills/plan-lifecycle/templates.md` 참조
> 사이클 절차 상세: `claude-config/skills/standard-plan-mode/SKILL.md` 참조

### exit-plan-mode-guard hook 통과 조건

`hooks/exit-plan-mode-guard.sh`는 매 ExitPlanMode 호출 직전 plan.md frontmatter를 검증합니다. 다음 중 하나면 통과:

1. `tier: Quick` — Quick tier 우회
2. `parts_reviewed: [1, 2, 3, 4]` 모두 충족 — Standard 모든 사이클 완료
3. `master_plan_path` 명시 + 그 master plan이:
   - `tier: Quick`
   - 또는 `parts_reviewed` 길이 ≥ 1 (사이클 2 이상 진행 중)
   - 또는 `parts_reviewed: []`이면서 임시 plan에 `cycle: 1` 명시 (첫 사이클 부트스트랩)

미달 시 차단 + 안내 메시지가 출력됩니다.

---

## 6. 세션 관리

### `/start-session`

Claude Code 대화 시작 시 실행:

1. **프로젝트 환경 감지** — git repo 여부 확인 (Plan Mode + Ultraplan 사용 가능 여부)
2. **진행 중 plan 탐지** — `specs/` 디렉토리에서 `status: in-progress`인 plan.md 검색
3. **컨텍스트 복원** — session-log.md 최근 항목, plan.md Part 3 미완료 태스크, memory/failure-patterns
4. **active_context.md 복원** — `~/.claude/projects/<cwd-encoded>/memory/active_context.md`의 "현재 초점 / 최근 변경 / 다음 단계" 3 섹션 표시 (없으면 신규 생성 안내)
5. **브랜치 확인** — plan.md의 branch 필드와 현재 브랜치 비교

### `/end-session`

작업 종료 시 실행:

1. **작업 요약** — 완료/변경 파일/커밋 정리
2. **상태 동기화** — plan.md Part 3 체크리스트 업데이트, session-log.md 기록, frontmatter 동기화
3. **Completion Assessment** — plan.md Part 1 AC 기반 진행도 판정
4. **active_context.md 갱신** — "현재 초점 / 최근 변경 / 다음 단계" 3 섹션 입력
5. **Reflect 수집** (Phase 6.5) — 3 슬롯 입력:
   - 잘된 것 → success-patterns.md append 후보
   - 개선할 것 → failure-patterns.md append 후보
   - 다음 작업에 가져갈 것 → active_context.md "다음 단계" 갱신

> 자동 기록은 하지 않고 사용자 명시 승인 후 각 파일에 append.

---

## 7. 프로젝트별 산출물 경로

모든 산출물은 프로젝트 루트의 `specs/` 디렉토리에 저장됩니다:

```
{project_root}/specs/
├── _steering/                ← 프로젝트별 영구 정보 (선택, steering-load skill이 read-only 로드)
│   ├── product.md            ← 제품/도메인 컨텍스트
│   ├── tech.md               ← 기술 스택, 의존성 결정
│   └── structure.md          ← 모듈 경계, 디렉토리 규약
├── 001-local-dev-environment/
│   ├── plan.md               ← 4-Part 통합 계획 (master plan, SSOT)
│   ├── session-log.md        ← 세션별 진행 기록
│   └── research.md           ← 기술 미지수 해결 (필요 시)
├── 002-user-auth/
│   └── ...
└── 003-payment/
    └── ...
```

- `NNN-{feature-name}/` 형식 (3자리 순번)
- git으로 관리 — PR 리뷰 시 계획도 함께 리뷰 가능
- Superpowers 기본 경로(`docs/superpowers/`)를 `rules/04-integration.md`에서 오버라이드

### `_steering/` 영구 정보 (선택)

매 plan.md Part 2에 stack/모듈 경계/도메인 어휘를 반복 기록하는 비용을 줄이기 위한 디렉토리. Standard tier Plan Mode 진입 시 `steering-load` skill이 자동으로 read-only 로드합니다.

```bash
# 프로젝트에 _steering/ 시범 작성
mkdir -p {project_root}/specs/_steering
$EDITOR {project_root}/specs/_steering/product.md
$EDITOR {project_root}/specs/_steering/tech.md
$EDITOR {project_root}/specs/_steering/structure.md
```

> 미작성 프로젝트에서도 plan flow는 정상 진행됩니다 (skill이 skip + 안내 메시지만 출력).
> 6개월간 갱신 0회면 롤백 권장.

### 프로젝트 레벨 전환

팀 전체가 익숙해지면 유저 레벨(`~/.claude/`)에서 프로젝트 레벨(`.claude/`)로 전환 가능:

```
{project_root}/.claude/
├── CLAUDE.md
├── rules/
├── skills/
├── commands/
└── hooks/
```

프로젝트 레벨 설정이 유저 레벨보다 우선합니다.

---

## 8. 예시

`examples/specs/001-local-dev-environment/`에 4-Part plan.md 형식의 예시가 있습니다.

### 파일 구성

| 파일 | 역할 |
|------|------|
| **plan.md** | 4-Part 통합 계획: Context & Requirements, Technical Design, Tasks, Risks & Verification |
| **session-log.md** | 3개 세션의 진행 기록, AC pass/fail 판정 |

### 예시의 핵심 포인트

1. **Part 1** — Acceptance Criteria가 Given/When/Then 형식으로 5개 정의. 이것이 완료 기준. (신규 plan은 `WHEN/THE SYSTEM SHALL` 형식 권장)
2. **Part 2** — 아키텍처 결정 4가지 + 검토한 대안 3가지. 왜 이 방식을 선택했는지 근거 포함.
3. **Part 3** — 5개 Phase, 8개 태스크. `||` 병렬 마커, `Depends on` 의존성 명시.
4. **Part 4** — 기술적 위험 3가지 + 검증 기준 6가지.
5. **session-log.md** — 세션별 완료/미완료/발견사항 기록. 마지막 세션에서 AC 전체 PASS 판정.

---

## 9. 선택 사항

### context-bar.sh (컨텍스트 사용량 상태 바)

Claude Code 하단에 다음과 같은 상태 바를 표시합니다:

```
user@host | ~/project | main (2 files, synced 20m ago) | ████▄░░░░░ 45%
```

**설정 방법:**

1. Step 3에서 `context-bar.sh`가 이미 복사되었는지 확인:
   ```bash
   ls ~/.claude/scripts/context-bar.sh
   ```

2. `~/.claude/settings.json`에 추가:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/scripts/context-bar.sh"
     }
   }
   ```

3. `jq` 설치 (없는 경우):
   ```bash
   brew install jq
   ```

### Python 외 언어

`rules/03-coding.md`는 Python 컨벤션입니다. 다른 언어를 사용한다면:
- 해당 파일을 프로젝트 언어에 맞게 수정하세요
- 또는 프로젝트 레벨 `.claude/rules/03-coding.md`로 오버라이드하세요

---

## 10. FAQ

### 기존 `~/.claude/` 설정이 있는데요?

Step 2에서 백업한 뒤, Step 3에서 파일을 복사하세요. `settings.json`은 기존 `permissions`를 유지하면서 `enabledPlugins` + `hooks` 섹션만 추가하면 됩니다. 특히 `hooks.PreToolUse` 항목은 ExitPlanMode 절차 검증에 필수입니다.

### Plan Mode가 뭔가요? 사이클 운영은?

Claude Code의 내장 기능으로, Claude가 코드를 수정하지 않고 계획만 작성하는 모드입니다. 본 워크플로우는 4-Part Plan을 3 사이클(Part 1 / Part 2 / Part 3+4)로 검토하며, 매 사이클마다 ExitPlanMode → plannotator → EnterPlanMode 순환을 거쳐 사용자 승인을 받습니다. `exit-plan-mode-guard` hook이 이 절차를 자동 검증합니다.

### plannotator가 Plan Mode 안에서 호출이 안 돼요

시스템 정책상 Plan Mode 안에서는 plannotator-annotate 같은 외부 도구 호출이 차단됩니다. 그래서 매 사이클마다 ExitPlanMode → plannotator → EnterPlanMode 순환이 필요하며, 이 절차를 hook이 강제합니다.

### rules/ 파일을 수정해도 되나요?

네. `03-coding.md`의 컨벤션을 프로젝트 스타일에 맞게 조정하거나, `01-principles.md`의 TDD 규칙을 완화/강화할 수 있습니다. `02-architecture.md`의 LLM 안티패턴 섹션은 자신의 도메인에 맞춰 누적해 가세요.

### memory/는 어떻게 활용?

별도 설정 불필요. Claude가 대화 중 중요 정보를 자동 저장합니다. "이것 기억해"라고 명시적으로 요청할 수도 있습니다. 프로젝트별 실패/성공 패턴, 진행 중 작업 스냅샷(`active_context.md`)도 자동 기록됩니다.

### `_steering/`는 꼭 만들어야 하나요?

선택 사항입니다. 미작성 프로젝트에서도 plan flow는 정상 진행됩니다(`steering-load` skill이 skip + 안내 메시지만 출력). 동일한 stack/도메인 정보를 plan.md Part 2에 반복 기록하는 비용이 부담될 때 시범 작성하세요.

### 가설 검증이 필요할 때는?

Quick과 Standard 사이에 `/dev-experiment`를 사용합니다. 30분 time-box로 "될지 안 될지" 먼저 확인하고, 결과에 따라 본 작업을 진행합니다.

### 디버깅이 계속 실패하면?

3회 연속 실패 시 자동으로 중단되고 `/oracle-consultation`으로 escalation됩니다. 추가 수정 시도 없이 아키텍처 수준에서 재논의합니다.

### Quick tier로 hook을 우회하고 싶어요

plan.md frontmatter에 `tier: Quick` 명시하면 통과합니다. **단**, Standard 작업을 hook 통과용으로 거짓 표기하는 것은 금지입니다(본질 거짓 표기). 매 사이클 ExitPlanMode 운영을 위해서는 `master_plan_path` 패턴(임시 plan)을 사용하세요.
