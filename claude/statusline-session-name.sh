#!/usr/bin/env bash
# ~/.claude/statusline-session-name.sh
# ccstatusline의 custom-command 세그먼트로 등록. statusline JSON의 session_name
# (/rename으로 정한 세션 이름)을 보여준다. 비어 있거나 없으면 아무것도 출력하지 않는다.

input=$(cat)
name=$(echo "$input" | jq -r '.session_name // empty' 2>/dev/null)
[ -n "$name" ] || exit 0
printf '%s' "$name"
