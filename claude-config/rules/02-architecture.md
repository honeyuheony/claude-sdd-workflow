# Architecture (Module/Class Design)

## Module Boundaries
- 한 모듈 = 한 책임. 공개 인터페이스를 명확히 노출
- 파일이 비대해지면 책임이 섞인 신호 -- 분할 검토
- 외부 라이브러리 import는 어댑터/인프라 레이어에 격리

## Layer & Dependency Rules
- API/Routes -> Service -> Repository -> Models (단방향)
  - **API/Routes**: HTTP, 검증, 직렬화
  - **Service**: 비즈니스 로직, 오케스트레이션
  - **Repository**: 데이터 접근, 쿼리
  - **Models**: 데이터 구조, 도메인 엔티티
- 도메인 레이어는 인프라/프레임워크에 의존하지 않음
- 경계에서는 인터페이스 역전 (DIP) -- 도메인에 interface, 인프라에 impl
- 함수 시그니처 변경 시 `grep -r "함수명("` 으로 전 호출자 확인 필수

## Class Design
- 클래스는 "상태 + 동작"이 결합된 경우만. 단순 함수 모음이면 함수로
- SRP: 한 클래스 한 책임
- 합성 > 상속
- Anemic 회피: 도메인 객체에 행동이 살아있도록 (모든 로직을 service에 몰지 않음)

## Abstraction Timing
- Rule of three: 같은 패턴이 3번 이상 반복되기 전 추상화 금지
- 구체 코드 먼저, 추상화는 패턴 검증 후
- "미래 확장"용 wrapper/스텁/interface 금지 -- 사용처 1곳뿐이면 직접 import

## LLM Anti-Patterns (관찰 기반)

다음 패턴은 `project-samoo-be`에서 실제 발생·수정된 사례로, 작성 시 회피:

- **추측성 추상화**: backward-compat 스텁이나 "확장 대비" wrapper 자동 생성 금지 (사용자가 명시 요청한 경우에만)
- **외부 API 필드명/스키마 추정 금지**: 실 호출 1건으로 검증 후 작성. 문서 없으면 실 응답 캡처가 우선
- **조건부 로직의 암묵적 가정 금지**: CASE WHEN, if-else 작성 시 모든 입력 케이스를 명시. NULL/빈 값/순서 가정을 코드에 박아넣지 않음
- **추측성 예외 처리 금지**: 실제 발생하는 예외만 catch. "혹시 모르니"의 try/except 금지
- **추측성 plugin/factory/registry 금지**: 요구가 있을 때만
