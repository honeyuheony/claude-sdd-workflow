# Document Templates

## session-log.md 형식

```markdown
## Session: YYYY-MM-DD HH:MM

### 완료
- [T003] 인증 서비스 구현 — 테스트 5/5 통과
- [T004] 인증 테스트 — 통과

### 미완료/이월
- [T005] 권한 관리 — 사유: Redis 연결 이슈

### 발견사항
- Redis 타임아웃 1초 → 5초로 변경 필요

### 다음 세션 TODO
- [ ] T005 재개
- [ ] T006 시작
```

---

## Failure Log Template

```markdown
### Failure: {title}
- **Date**: YYYY-MM-DD
- **Attempted**: 시도한 방법
- **Expected**: 예상했던 결과
- **Actual**: 실제 결과
- **Root Cause**: 실패 원인
- **Lesson**: 재사용 가능한 통찰
```

---

## Success Log Template

```markdown
### Success: {title}
- **Date**: YYYY-MM-DD
- **What worked**: 성공한 접근법
- **Why it worked**: 성공 요인
- **Pattern**: 재사용 가능한 패턴
```
