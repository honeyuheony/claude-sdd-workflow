# CLAUDE.md

`~/.claude/` 규칙 시스템 — Global instructions for Claude Code.

---

## 절대 규칙

1. 요청된 작업만 수행 — 질문형은 답변만, 상태 변경은 명시적 실행 동사에만 반응
2. 구조적/동작적 변경 분리 (Tidy First)
3. 테스트 통과 후에만 커밋
4. 응답은 한국어 (코드 식별자, 경로, 명령어 제외)
5. 기본은 Edit Mode, 설계 필요 시 Plan Mode (04-integration.md 참조)
6. 산출물 작성 시 04-integration.md 역할 분담 참조

---

## 아키텍처

| 레이어 | 역할 | 로딩 |
|--------|------|------|
| `rules/` | 원칙과 제약 | 항상 |
| `skills/` | 워크플로우, 참조 자료 | on-demand |
| plugins | 실행 엔진 (superpowers, hookify, context7) | 설정별 |

rules/는 "무엇을 지켜야 하는가", skills/plugins는 "어떻게 실행하는가".

---

## 규칙 인덱스

| 파일 | 내용 |
|------|------|
| `rules/01-principles.md` | TDD, Verification, Debugging, Tidy First 원칙 |
| `rules/02-architecture.md` | 모듈/클래스 설계, 의존성, 추상화, LLM 안티패턴 |
| `rules/03-coding.md` | Python 코딩 컨벤션 |
| `rules/04-integration.md` | Tier 판별, 도구 역할 분담, 산출물 경로 |
| `rules/05-clarifications.md` | NEEDS CLARIFICATION 마커, 3개 한도, plan.md Clarifications 섹션 |

---

## 언어 규칙

- **한국어 필수**: 응답, 사고 과정, 작업 상태, 문서
- **영어 허용**: 코드 식별자, 파일 경로, 기술 용어, 터미널 명령어

---

## 메모리 관리

Auto Memory + Auto Dream 활성화 상태. 메모리 정리는 Auto Dream에 위임.

| 역할 | 담당 |
|------|------|
| 새 메모리 기록 | Claude (세션 중 자동/수동) |
| 오래된 메모리 정리 | Auto Dream (세션 간 자동) |
| failure-patterns 관리 | Auto Dream (교훈만 간결하게 기록, 정리는 위임) |
| project 메모리 삭제 | Auto Dream (머지 완료된 설계 결정 자동 판단) |

Claude가 하지 않는 것:
- 세션 중 오래된 메모리 수동 삭제 (Auto Dream 영역)
- failure-patterns에 상세 로그 기록 (session-log.md에 기록, patterns에는 교훈만)
- 완료된 project 메모리 정리 (Auto Dream이 stale 판단)

---

## 충돌 해결

| 상황 | 해결 |
|------|------|
| rules/ vs superpowers skill | rules/가 원칙, skill이 실행 방식 |
| "요청된 작업만" vs "테스트/스킬 호출" | 품질 검증과 작업 방식이므로 허용 |
| Quick vs skill 확인 | Quick: TDD/debugging만; Standard: 모든 skill 확인 |
| Plan Mode vs Edit Mode | 설계 = Plan Mode (Standard 필수, Quick 선택); 구현 = Edit Mode |
| 시스템 auto memory 지침 vs CLAUDE.md 메모리 규칙 | CLAUDE.md가 우선 (기록 형식, 정리 위임 등) |
