---
name: oracle-consultation
description: Use when facing complex architecture decisions, hard debugging (2+ failed attempts), multi-system tradeoffs, or need high-quality reasoning review
---

# Oracle Consultation

Read-only, high-IQ reasoning specialist for complex problems. **Consultation only - never implements directly.**

## When to Invoke (MUST)

| Trigger | Action |
|---------|--------|
| Complex architecture design | Oracle FIRST, then implement |
| 2+ failed fix attempts | Oracle FIRST, then implement |
| Multi-system tradeoffs | Oracle FIRST, then implement |
| Security/performance concerns | Oracle FIRST, then implement |
| After completing significant work | Self-review with Oracle |
| Unfamiliar code patterns | Oracle FIRST, then implement |

## When NOT to Invoke

- Simple file operations (use direct tools)
- First attempt at any fix (try yourself first)
- Questions answerable from code you've read
- Trivial decisions (variable names, formatting)
- Things you can infer from existing code patterns

## Consultation Format

When consulting Oracle, structure your request:

```markdown
## Context
[What you're trying to achieve - be specific]

## What I've Tried
[Failed approaches and WHY they failed - not just what]

## Specific Question
[The exact decision/insight you need]

## Constraints
[Time, compatibility, performance, backwards-compat requirements]
```

## Oracle Response Expectations

Oracle should provide:
1. **Analysis** of the problem space
2. **Trade-offs** between options (not just "best" answer)
3. **Recommendation** with reasoning
4. **Risks** to watch for in implementation
5. **Verification criteria** - how to know it worked

## Usage Pattern

```
1. Announce: "Consulting Oracle for [specific reason]"
2. Provide structured context
3. Wait for analysis
4. Implement based on recommendation
5. Verify against Oracle's criteria
```

## Anti-Patterns (Don't Do)

- Using Oracle for simple lookups
- Asking Oracle without trying first
- Ignoring Oracle's trade-off analysis
- Not providing constraints
- Asking vague questions like "what should I do?"

---

## Routing to Personas (1단계 — 인터페이스만)

위 절차는 **default consultation** 으로 유지된다. 추가로 5 lateral persona 가 `personas/` 디렉토리에 정의되어 있다. 페르소나 선택은 **트리거 신호** 로 수동 라우팅한다 (자동 라우팅은 SU2 `escalation-router` 에서 본격 구현).

| 트리거 신호 | 권장 페르소나 | 파일 |
|---|---|---|
| oscillation (같은 가설 2+ 회 재시도, loop-detector 보고) | **Contrarian** | `personas/contrarian.md` |
| spinning (3+ 시도, 모두 다른 방향, 진척 0) | **Hacker** | `personas/hacker.md` |
| diminishing returns (수정량 ↑, 효과 ↓) / 추상 비대 / 태스크 ≥ 15 | **Simplifier** | `personas/simplifier.md` |
| no-drift (목표·제약 변경 없이 진척만 적음) / unfamiliar 영역 / 표준·RFC 도메인 | **Researcher** | `personas/researcher.md` |
| 다중 시스템 트레이드오프 / 모듈 경계 결정 / 공개 API · schema 변경 | **Architect** | `personas/architect.md` |

### Routing 사용 절차 (1단계 manual)

1. 트리거 신호를 본인이 식별 — 위 표의 1행과 매칭
2. 매칭되는 페르소나 SKILL.md (예: `personas/contrarian.md`) 의 Question Set 과 Output Format 을 그대로 사용
3. 매칭 실패 → 본 SKILL.md 의 default Consultation Format 사용
4. 매칭 모호 → Researcher (외부 evidence) 우선

### 3-failure rule 호환성

`rules/01-principles.md` Debugging 의 \"3-failure rule → oracle-consultation\" 트리거는 **변경 없이 유지**. 단 본 router 가 추가되면서, 3회 실패의 패턴에 따라 페르소나가 달라진다:

- 같은 수정을 반복했다 → Contrarian
- 매번 다른 시도였다 → Hacker
- 단순 typo / 작은 실수 → Simplifier 호출 불요, default consultation 으로 충분

### SU 사이클 예고

SU2 `escalation-router` 가 도입되면 본 routing 표를 자동화한다:
- loop-detector 출력 → Contrarian 자동 호출
- drift-monitor 출력 (no-drift) → Researcher 자동 호출
- info-gain 출력 (diminishing) → Simplifier 자동 호출

1단계는 인터페이스 (페르소나 SKILL.md 5개 + 본 router 표) 만 정의한다.
