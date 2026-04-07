---
name: dev-experiment
description: Quick과 Standard 사이의 ~30분 time-box 가설 검증. "될지 안 될지 모르니까 먼저 시도" 상황에서 사용.
---

# /dev-experiment Skill

Quick-Standard 사이 gap을 메우는 짧은 가설 검증.

## When to Use

**이런 상황에서 사용:**
- 라이브러리/도구가 원하는 동작을 지원하는지 먼저 확인
- 결과에 따라 아키텍처가 달라지는 기술 결정
- 30분 내에 결론 낼 수 있는 작은 검증

**예시:**
- "Mermaid.js가 iframe 안에서 렌더링 되는지 확인"
- "FastAPI에서 WebSocket + SSE 동시 지원 가능한지 테스트"
- "새 ORM 패턴이 기존 쿼리 성능에 영향 주는지 벤치마크"

## When NOT to Use

- Quick으로 처리 가능한 것 (1~2파일, 명확한 요건)
- 30분을 넘길 것 같은 작업 → Standard 사용
- 이미 결과가 예측 가능한 것

## Execution Steps

| 단계 | 시간 | 내용 |
|------|------|------|
| 1. Hypothesis | 1분 | 검증하려는 가설 1문장으로 명확화 |
| 2. Setup | 5분 | 최소한의 환경 준비 (experiment/ 브랜치 생성) |
| 3. Implement | 15분 | 가설을 검증할 최소한의 코드 작성 |
| 4. Validate | 5분 | 결과 확인, 가설 pass/fail 판정 |
| 5. Conclude | 2분 | 결론 기록 + 다음 행동 결정 |

**타임박스**: 30분. 초과 시 즉시 중단 → Standard로 전환.

## Branch Policy

- 브랜치: `experiment/{brief-description}`
- 커밋: 불필수 (검증용 임시 코드)
- **성공 시**: 결론 기록 후 본 작업 진행. 브랜치 삭제 또는 유지.
- **실패 시**: failure-patterns.md에 기록 (01-principles.md Debugging 참조). 브랜치 삭제.

## Escalation

| 상황 | 행동 |
|------|------|
| 30분 초과 | 즉시 중단 → Standard 전환 |
| 범위 확장 감지 | 중단 → 사용자에게 보고 |
| 가설 불명확 | 먼저 1문장으로 명확화 |

## Output Format

검증 완료 후 결론 요약:
```
## Experiment Result: {가설 제목}
- **가설**: {1문장}
- **결과**: Pass / Fail
- **근거**: {테스트 결과 요약}
- **다음 행동**: {Standard 진행 / 다른 접근 시도 / 포기}
```
