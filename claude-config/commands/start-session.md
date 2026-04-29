---
description: 세션 시작 - 진행 중 작업 확인, 맥락 파악
---

# 세션 시작

새 세션을 시작합니다.

## 0단계: 프로젝트 환경 감지

```
git rev-parse --is-inside-work-tree 2>/dev/null
→ git repo: "Git 프로젝트 — Plan Mode + Ultraplan 사용 가능"
→ non-git: "Non-git 환경 — Plan Mode 터미널 리뷰"
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

2. **plan.md Part 3** — 미완료 태스크([ ]) 추출
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

## 1.8단계: active_context.md 복원

진행 중 작업의 현재 상태를 단일 파일에서 빠르게 복원합니다:

```
project_memory_dir = ~/.claude/projects/<cwd-encoded>/memory/
active_context_path = {project_memory_dir}/active_context.md
```

**파일이 존재하면**, 내용을 읽어 다음 3 섹션 표시:
- **현재 초점**: 진행 중 plan / Phase / Step
- **최근 변경**: 최근 의도 단위 변경 1~3건
- **다음 단계**: 후속 작업 체크리스트

**파일이 존재하지 않으면**:
> "active_context.md가 없습니다. 신규 생성하시겠습니까? (자동 생성 X — 사용자 명시 후 작성)"
