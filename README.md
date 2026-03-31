# Claude SDD Workflow

Claude Code 기반 **Spec Driven Development** 워크플로우 설정 패키지.

요구사항을 문서(spec)로 구조화하고, 구현 계획(plan)과 태스크(tasks)로 분해한 뒤, TDD로 구현하는 전체 흐름을 Claude Code가 따르도록 구성합니다.

---

## 목차

1. [SDD(Spec Driven Development)란?](#1-sddspec-driven-development란)
2. [Claude Code 확장 개념](#2-claude-code-확장-개념)
3. [설치 가이드](#3-설치-가이드)
4. [워크플로우 가이드](#4-워크플로우-가이드)
5. [프로젝트별 경로 설정](#5-프로젝트별-경로-설정)
6. [예시로 보는 SDD](#6-예시로-보는-sdd)
7. [FAQ](#7-faq)

---

## 1. SDD(Spec Driven Development)란?

### 문제

구두 지시나 즉석 설명으로 개발을 진행하면:
- 맥락 누락 → 의도와 다른 구현
- 요건 변경 추적 불가 → 재작업
- 완료 기준 불명확 → "됐나?" 반복

### 해결

**요구사항을 문서로 먼저 만들고, 그 문서를 기반으로 개발한다.**

```
요구사항 정의
  ↓
spec.md (User Story + Acceptance Criteria + Requirements)
  ↓
research.md (기술 미지수 해결)
  ↓
plan.md (기술 설계 + Key Design Decisions)
  ↓
tasks.md (Phase별 체크리스트)
  ↓
TDD 구현 (Red → Green → Refactor)
  ↓
검증 (Success Criteria 기반)
```

Claude Code가 이 흐름을 자동으로 따르도록 rules/skills/plugins로 구성한 것이 이 워크플로우입니다.

---

## 2. Claude Code 확장 개념

Claude Code는 `~/.claude/` 디렉토리의 설정 파일을 통해 동작을 확장할 수 있습니다.

### 디렉토리 구조

```
~/.claude/
├── CLAUDE.md          ← 메인 지침 (항상 로딩)
├── settings.json      ← 권한, 플러그인, 언어 설정
├── rules/             ← 원칙과 제약 (항상 로딩)
├── skills/            ← 워크플로우 (필요 시 로딩)
├── commands/          ← 사용자가 /명령어로 직접 호출
├── memory/            ← Claude가 대화 간 학습 내용 저장
└── plugins/           ← 외부 실행 엔진 (별도 설치)
```

### 각 요소의 역할

| 요소 | 로딩 시점 | 역할 | 예시 |
|------|----------|------|------|
| **CLAUDE.md** | 항상 | 절대 규칙, 아키텍처 안내 | "테스트 통과 후에만 커밋" |
| **rules/** | 항상 | 원칙과 제약 | TDD 원칙, Python 컨벤션 |
| **skills/** | Claude가 필요 시 | 워크플로우, 템플릿 | plan 문서 관리, 디버깅 escalation |
| **commands/** | 사용자가 `/명령어` 입력 시 | 세션 관리 | `/start-session`, `/end-session` |
| **plugins** | 설정에 따라 | 외부 실행 엔진 | superpowers, plannotator |
| **memory/** | 항상 (인덱스) | 대화 간 학습 유지 | 프로젝트 컨텍스트, 피드백 기록 |

### rules/ — 항상 로딩되는 원칙

Claude Code가 세션 시작 시 자동으로 읽는 파일들입니다. 모든 대화에 적용됩니다.

- `01-principles.md` — TDD, Verification, Debugging, Tidy First
- `02-coding.md` — Python 코딩 컨벤션 (Black/Ruff, type hints, snake_case 등)
- `03-integration.md` — Quick/Standard 판별, 워크플로우 흐름, 도구 역할 분담

### skills/ — 필요할 때 호출되는 워크플로우

Claude가 상황에 맞게 자동으로 참조하거나, 다른 스킬이 호출합니다.

- `plan-lifecycle/` — spec, plan, tasks, session-log 문서의 형식, 저장 경로, 상태 추적
- `oracle-consultation/` — 복잡한 아키텍처 결정이나 디버깅 3회 실패 시 escalation
- `agent-handbook/` — SubAgent 위임 시 프롬프트 템플릿

### commands/ — 직접 실행하는 명령어

Claude Code 대화창에서 `/명령어`로 직접 호출합니다.

- `/start-session` — 진행 중 작업 탐지, 세션 컨텍스트 복원
- `/end-session` — 작업 정리, 상태 동기화, 학습 추출

### plugins — 외부 실행 엔진

`claude plugins install`로 별도 설치하는 확장입니다.

| 플러그인 | 역할 |
|---------|------|
| **superpowers** | brainstorming, TDD, debugging, verification, code review 등 핵심 워크플로우 |
| **plannotator** | 마크다운 문서를 웹 UI로 띄워 시각적 리뷰/어노테이션 |
| **speckit** | 구조화된 산출물 생성 (프로젝트별 설치) |

### memory/ — 대화 간 학습

Claude Code는 대화에서 얻은 중요 정보를 `~/.claude/projects/{project}/memory/`에 저장합니다.

- **user** — 사용자 역할, 선호, 역량 (맞춤 응답에 활용)
- **feedback** — 사용자가 교정한 접근 방식 (같은 실수 반복 방지)
- **project** — 진행 중인 작업, 의사결정 배경
- **reference** — 외부 시스템 위치 (Linear 프로젝트, Slack 채널 등)

`MEMORY.md`가 인덱스 역할이고, 각 메모리는 별도 `.md` 파일로 저장됩니다.
별도 설정 없이도 Claude가 자동으로 관리하지만, 명시적으로 "이것 기억해"라고 요청할 수도 있습니다.

---

## 3. 설치 가이드

### 사전 요구사항

- Claude Code CLI 설치 완료 ([공식 문서](https://docs.anthropic.com/en/docs/claude-code/overview))
- GitHub CLI (`gh`) 설치 (선택사항)

### Step 1: 레포 클론

```bash
git clone https://github.com/uheon/claude-sdd-workflow.git
cd claude-sdd-workflow
```

### Step 2: 기존 설정 백업

```bash
# 기존 설정이 있으면 백업
cp -r ~/.claude/rules ~/.claude/rules.backup 2>/dev/null
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.backup 2>/dev/null
```

### Step 3: 설정 파일 복사

```bash
# CLAUDE.md
cp claude-config/CLAUDE.md ~/.claude/CLAUDE.md

# rules/
cp claude-config/rules/* ~/.claude/rules/

# skills/
cp -r claude-config/skills/* ~/.claude/skills/

# commands/
cp claude-config/commands/* ~/.claude/commands/
```

### Step 4: settings.json 병합

`claude-config/settings.json`은 **참고용**입니다. 기존 settings.json이 있으면 수동으로 병합하세요.

```bash
# 기존 설정이 없으면 그대로 복사
cp claude-config/settings.json ~/.claude/settings.json

# 기존 설정이 있으면 아래 항목을 수동 추가:
# - enabledPlugins에 superpowers, plannotator 추가
# - language, effortLevel 설정
```

주요 설정값:

```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "plannotator@plannotator": true
  },
  "language": "korean",
  "effortLevel": "medium"
}
```

> `permissions`는 개인별로 다르므로 포함하지 않았습니다. Claude Code 사용 중 권한 요청이 오면 그때 허용하면 됩니다.

### Step 5: 플러그인 설치

각 플러그인마다 설치 방법이 다릅니다.

#### Superpowers

Claude Code 공식 마켓플레이스에 포함되어 있습니다.

```bash
claude plugins install superpowers@claude-plugins-official
```

#### Plannotator

CLI 바이너리를 먼저 설치한 뒤 플러그인을 추가합니다.
([GitHub: backnotprop/plannotator](https://github.com/backnotprop/plannotator))

```bash
# 1. CLI 설치
curl -fsSL https://plannotator.ai/install.sh | bash

# 2. 플러그인 마켓플레이스 추가 및 설치
claude plugins marketplace add backnotprop/plannotator
claude plugins install plannotator
```

> 설치 후 Claude Code를 재시작해야 합니다.

#### 설치 확인

```bash
claude plugins list
```

#### SpecKit (프로젝트별)

SpecKit은 Claude Code 플러그인이 아닌 **독립 CLI 도구**입니다.
`uv`로 설치한 뒤 프로젝트에서 초기화하면 Claude Code용 slash commands가 자동 생성됩니다.
([GitHub: github/spec-kit](https://github.com/github/spec-kit))

```bash
# 1. specify CLI 설치 (uv 필요)
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# 2. 프로젝트에서 초기화 (Claude Code 연동)
cd /your/project
specify init --here --ai claude
```

초기화 후 `.claude/commands/`에 `/speckit.specify`, `/speckit.plan`, `/speckit.tasks` 등의 명령어가 생성됩니다.
SpecKit이 없는 프로젝트에서는 superpowers가 자동 폴백합니다.

### Step 6: 프로젝트에 specs/ 디렉토리 생성

작업할 프로젝트의 루트에 산출물 저장용 디렉토리를 만듭니다:

```bash
cd /your/project
mkdir specs
```

---

## 4. 워크플로우 가이드

### Tier 판별: Quick vs Standard

모든 작업은 먼저 Tier를 판별합니다.

**Quick** — 아래 조건을 **모두** 충족:
- 1~2 파일 변경
- 요건이 한 문장
- 기존 패턴 따름
- 새 아키텍처 결정 없음

**Standard** — Quick이 아닌 모든 것

| | Quick | Standard |
|---|---|---|
| 스킬 확인 | TDD/debugging만 | 모든 스킬 확인 |
| 탐색 에이전트 | 1개 | 1~3개 |
| 산출물 | 없음 | spec, plan, tasks |

### Quick 흐름

```
코드베이스 탐색 (Explore Agent)
  ↓
TDD (동작 변경 시)
  ↓
verification-before-completion
  ↓
커밋
```

간단한 버그 수정, 설정 변경, 작은 기능 추가에 적합합니다.

### Standard 흐름

```
[설계]
Phase 1: 코드베이스 탐색 (Explore Agent 1~3개, 병렬)
  ↓
Phase 2: brainstorming (인터랙티브 설계 탐색)
  - Claude가 질문을 하나씩 던지며 요구사항 파악
  - 2~3개 접근법 제안 + 추천
  - 설계를 섹션별로 제시, 승인
  ↓
Phase 3: 산출물 생성
  - SpecKit 있으면: /speckit.specify → /speckit.clarify → /speckit.plan → /speckit.tasks
  - SpecKit 없으면: brainstorming에서 spec 작성 → superpowers:writing-plans
  ↓
[리뷰 게이트]
/plannotator-annotate {plan.md 경로}
  - plan.md를 웹 UI로 띄워서 시각적으로 리뷰
  - 라인별 어노테이션/코멘트로 정확한 피드백 전달
  - Claude가 피드백을 반영하여 plan 수정
  ↓
[구현]
태스크별 TDD 구현
  - [RED] 실패 테스트 작성
  - [GREEN] 최소 구현으로 통과
  - [REFACTOR] 정리
  - 각 태스크 완료 시 tasks.md 체크
  ↓
Phase 완료 시: superpowers:requesting-code-review
  ↓
verification-before-completion → 커밋
```

### 세션 관리

**`/start-session`** — 세션 시작 시 실행

- 현재 프로젝트에 진행 중인 plan이 있는지 탐지
- 있으면: 마지막 session-log 표시, 미완료 태스크 안내, 브랜치 확인
- 없으면: "오늘 어떤 작업을 할까요?" 질문

**`/end-session`** — 세션 종료 시 실행

- 이번 세션 작업 요약 (완료/이월)
- tasks.md 체크, plan.md frontmatter 동기화
- session-log.md에 기록 추가
- 학습 추출 (failure/success patterns)

### `/plannotator-annotate` — 리뷰 게이트 도구

plan.md, spec.md 등 마크다운 문서를 **웹 브라우저 UI**로 띄워서 리뷰할 수 있습니다.

```
/plannotator-annotate specs/001-feature/plan.md
```

- 문서가 웹 페이지로 열리고, 각 라인에 어노테이션/코멘트를 남길 수 있음
- "3번 태스크에서 이 부분 수정해줘"보다 **라인을 직접 가리키며** 피드백 가능
- 어노테이션을 저장하면 Claude가 피드백을 읽고 자동 반영

Standard 워크플로우의 **리뷰 게이트** 단계에서 사용합니다.
plan을 승인하기 전에 이 도구로 꼼꼼히 검토하면, 구현 단계에서의 재작업을 줄일 수 있습니다.

---

## 5. 프로젝트별 경로 설정

### specs/ 디렉토리

모든 SDD 산출물은 프로젝트 루트의 `specs/` 디렉토리에 저장됩니다:

```
{project_root}/specs/
├── 001-local-dev-environment/
│   ├── spec.md           ← 요구사항 (User Story + AC + FR)
│   ├── plan.md           ← 기술 설계
│   ├── tasks.md          ← Phase별 태스크 체크리스트
│   ├── research.md       ← 기술 조사 및 의사결정 근거
│   └── session-log.md    ← 세션별 진행 기록 (/end-session이 생성)
├── 002-user-auth/
│   └── ...
└── 003-payment/
    └── ...
```

### 네이밍 규칙

- `NNN-{feature-name}/` — 순번 + 기능명
- 순번은 3자리 (001, 002, ...)
- git으로 관리 (`.gitignore`에 추가하지 않음)

### Superpowers 기본 경로 오버라이드

Superpowers 플러그인의 기본 저장 경로는 `docs/superpowers/specs/`와 `docs/superpowers/plans/`입니다.
이 워크플로우에서는 `rules/03-integration.md`의 설정으로 `specs/` 경로를 사용하도록 오버라이드합니다.

### 향후: 프로젝트 레벨 전환

현재는 유저 레벨(`~/.claude/`)에 설정했지만, 팀 전체가 익숙해지면 프로젝트 레벨로 전환할 수 있습니다:

```
{project_root}/.claude/
├── CLAUDE.md
├── rules/
├── skills/
└── commands/
```

프로젝트 레벨 설정은 해당 레포에서만 적용되며, 유저 레벨 설정과 병합됩니다.
(프로젝트 레벨이 우선)

---

## 6. 예시로 보는 SDD

`examples/specs/001-local-dev-environment/`에 "로컬 개발 환경 구성" 예시가 있습니다.
실제 SpecKit이 생성하는 형식과 동일한 구조입니다.

### 산출물 구성

| 파일 | 역할 | 핵심 내용 |
|------|------|----------|
| **spec.md** | 요구사항 명세 | User Story, Acceptance Scenarios, Functional Requirements, Success Criteria |
| **plan.md** | 기술 설계 | Summary, Technical Context, Project Structure, Key Design Decisions |
| **tasks.md** | 태스크 분해 | Phase별 체크리스트, 병렬/의존성 표기, Implementation Strategy |
| **research.md** | 기술 조사 | 설계 결정의 근거, 대안 비교 |

### 흐름

1. **spec.md** — "로컬에서 E2E 테스트가 필요하다"는 요구사항을 구조화
   - User Story 3개 (우선순위별)
   - 각 스토리에 Given-When-Then 시나리오
   - Functional Requirements (FR-001~007)
   - 측정 가능한 Success Criteria

2. **research.md** — 설계 전 기술적 미지수 해결
   - ARM64 호환성, Dockerfile 분리 전략, 네트워크 전략
   - 각 항목: Decision → Rationale → Alternatives considered

3. **plan.md** — spec + research를 기반으로 기술 설계
   - 파일 구조, 서비스별 구성, 네트워크/볼륨 설계
   - 기존 코드와의 관계 (수정하지 않을 것 명시)

4. **tasks.md** — plan을 실행 가능한 단위로 분해
   - Phase별 Purpose/Goal/Checkpoint
   - `[P]` 병렬 가능 태스크, `[US1]` 스토리 매핑
   - Dependencies & Execution Order로 실행 순서 명확화
   - MVP First 전략 (US1 먼저 검증 후 확장)

각 파일을 열어보면 형식과 구조를 바로 파악할 수 있습니다.

---

## 7. FAQ

### "기존 `~/.claude/` 설정이 있는데요?"

Step 2에서 백업한 뒤, 기존 설정과 수동 병합하세요.
특히 `settings.json`은 기존 `permissions`를 유지하면서 `enabledPlugins`만 추가하면 됩니다.

### "SpecKit은 왜 별도 설치?"

SpecKit은 Claude Code 플러그인이 아닌 독립 CLI 도구(`specify-cli`)입니다.
프로젝트별로 `specify init --here --ai claude`를 실행하면 해당 프로젝트의 `.claude/commands/`에 `/speckit.specify`, `/speckit.plan` 등의 명령어가 생성됩니다.
SpecKit이 없는 프로젝트에서는 superpowers가 자동으로 폴백하므로, 설치하지 않아도 워크플로우는 정상 작동합니다.

### "프로젝트 레벨로 전환하려면?"

프로젝트 루트에 `.claude/` 디렉토리를 만들고 동일한 구조(CLAUDE.md, rules/, skills/, commands/)를 배치합니다.
프로젝트 레벨 설정이 유저 레벨보다 우선합니다.

### "memory/는 어떻게 활용?"

별도 설정 불필요. Claude Code가 대화 중 중요한 정보를 자동으로 저장합니다.
명시적으로 "이 패턴 기억해" 등으로 요청할 수도 있습니다.
저장된 메모리는 `~/.claude/projects/{project}/memory/`에서 확인 가능합니다.

### "플러그인 설치가 안 돼요"

Claude Code 버전이 최신인지 확인하세요:
```bash
claude --version
```

플러그인 목록 확인:
```bash
claude plugins list
```

### "rules/ 파일을 수정해도 되나요?"

네. 팀/개인 상황에 맞게 자유롭게 수정하세요.
예를 들어 `02-coding.md`의 Python 컨벤션을 프로젝트 스타일에 맞게 조정하거나,
`01-principles.md`의 TDD 규칙을 완화/강화할 수 있습니다.
