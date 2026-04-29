---
description: 세션 종료 - 작업 정리, 평가, 학습 추출
---

# 세션 종료

세션을 종료하고 진행 상태를 정리합니다.

## 1단계: 작업 요약

이번 세션에서 수행한 작업을 정리합니다:

- **완료된 작업** — 구현/수정/삭제한 내용
- **변경된 파일** — 주요 파일 목록
- **커밋 내역** — 생성된 커밋들

## 2단계: 상태 동기화

Standard 작업이 있었으면 산출물 상태를 동기화합니다:

### 2A: plan.md Part 3 업데이트
- 완료된 태스크를 `[x]`로 표시
- 진행률 계산: "{완료}/{전체} tasks ({퍼센트}%)"

### 2B: session-log.md 작성
해당 Specs 폴더의 session-log.md에 현재 세션 기록을 **추가** (append):

```markdown
## Session: {현재 날짜와 시간}

### 완료
- [T{ID}] {태스크 제목} — {결과/테스트 통과 여부}

### 미완료/이월
- [T{ID}] {태스크 제목} — 사유: {이유}

### 발견사항
- {중요한 기술적 발견이나 의사결정}

### 다음 세션 TODO
- [ ] {다음에 할 작업}
```

### 2C: plan.md frontmatter 동기화
plan.md Part 3의 체크리스트 상태를 기반으로 frontmatter를 자동 계산:
- `current_phase`: 현재 진행 중인 Phase 번호 (가장 최근 미완료 Phase)
- `current_step`: 해당 Phase에서 완료된 태스크 수
- 모든 태스크 완료 시: `status: done`

## 3단계: Completion Assessment

### 3A: AC 기반 진행도 (plan.md Part 1 AC 있을 때)
plan.md Part 1의 각 AC/User Scenario를 순회하여 판정:

```
AC-01: {설명} — PASS (T003, T004 완료, 테스트 통과)
AC-02: {설명} — PARTIAL (T005 미완료)
AC-03: {설명} — NOT STARTED
전체: {PASS}/{전체} AC
```

### 3B: plan.md Part 3 진행도
```
완료: {n}/{total} ({percent}%)
Phase 1: {n}/{m} 완료
Phase 2: {n}/{m} 진행 중
Phase 3: {n}/{m} 미시작
```

### 3C-1: active_context.md 갱신

`~/.claude/projects/<cwd-encoded>/memory/active_context.md`를 갱신합니다. 사용자에게 다음 3 슬롯 입력 요구:

- **현재 초점**: 진행 중 plan / Phase / Step
- **최근 변경**: 본 세션 의도 단위 변경 1~3건
- **다음 단계**: 후속 작업 체크리스트

파일이 없으면 신규 생성, 있으면 덮어쓰기. 자동 채움 X — 사용자 명시 입력 후 작성.

### 3C-2: Reflect 수집 (Phase 6.5와 1:1 매핑)

사용자에게 다음 3 슬롯 입력 요구 후 분류 제안:

- **잘된 것** → `success-patterns.md` append 후보 (사용자 명시 승인 후 기록)
- **개선할 것** → `failure-patterns.md` append 후보 (사용자 명시 승인 후 기록)
- **다음 작업에 가져갈 것** → `active_context.md` "다음 단계" 섹션 갱신 (3C-1 결과와 통합)

자동 기록 X. 형식적 산출물 방지를 위해 빈 슬롯 허용 (실 인사이트가 없으면 그대로 비움).

### 3C: 학습 추출
1. memory/ 디렉토리의 기존 메모리 파일 읽기
2. 세션 대화 이력에서 직접 분석:
   - **failure-patterns.md 업데이트**: 3회 이상 실패한 접근법 기록
   - **success-patterns.md 업데이트**: 효과적이었던 패턴 기록 (의미 있는 세션에서만)
3. 기존 failure-patterns와 대조하여 재발 패턴 식별

> **서브에이전트를 사용하지 않는다.** 세션 컨텍스트 자체가 입력이므로
> 메인 컨텍스트에서 직접 실행 (1M 컨텍스트면 충분).

## 4단계: Final Review (plan.md Part 3 모든 태스크 완료 시에만)

Task의 모든 태스크가 완료되었으면:

1. plan.md Part 1 AC 전체 pass/fail 판정
2. 각 항목의 증거(테스트 결과, 빌드 출력) 함께 제시
3. 전체 PASS → verification-before-completion 진행
4. 실패 항목 있으면 → 해당 Phase 재실행 제안
5. plan.md `status: done` 업데이트
6. 결과 요약을 session-log.md에 기록

## 5단계: 완료 알림

> "세션이 종료되었습니다. 다음 세션에서 `/start-session`으로 시작하세요."
