---
name: steering-load
description: Plan Mode 진입 시 프로젝트별 영구 정보(_steering/)를 컨텍스트에 로드. Standard tier에서 호출. 콘텐츠 미존재 시 skip.
user-invocable: false
---

# Steering Load

프로젝트별로 매 plan에 반복 기록되는 영구 정보(stack/제약/모듈 경계/도메인 어휘 등)를 `specs/_steering/`에 한 번만 박아두고, Plan Mode 진입 시 컨텍스트에 자동 로드한다.

## 트리거

- Standard tier Plan Mode 진입 직후
- 또는 brainstorming 종료 직후 Plan Mode 진입 시점
- Quick tier에서는 호출하지 않음 (1~2 파일 변경에 영구 정보 로드는 과함)

## 동작

1. 현재 프로젝트 루트(`git rev-parse --show-toplevel` 또는 cwd) 확인
2. `{project_root}/specs/_steering/` 디렉토리 존재 여부 확인
3. **존재하지 않으면** → skip + 안내 메시지 출력. plan flow 정상 진행.
   ```
   _steering/ 미존재 — plan에 영구 정보 직접 기록 권장. 반복되는 NFR/stack/모듈 경계는
   _steering/{product,tech,structure}.md 도입 검토 (별도 plan).
   ```
4. **존재하면** → 다음 3 파일 중 존재하는 것을 read-only로 컨텍스트 진입:
   - `product.md` — 프로젝트 미션, 사용자, 도메인 어휘
   - `tech.md` — 채택 stack, 금지 라이브러리, 외부 API 정책
   - `structure.md` — 모듈 경계, 레이어, 파일 명명
5. 로드한 파일 목록을 사용자에게 1줄 요약:
   ```
   steering loaded: product, tech (structure 미작성)
   ```

## 출력 규약

- 로드 성공 시: 파일별 1줄 요약 + plan-lifecycle frontmatter `steering: [...]`에 기록 권장
- skip 시: 안내 메시지만, 정상 진행
- 한 파일이라도 로드 시점에 read 실패하면 → 해당 파일은 skip하고 나머지 진행

## plan-lifecycle 정합성

- `plan-lifecycle/SKILL.md` frontmatter `steering: [product, tech, structure]` 옵션 필드와 1:1 매핑
- plan.md frontmatter에 `steering: [product, tech]` 식으로 로드한 파일 명시
- ExitPlanMode 후 plan 저장 시 frontmatter `steering` 필드는 그대로 보존

## 비범위

- `_steering/` 콘텐츠 자체 작성은 본 skill 책임 아님 (별도 plan에서 수행)
- `_steering/` 갱신 정책(누가, 언제) 또한 본 skill 외 영역
- Quick tier 우회 키워드(`tier: Quick`)가 있으면 호출하지 않음
