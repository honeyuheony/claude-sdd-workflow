---
description: 세션 시작 - 진행 중 작업 확인, 맥락 파악
---

# 세션 시작

새 세션을 시작합니다.

## 0단계: 프로젝트 환경 감지

```
.claude/commands/speckit.specify.md 존재 확인
→ 존재: "SpecKit 사용 가능 — 역할 분담 모드 (03-integration.md)"
→ 미존재: "기본 모드 — Superpowers 폴백"
```

## 1단계: 진행 중 Plan 탐지

현재 프로젝트 내 진행 중 작업을 확인합니다:

```
project_root = git rev-parse --show-toplevel
find {project_root}/specs -name "plan.md" 2>/dev/null
→ 각 파일의 frontmatter에서 status 확인
→ status = in-progress 인 것만 필터
```

**진행 중 작업이 있으면:**

각 plan.md에서 읽어온 정보를 표시:
```
진행 중인 작업:
- [{feature}] Phase {current_phase}, Step {current_step} 완료 / 브랜치: {branch}
  파일: specs/{NNN-feature}/plan.md
```

여러 개면 전부 나열 후 질문:
> "어떤 작업을 이어서 할까요? (번호 입력 또는 '새 작업')"

**진행 중 작업이 없으면:**

> "오늘 어떤 작업을 할까요?"

## 1.5단계: 세션 컨텍스트 복원

진행 중 작업을 선택한 경우, 해당 specs 폴더에서 추가 정보를 복원합니다:

1. **session-log.md** — 최근 세션 항목 읽기
   ```
   마지막 세션 (YYYY-MM-DD):
   - 완료: T003 인증 서비스, T004 인증 테스트
   - 이월: T005 권한 관리 (사유: Redis 연결)
   - 다음 TODO: T005 재개, T006 시작
   ```

2. **tasks.md** — 미완료 태스크([ ]) 추출
   ```
   미완료 태스크: 12/20 (60% 완료)
   다음 태스크: [T005] 권한 관리 — src/services/auth.py
   ```

3. **memory/failure-patterns.md** — 최근 3개 패턴 표시 (있으면)
   ```
   최근 실패 패턴:
   - [2026-03-25] plan.md 저장 전 구현 시작
   - [2026-03-20] pyproject.toml 직접 편집 후 uv.lock 미갱신
   ```

## 1.7단계: 브랜치 상태 확인

plan.md의 `branch` 필드와 현재 체크아웃된 브랜치를 비교합니다:

```
현재 브랜치: $(git branch --show-current)
plan.md 브랜치: {branch from frontmatter}
```

불일치 시 경고:
> "plan.md는 `{plan_branch}`를 가리키지만 현재 `{current_branch}`에 있습니다. 브랜치를 전환할까요?"
