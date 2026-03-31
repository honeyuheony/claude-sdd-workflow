---
name: agent-handbook
description: SubAgent 위임 가이드 — Delegation Template, 작업 분해 패턴. Agent 디스패치 시 참조.
user-invocable: false
---

# Agent Handbook

## Delegation Template

Agent tool로 SubAgent를 호출할 때 아래 형식을 사용한다.

### Required Fields

| Section | Content | Required |
|---------|---------|:--------:|
| TASK | 원자적 목표 (1문장) | O |
| EXPECTED OUTCOME | 완료 상태 설명 | O |
| CONTEXT | 배경 정보, 파일 경로, 기존 패턴 요약 | O |
| MUST DO | 필수 수행 사항 | — |
| MUST NOT DO | 금지 사항 | — |
| REFERENCE FILES | 참조 파일 (path:line) | — |

### Example

```
TASK: UserService login 메서드에 rate limiting 추가
EXPECTED OUTCOME: 동일 IP에서 5회 이상 실패 시 30초 차단
CONTEXT: src/services/user.py:45 기존 login 메서드, Redis 기반 캐시 사용
MUST DO: 기존 Redis 패턴 따르기, type hints 포함
MUST NOT DO: 다른 메서드 수정, 새 의존성 추가
REFERENCE FILES: src/services/user.py:45, src/utils/redis.py:12
```

### Work Decomposition

복잡한 작업은 분할한다:
- 여러 모듈/레이어에 걸치면 → 레이어별 분할
- 각 sub-task는 독립 실행 가능하게
- 의존성 없으면 병렬, 있으면 순차

Sub-task Template:
```
TASK: {parent task} sub-task {M}/{total} — {specific goal}
EXPECTED OUTCOME: {이 sub-task의 구체적 산출물}
CONTEXT: Parent: {부모 task 1줄 요약}
SCOPE: {할당된 파일/모듈}
```
