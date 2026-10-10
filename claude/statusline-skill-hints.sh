#!/usr/bin/env bash
# ~/.claude/statusline-skill-hints.sh
# ccstatusline의 custom-command 세그먼트로 등록. claude-harness의 cadence-reminder 훅이
# 세션 시작 때 ~/.claude/skill-hints/<레포 경로>에 남긴 권고 스킬 이름을
# 노란 배경·검은 굵은 글씨로 띄운다. 대화 속 환기는 묻히기 때문이다.
# 권고가 없으면(파일 없음) 아무것도 출력하지 않아 칸이 비어 있다.

input=$(cat)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)
[ -n "$dir" ] || exit 0

root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
file="${CLAUDE_SKILL_HINTS_DIR:-$HOME/.claude/skill-hints}/$(printf '%s' "$root" | tr '/' '-')"
[ -s "$file" ] || exit 0

hints=$(paste -sd '|' "$file" | sed 's/|/ · /g')
printf '\033[1;30;103m ▶ 권고 스킬: %s \033[0m' "$hints"
