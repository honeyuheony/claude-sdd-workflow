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
