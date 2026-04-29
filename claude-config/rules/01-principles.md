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

### Red 품질 기준

Red = "기능 명세를 표현하는 assertion failure"

- **Invalid Red**: ImportError, NameError, SyntaxError, fixture/setup 오류
  - "기능이 없다"가 아니라 "코드가 없다"는 신호 -- 진짜 Red 아님
- **Valid Red**: AssertionError + 의도한 동작과 실제의 구체적 차이
- Red 단계에서 실제 테스트 실행 + 출력 캡처 (세션·commit 메시지에 명시)
- Red 작성과 Green 구현은 분리 -- 같은 응답·같은 commit에서 작성 금지

### 테스트 깊이 (관찰 기반)

| 검증 대상 | 적합한 테스트 |
|----------|--------------|
| 순수 로직 (계산, 변환) | 단위 테스트 (mock 불필요) |
| 외부 의존이 있는 흐름 | 통합 테스트 (testcontainers / 실 인스턴스) |
| DB 쿼리 의미 (SQL/Cypher) | E2E 테스트 (실제 DB) |

- Mock 기반 단위 테스트는 "호출 여부"만 검증 -- 의미/동작 검증 불가
- 데이터 처리 로직은 실 데이터 1건 이상으로 검증

## Verification

**검증 증거 없이 완료 선언 금지.**

상세 프로세스: superpowers:verification-before-completion

| Tier | 기준 도출 | 사용자 승인 |
|------|----------|:---------:|
| Quick | Skip | -- |
| Standard | brainstorming 후 도출 | 제시 후 진행 |
| SDD | Plan Mode Part 1 AC | Plan 승인 시 |

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

### Hypothesis First (가설 우선)
- 수정 시도 전 가능한 원인을 **모두** 나열 -> 증거·확률로 랭크 -> 가장 저렴한 진단부터
- 단일 가설 직렬 추격 금지 -- 첫 가설 반증 시 이미 다음 후보가 준비돼 있어야 함
- 공유 자원 이슈(로그, DB, 캐시, 큐)는 서비스 설정 의심 전에 공유 인프라(PostgreSQL, Redis, AMQP 등) 먼저 확인
- 비자명한 운영/인프라 버그: 근본 원인 가설 확정 전에 oracle-consultation 활용

### 3-Failure Rule
- 3회+ 실패 -> 즉시 중단
- failure-patterns.md에 기록 (plan-lifecycle skill 참조)
- /oracle-consultation으로 escalation
- 추가 수정 시도 금지 -- 아키텍처 논의 우선

## Feedback Re-alignment (피드백 수신 시 본질 재정렬)

**코멘트별 patch만 붙이는 것 금지. 본질이 깨졌는지 매번 확인.**

상세 프로세스: standard-plan-mode skill의 Pre-Edit Checklist (5문항)

### 적용 대상
- plannotator-annotate 등 검토 도구로 받은 사용자 피드백
- code review 피드백
- 사용자가 명시 의문 또는 수정 요청

### 핵심 원칙
- 피드백을 받으면 plan/spec/code의 어느 가정을 깨는지 먼저 점검
- 가정이 깨지면 → **재정렬** (영향 범위 전체 수정, 사용자에게 의도 명시 후 진행)
- 가정이 안 깨지면 → 국소 patch 가능 (단, "안 깨진다"는 답을 명시 작성 후)
- "이 코멘트는 작아 보이니 patch만" 충동이 가장 빈번한 함정 — 본질 점검을 매번 다시 한다

### 위반 신호
- 6+ 라운드 피드백 동안 plan/code의 큰 구조가 한 번도 재정렬되지 않음
- 사용자가 "본질적으로 해결" / "재정렬" / "전체 다시" 류 개입을 명시
- 피드백 답변을 응답에 작성하지 않은 채 곧바로 Edit

위반 발견 시: 진행 멈추고 Pre-Edit Checklist 5문항 재적용 → 재정렬 결과를 사용자에게 명시.

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
