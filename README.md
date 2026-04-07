# Claude SDD Workflow

Claude Code 기반 **Spec Driven Development** 워크플로우 설정 패키지.

요구사항을 문서(spec)로 구조화하고, 구현 계획(plan)과 태스크(tasks)로 분해한 뒤, TDD로 구현하는 전체 흐름을 Claude Code가 따르도록 구성합니다.

---

## 목차

1. [SDD란?](#1-sdd란)
2. [Claude Code 확장 개념](#2-claude-code-확장-개념)
3. [설치 가이드](#3-설치-가이드)
4. [워크플로우 가이드](#4-워크플로우-가이드)
5. [프로젝트별 경로 설정](#5-프로젝트별-경로-설정)
6. [예시로 보는 SDD](#6-예시로-보는-sdd)
7. [FAQ](#7-faq)

---

## 1. SDD란?

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

```
~/.claude/
├── CLAUDE.md          ← 메인 지침 (항상 로딩)
├── settings.json      ← 플러그인, 언어 설정
├── rules/             ← 원칙과 제약 (항상 로딩)
├── skills/            ← 워크플로우 (필요 시 로딩)
├── commands/          ← /명령어로 직접 호출
├── memory/            ← 대화 간 학습 내용 저장
└── plugins/           ← 외부 실행 엔진 (별도 설치)
```

| 요소 | 로딩 시점 | 역할 |
|------|----------|------|
| **CLAUDE.md** | 항상 | 절대 규칙, 아키텍처 안내 |
| **rules/** | 항상 | TDD 원칙, Python 컨벤션, 워크플로우 흐름 |
| **skills/** | Claude가 필요 시 | plan 문서 관리, 디버깅 escalation, SubAgent 위임 |
| **commands/** | `/명령어` 입력 시 | `/start-session`, `/end-session` |
| **plugins** | 설정에 따라 | superpowers, plannotator |
| **memory/** | 항상 (인덱스) | 프로젝트 컨텍스트, 피드백 기록 |

### 이 워크플로우에 포함된 파일들

**rules/** (항상 로딩):
- `01-principles.md` — TDD, Verification, Debugging, Tidy First
- `02-coding.md` — Python 코딩 컨벤션
- `03-integration.md` — Quick/Standard 판별, 도구 역할 분담

**skills/** (필요 시 로딩):
- `plan-lifecycle/` — spec, plan, tasks, session-log 문서 형식과 상태 추적
- `oracle-consultation/` — 복잡한 문제나 디버깅 3회 실패 시 escalation
- `agent-handbook/` — SubAgent 위임 시 프롬프트 템플릿

**commands/** (직접 호출):
- `/start-session` — 진행 중 작업 탐지, 세션 컨텍스트 복원
- `/end-session` — 작업 정리, 상태 동기화, 학습 추출

**plugins** (별도 설치):

| 플러그인 | 역할 |
|---------|------|
| **superpowers** | brainstorming, TDD, debugging, verification, code review 등 핵심 워크플로우 |
| **plannotator** | 마크다운 문서를 웹 UI로 띄워 시각적 리뷰/어노테이션 |

**외부 도구**:

| 도구 | 역할 |
|------|------|
| **SpecKit** | 구조화된 산출물 생성 (프로젝트별 CLI 도구, 없으면 superpowers가 폴백) |

### memory/

Claude Code는 대화에서 얻은 중요 정보를 `~/.claude/projects/{project}/memory/`에 자동 저장합니다.
별도 설정 없이 동작하며, "이것 기억해"라고 명시적으로 요청할 수도 있습니다.

---

## 3. 설치 가이드

### 사전 요구사항

- Claude Code CLI 설치 완료 ([공식 문서](https://docs.anthropic.com/en/docs/claude-code/overview))

### Step 1: 레포 클론

```bash
git clone https://github.com/honeyuheony/claude-sdd-workflow.git
cd claude-sdd-workflow
```

### Step 2: 기존 설정 백업

```bash
# 기존 설정이 있으면 백업
mkdir -p ~/.claude/backups
cp ~/.claude/CLAUDE.md ~/.claude/backups/ 2>/dev/null
cp -r ~/.claude/rules ~/.claude/backups/ 2>/dev/null
cp -r ~/.claude/skills ~/.claude/backups/ 2>/dev/null
cp -r ~/.claude/commands ~/.claude/backups/ 2>/dev/null
```

### Step 3: 설정 파일 복사

```bash
# 디렉토리 생성 (없으면)
mkdir -p ~/.claude/rules ~/.claude/skills ~/.claude/commands

# 복사
cp claude-config/CLAUDE.md ~/.claude/CLAUDE.md
cp claude-config/rules/* ~/.claude/rules/
cp -r claude-config/skills/* ~/.claude/skills/
cp claude-config/commands/* ~/.claude/commands/
```

### Step 4: settings.json 병합

`claude-config/settings.json`은 **참고용**입니다.

```bash
# 기존 settings.json이 없으면 그대로 복사
cp claude-config/settings.json ~/.claude/settings.json

# 기존 설정이 있으면 아래 항목을 수동 추가
```

추가할 항목:

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

#### Superpowers

공식 마켓플레이스에 포함되어 있습니다.

```bash
claude plugins install superpowers@claude-plugins-official
```

#### Plannotator

CLI 바이너리를 먼저 설치한 뒤 플러그인을 추가합니다.
([GitHub: backnotprop/plannotator](https://github.com/backnotprop/plannotator))

```bash
# 1. CLI 설치
curl -fsSL https://plannotator.ai/install.sh | bash

# 2. 마켓플레이스 추가 및 플러그인 설치
claude plugins marketplace add backnotprop/plannotator
claude plugins install plannotator@plannotator
```

설치 후 Claude Code를 재시작해야 합니다.

#### 설치 확인

```bash
claude plugins list
```

#### SpecKit (프로젝트별, 선택사항)

SpecKit은 Claude Code 플러그인이 아닌 **독립 CLI 도구**입니다.
설치하면 구조화된 산출물 생성이 가능하지만, 없어도 superpowers가 폴백합니다.
([GitHub: github/spec-kit](https://github.com/github/spec-kit))

```bash
# 1. specify CLI 설치 (uv 필요)
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# 2. 프로젝트에서 초기화
cd /your/project
specify init --here --ai claude
```

초기화 후 해당 프로젝트의 `.claude/commands/`에 `/speckit.specify`, `/speckit.plan`, `/speckit.tasks` 등의 명령어가 생성됩니다.

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
| 탐색 에이전트 | 1개 | 1~3개 |
| 산출물 | 없음 | spec, plan, tasks |

### Quick 흐름

```
코드베이스 탐색
  ↓
TDD (동작 변경 시)
  ↓
검증 → 커밋
```

### Standard 흐름

```
[설계]
Phase 1: 코드베이스 탐색 (Explore Agent 1~3개, 병렬)
  ↓
Phase 2: brainstorming (인터랙티브 설계 탐색)
  - Claude가 질문을 하나씩 던지며 요구사항 파악
  - 2~3개 접근법 제안 → 설계를 섹션별로 제시/승인
  ↓
Phase 3: 산출물 생성
  - SpecKit 있으면: /speckit.specify → /speckit.plan → /speckit.tasks
  - SpecKit 없으면: brainstorming에서 spec 작성 → superpowers:writing-plans
  ↓
[리뷰 게이트]
/plannotator-annotate {plan.md 경로}
  - plan.md를 웹 UI로 띄워 시각적 리뷰
  - 라인별 어노테이션으로 정확한 피드백 전달
  ↓
[구현]
태스크별 TDD 구현 (Red → Green → Refactor)
  ↓
Phase 완료 시: code review → 검증 → 커밋
```

### 세션 관리

**`/start-session`** — 진행 중 plan 탐지, 세션 컨텍스트 복원, 브랜치 확인

**`/end-session`** — 작업 요약, tasks.md/plan.md 동기화, session-log.md 기록, 학습 추출

### `/plannotator-annotate` — 리뷰 게이트

```
/plannotator-annotate specs/001-feature/plan.md
```

마크다운 문서를 웹 브라우저로 띄워 라인별 어노테이션/코멘트를 남기면, Claude가 피드백을 읽고 반영합니다.
plan 승인 전에 사용하면 구현 단계의 재작업을 줄일 수 있습니다.

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

- `NNN-{feature-name}/` 형식 (3자리 순번)
- git으로 관리
- Superpowers 기본 경로(`docs/superpowers/`)를 `rules/03-integration.md`에서 오버라이드

### 프로젝트 레벨 전환 (향후)

팀 전체가 익숙해지면 프로젝트 레벨(`.claude/`)로 전환 가능합니다:

```
{project_root}/.claude/
├── CLAUDE.md
├── rules/
├── skills/
└── commands/
```

프로젝트 레벨 설정이 유저 레벨보다 우선합니다.

---

## 6. 예시로 보는 SDD

`examples/specs/001-local-dev-environment/`에 실제 SpecKit 형식의 예시가 있습니다.

| 파일 | 역할 | 핵심 내용 |
|------|------|----------|
| **spec.md** | 요구사항 명세 | User Story, Acceptance Scenarios, FR, Success Criteria |
| **plan.md** | 기술 설계 | Summary, Technical Context, Project Structure, Design Decisions |
| **tasks.md** | 태스크 분해 | Phase별 체크리스트, 병렬/의존성, Implementation Strategy |
| **research.md** | 기술 조사 | Decision → Rationale → Alternatives considered |

### 흐름

1. **spec.md** — 요구사항을 User Story 3개(우선순위별)로 구조화. 각 스토리에 Given-When-Then 시나리오, FR, 측정 가능한 Success Criteria 포함.

2. **research.md** — 설계 전 기술적 미지수 해결. 각 항목마다 Decision, Rationale, Alternatives.

3. **plan.md** — spec + research 기반 기술 설계. 파일 구조, 서비스별 구성, 기존 코드와의 관계.

4. **tasks.md** — plan을 Phase별 체크리스트로 분해. `[P]` 병렬 태스크, `[US1]` 스토리 매핑, MVP First 전략.

---

## 7. FAQ

### 기존 `~/.claude/` 설정이 있는데요?

Step 2에서 백업한 뒤 수동 병합하세요. `settings.json`은 기존 `permissions`를 유지하면서 `enabledPlugins`만 추가하면 됩니다.

### SpecKit은 왜 별도?

SpecKit은 Claude Code 플러그인이 아닌 독립 CLI 도구입니다. 프로젝트별로 `specify init --here --ai claude`를 실행하면 slash commands가 생성됩니다. 없어도 superpowers가 폴백하므로 워크플로우는 정상 작동합니다.

### rules/ 파일을 수정해도 되나요?

네. `02-coding.md`의 컨벤션을 프로젝트 스타일에 맞게 조정하거나, `01-principles.md`의 TDD 규칙을 완화/강화할 수 있습니다.

### memory/는 어떻게 활용?

별도 설정 불필요. Claude가 대화 중 중요 정보를 자동 저장합니다. "이것 기억해"라고 명시적으로 요청할 수도 있습니다.
