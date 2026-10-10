#!/usr/bin/env bash
# ~/.claude/statusline-skill-hints.sh
# ccstatusline의 custom-command 세그먼트로 등록. claude-harness 훅이 세션 시작 때
# ~/.claude/skill-hints/<레포 경로>(cadence-reminder)와 <레포 경로>.readiness(weekly-readiness-check)에 남긴
# 권고를 노란 배경·검은 굵은 글씨로 띄운다. 한 줄은 '스킬 — 이유'. 앞의 2개만 보이고 나머지는 '외 n건'.
# 권고가 없으면 아무것도 출력하지 않아 칸이 비어 있다.

input=$(cat)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)
[ -n "$dir" ] || exit 0

root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
base="${CLAUDE_SKILL_HINTS_DIR:-$HOME/.claude/skill-hints}/$(printf '%s' "$root" | tr '/' '-')"
lines=$(cat "$base" "$base.readiness" 2>/dev/null | grep -v '^[[:space:]]*$')
[ -n "$lines" ] || exit 0

n=$(printf '%s\n' "$lines" | wc -l | tr -d ' ')
shown=$(printf '%s\n' "$lines" | head -2 | paste -sd '|' - | sed 's/|/ · /g')
[ "$n" -gt 2 ] && shown="$shown 외 $((n - 2))건"
printf '\033[1;30;103m ▶ %s \033[0m' "$shown"
