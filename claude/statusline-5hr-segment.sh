#!/usr/bin/env bash
# ~/.claude/statusline-5hr-segment.sh
# ccstatusline의 custom-command 세그먼트로 등록. rate_limits.five_hour의
# 사용률(%)을 "5h session: xx%" 형식으로 표시하고, 잔여율 구간에 따라
# 색을 입힌다(잔여율 기준 — 표시 숫자는 사용률).
#   80% 이상 남음 → 민트 그린
#   60~80% 남음   → 피치
#   20~60% 남음   → 코랄 레드
#   20% 미만 남음  → 진한 빨강(굵게)

input=$(cat)

used_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

if [ -z "$used_pct" ]; then
  exit 0
fi

used_int=$(awk -v u="$used_pct" 'BEGIN { printf "%.0f", u }')
remaining=$((100 - used_int))

MINT='\033[38;2;62;180;137m'
PEACH='\033[38;2;255;178;125m'
CORAL='\033[38;2;255;111;94m'
DEEPRED='\033[1;38;2;255;59;48m'
RESET='\033[0m'

if [ "$remaining" -ge 80 ]; then
  color="$MINT"
elif [ "$remaining" -ge 60 ]; then
  color="$PEACH"
elif [ "$remaining" -ge 20 ]; then
  color="$CORAL"
else
  color="$DEEPRED"
fi

printf "${color}5h session: %s%%${RESET}" "$used_int"
