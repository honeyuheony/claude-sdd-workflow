#!/usr/bin/env bash
# ExitPlanMode 호출 시 Standard Plan Mode 절차 위반을 감지해 차단.
#
# 통과 조건 (어느 하나):
#   1. 가장 최근 plan.md frontmatter의 tier == "Quick" (Quick tier 우회 — 단순 작업 한정)
#   2. 가장 최근 plan.md frontmatter의 parts_reviewed에 [1, 2, 3, 4] 모두 존재
#   3. (사이클 운영) frontmatter에 master_plan_path가 명시되어 있고,
#      그 master plan이 다음 중 하나:
#        - tier: Quick (master 자체가 Quick)
#        - tier: Standard + parts_reviewed 길이 >= 1 (Part 1 이상 진행 중인 사이클 운영)
#        - parts_reviewed: [1, 2, 3, 4] 완료
#        - parts_reviewed 비어있고 임시 plan frontmatter에 cycle: 1 명시 (첫 사이클 부트스트랩)
#
# master_plan_path 패턴은 매 Part마다 ExitPlanMode → plannotator → EnterPlanMode 사이클을
# 정직하게 표현하는 용도. 임시 plan은 메타 파일이고 본질(Standard 4-Part)은 master에서 추적.
# 매 사이클은 사용자 명시 승인을 통해 진행되므로 hook은 master plan의 *진행 중* 상태만 확인.
#
# 검증 흐름:
#   - stdin JSON에서 session_id 추출
#   - ~/.claude/projects/*/<session_id>.jsonl 에서 transcript 찾기
#   - transcript에서 가장 최근 ~/.claude/plans/*.md 또는 specs/**/plan.md
#     Edit/Write 대상 파일 경로 추출
#   - 그 plan 파일 frontmatter parsing → tier / master_plan_path / parts_reviewed 순 검사
#   - 미달이면 차단 + 누락 안내

set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")

# session_id 추출 실패 → safe-fail (통과)
if [[ -z "$SESSION_ID" ]]; then
  exit 0
fi

# transcript 파일 위치
TRANSCRIPT=$(find "$HOME/.claude/projects" -maxdepth 2 -name "${SESSION_ID}.jsonl" -type f 2>/dev/null | head -n 1)

if [[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]]; then
  exit 0
fi

# === plan 파일 경로 추출 ===
# transcript에서 가장 최근 Edit/Write tool_use의 file_path가
# ~/.claude/plans/*.md 또는 **/specs/**/plan.md 패턴인 것
PLAN_PATH=$(grep -E '"name":"(Edit|Write)"' "$TRANSCRIPT" 2>/dev/null | \
  grep -oE '"file_path":"[^"]+\.md"' | \
  grep -E '/(\.claude/plans/|specs/.*/plan\.md)' | \
  tail -n 1 | \
  sed -E 's/.*"file_path":"([^"]+)".*/\1/' || echo "")

# plan 파일 미발견 → safe-fail
# (다른 도구로 plan 작성한 경우 또는 Quick tier에서 plan.md 미작성한 경우)
if [[ -z "$PLAN_PATH" || ! -f "$PLAN_PATH" ]]; then
  exit 0
fi

# === frontmatter 추출 ===
FRONTMATTER=$(awk '/^---$/{f++; next} f==1' "$PLAN_PATH" 2>/dev/null || echo "")

if [[ -z "$FRONTMATTER" ]]; then
  REASON="plan.md (${PLAN_PATH})에 frontmatter가 없어 진행 상태 검증 불가.

standard-plan-mode skill을 사용해 frontmatter를 초기화하고 Part 단위로 진행하세요.

  ---
  type: master-plan
  tier: Standard         # 또는 Quick (단순 작업)
  parts_reviewed: []     # Standard일 때 Part 승인마다 [1], [1,2], ...
  ...
  ---

Quick tier(1~2 파일 변경, 한 문장 요건)라면 frontmatter에 tier: Quick 으로 명시하면 본 hook을 우회합니다."
  jq -n --arg reason "$REASON" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
