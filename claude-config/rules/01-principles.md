# 개발 원칙

## TDD (Red -> Green -> Refactor)

**실패 테스트 없이 프로덕션 코드 작성 금지.**

상세 프로세스: superpowers:test-driven-development

| 상황 | TDD 적용 |
|------|---------|
| 새 기능/버그 수정 | 필수 |
| 리팩토링/설정/문서 | 불필요 |

- 버그 수정: 재현 테스트 -> 수정 -> 통과 확인
- 한 번에 하나의 테스트, 통과 후 다음

## Verification

**검증 증거 없이 완료 선언 금지.**

상세 프로세스: superpowers:verification-before-completion

| Tier | 기준 도출 | 사용자 승인 |
|------|----------|:---------:|
| Quick | Skip | -- |
| Standard | brainstorming 후 도출 | 제시 후 진행 |
| SDD | spec.md AC 대체 | Phase 2 승인 |

| Bad (주관적) | Good (검증 가능) |
|-------------|----------------|
| "성능이 좋아야 한다" | "API 응답 < 200ms (p95)" |
| "코드가 깔끔해야 한다" | "모듈 내 기존 패턴 따름" |
| "에러 처리가 잘 돼야 한다" | "잘못된 입력 시 400 + 에러 메시지" |

경고 신호:
- "should", "probably", "seems to" 사용 금지
- 동일 실패 3회+ -> 중단, 전략 변경
- 요청하지 않은 기능 추가 -> 즉시 중단
- 테스트 비활성화 -> 절대 금지

## Debugging

**근본 원인 조사 없이 수정 시도 금지.**

상세 프로세스: superpowers:systematic-debugging

### 3-Failure Rule
- 3회+ 실패 -> 즉시 중단
- failure-patterns.md에 기록 (plan-lifecycle skill 참조)
- /oracle-consultation으로 escalation
- 추가 수정 시도 금지 -- 아키텍처 논의 우선

## Tidy First (커밋 규율)

구조적 변경과 동작적 변경을 같은 커밋에 섞지 않음.

**구조적** (동작 불변): rename, extract method, reformat, simplify conditionals
**동작적** (기능 변경): 새 기능, 버그 수정, API/스키마 변경

순서: 구조적 먼저 -> 테스트 확인 -> 동작적 변경

커밋 조건:
1. 모든 테스트 통과
2. 린터/타입 체커 경고 해결
3. 단일 논리 단위

커밋 메시지: WHY 설명 (WHAT 아닌). 작고 빈번한 커밋.
```
refactor: rename UserService to UserManager
feat: add user authentication endpoint
fix: resolve race condition in processing
```
