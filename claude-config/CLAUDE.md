# CLAUDE.md

`~/.claude/` 규칙 시스템 — Global instructions for Claude Code.

---

## 절대 규칙

1. 요청된 작업만 수행, 불필요한 파일 생성 금지
2. 구조적/동작적 변경 분리 (Tidy First)
3. 테스트 통과 후에만 커밋
4. 응답은 한국어 (코드 식별자, 경로, 명령어 제외)
5. Edit Mode에서 작업 (Plan Mode 미사용)
6. 산출물 작성 시 03-integration.md 역할 분담 참조

---

## 아키텍처

| 레이어 | 역할 | 로딩 |
|--------|------|------|
| `rules/` | 원칙과 제약 | 항상 |
| `skills/` | 워크플로우, 참조 자료 | on-demand |
| plugins | 실행 엔진 (superpowers, plannotator, speckit) | 설정별 |

rules/는 "무엇을 지켜야 하는가", skills/plugins는 "어떻게 실행하는가".

---

## 규칙 인덱스

| 파일 | 내용 |
|------|------|
| `rules/01-principles.md` | TDD, Verification, Debugging, Tidy First 원칙 |
| `rules/02-coding.md` | Python 코딩 컨벤션 |
| `rules/03-integration.md` | Tier 판별, 도구 역할 분담, 산출물 경로 |

---

## 언어 규칙

- **한국어 필수**: 응답, 사고 과정, 작업 상태, 문서
- **영어 허용**: 코드 식별자, 파일 경로, 기술 용어, 터미널 명령어

---

## 충돌 해결

| 상황 | 해결 |
|------|------|
| rules/ vs superpowers skill | rules/가 원칙, skill이 실행 방식 |
| "요청된 작업만" vs "테스트/스킬 호출" | 품질 검증과 작업 방식이므로 허용 |
| Quick vs skill 확인 | Quick: TDD/debugging만; Standard: 모든 skill 확인 |