fi

# === Quick tier 우회 검사 ===
# tier: Quick 라인이 있으면 통과 (대소문자 무관, 따옴표 허용)
TIER_LINE=$(printf '%s\n' "$FRONTMATTER" | grep -iE '^tier:[[:space:]]*' | head -n 1 || echo "")
if [[ -n "$TIER_LINE" ]]; then
  TIER_VALUE=$(printf '%s' "$TIER_LINE" | sed -E 's/^[Tt]ier:[[:space:]]*//' | tr -d '"' "'" | tr -d '[:space:]')
  if [[ "${TIER_VALUE,,}" == "quick" ]]; then
    exit 0
  fi
fi

# === master_plan_path 분기 (사이클 운영) ===
# 임시 plan에 master_plan_path 필드가 있으면 그 master plan을 따라가 본질 검증.
# 이 패턴은 매 Part 사이클 ExitPlanMode 운영을 정직하게 표현 (Quick tier 우회 대체).
MASTER_PLAN_LINE=$(printf '%s\n' "$FRONTMATTER" | grep -E '^master_plan_path:' | head -n 1 || echo "")
if [[ -n "$MASTER_PLAN_LINE" ]]; then
  MASTER_PLAN_PATH=$(printf '%s' "$MASTER_PLAN_LINE" | sed -E 's/^master_plan_path:[[:space:]]*//' | tr -d '"' | tr -d "'" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
  # ~ 확장
  MASTER_PLAN_PATH="${MASTER_PLAN_PATH/#\~/$HOME}"

  if [[ -f "$MASTER_PLAN_PATH" ]]; then
    MASTER_FM=$(awk '/^---$/{f++; next} f==1' "$MASTER_PLAN_PATH" 2>/dev/null || echo "")

    # master tier: Quick → 통과
    MASTER_TIER_LINE=$(printf '%s\n' "$MASTER_FM" | grep -iE '^tier:[[:space:]]*' | head -n 1 || echo "")
    MASTER_TIER=$(printf '%s' "$MASTER_TIER_LINE" | sed -E 's/^[Tt]ier:[[:space:]]*//' | tr -d '"' "'" | tr -d '[:space:]')
    if [[ "${MASTER_TIER,,}" == "quick" ]]; then
      exit 0
    fi

    # master parts_reviewed 검사
    MASTER_PARTS_LINE=$(printf '%s\n' "$MASTER_FM" | grep -E '^parts_reviewed:' | head -n 1 || echo "")
    MASTER_PARTS_RAW=$(printf '%s' "$MASTER_PARTS_LINE" | sed -E 's/^parts_reviewed:[[:space:]]*//' | tr -d '[]," ')
    # 길이 >= 1 (Part 1 이상 진행 중) 또는 [1,2,3,4] 완료 모두 통과
    if [[ -n "$MASTER_PARTS_RAW" ]]; then
      exit 0
    fi

    # 첫 사이클 부트스트랩 예외 — 임시 plan frontmatter에 cycle: 1이 명시되어 있으면
    # master parts_reviewed가 비어있어도 통과 (사이클 1은 master 누적 시작 직전 상태)
    CYCLE_LINE=$(printf '%s\n' "$FRONTMATTER" | grep -E '^cycle:' | head -n 1 || echo "")
    if [[ -n "$CYCLE_LINE" ]]; then
      CYCLE_VALUE=$(printf '%s' "$CYCLE_LINE" | sed -E 's/^cycle:[[:space:]]*//' | tr -d '"' "'" | tr -d '[:space:]')
      if [[ "$CYCLE_VALUE" == "1" ]]; then
        exit 0
      fi
    fi

    # master plan에 parts_reviewed가 비어있고 첫 사이클(cycle: 1)도 아님 → 차단
    REASON="사이클 운영 모드(master_plan_path=${MASTER_PLAN_PATH})이지만 master plan의 parts_reviewed가 비어있습니다.

사이클 2 이상은 master plan에 최소 Part 1이 승인되어 있어야 통과합니다.

  master plan frontmatter:
    type: master-plan
    tier: Standard
    parts_reviewed: [1]   # ← Part 1 승인 후 최소 이 상태

첫 사이클(Part 1 부트스트랩)이라면 임시 plan frontmatter에 cycle: 1 을 명시하세요:

  ---
  type: meta-progress
  tier: Standard
  parts_reviewed: []
  master_plan_path: <master 절대 경로>
  cycle: 1
  ---"
    jq -n --arg reason "$REASON" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
    exit 0
  fi

  # master plan 파일이 존재하지 않음
  REASON="frontmatter에 master_plan_path: ${MASTER_PLAN_PATH} 가 명시되어 있지만 파일이 존재하지 않습니다.

사이클 운영 모드를 사용하려면 master plan 파일이 먼저 specs/NNN-feature/plan.md 경로에 생성되어 있어야 합니다."
  jq -n --arg reason "$REASON" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
fi

# === parts_reviewed 검사 ===
PARTS_LINE=$(printf '%s\n' "$FRONTMATTER" | grep -E '^parts_reviewed:' | head -n 1 || echo "")

if [[ -z "$PARTS_LINE" ]]; then
  REASON="plan.md frontmatter에 parts_reviewed 필드가 없습니다 (tier도 Quick이 아님).

Standard tier라면 standard-plan-mode skill에 따라 parts_reviewed: [] 로 초기화하고, 각 Part 작성 + plannotator-annotate 리뷰 + 사용자 승인 후 Part 번호를 누적 추가하세요.

  parts_reviewed: [1]           # Part 1 승인 후
  parts_reviewed: [1, 2]        # Part 2 승인 후
  parts_reviewed: [1, 2, 3, 4]  # 모든 Part 승인 — ExitPlanMode 가능

Quick tier라면 frontmatter에 tier: Quick 을 추가해 본 hook을 우회하세요."
  jq -n --arg reason "$REASON" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
fi

# 배열 내용 파싱: "[1, 2, 3, 4]" → "1234"
PARTS_RAW=$(printf '%s' "$PARTS_LINE" | sed -E 's/^parts_reviewed:[[:space:]]*//' | tr -d '[]," ' )
HAS_1=0; HAS_2=0; HAS_3=0; HAS_4=0
[[ "$PARTS_RAW" == *1* ]] && HAS_1=1
[[ "$PARTS_RAW" == *2* ]] && HAS_2=1
[[ "$PARTS_RAW" == *3* ]] && HAS_3=1
[[ "$PARTS_RAW" == *4* ]] && HAS_4=1

if [[ $HAS_1 -eq 1 && $HAS_2 -eq 1 && $HAS_3 -eq 1 && $HAS_4 -eq 1 ]]; then
  exit 0
fi

MISSING=""
[[ $HAS_1 -eq 0 ]] && MISSING="$MISSING 1"
[[ $HAS_2 -eq 0 ]] && MISSING="$MISSING 2"
[[ $HAS_3 -eq 0 ]] && MISSING="$MISSING 3"
[[ $HAS_4 -eq 0 ]] && MISSING="$MISSING 4"

REASON=$(printf '%s' "Standard Plan Mode 절차 위반 — Part 진행 상태 미달.

plan.md: ${PLAN_PATH}
${PARTS_LINE}
누락 Part:${MISSING}

각 Part는 다음 단계를 거쳐야 합니다 (standard-plan-mode skill 참조):
  1. Part 본문 작성
  2. plannotator-annotate 호출 → 사용자 피드백 수신
  3. Pre-Edit Checklist 5문항 적용 (재정렬 vs patch 판정)
  4. 사용자 승인 (\"Part N 승인\" 등)
  5. plan.md frontmatter parts_reviewed에 N 추가

Quick tier(단순 작업)라면 frontmatter에 tier: Quick 을 추가하면 본 hook을 우회합니다.")

jq -n --arg reason "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'

exit 0
