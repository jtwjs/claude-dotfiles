#!/usr/bin/env bash
# ~/.claude/statusline-sdd.sh
# ccstatusline의 custom-command 세그먼트. 창에 돌아왔을 때 "이 세션이 뭘 하던지 · 어디까지 갔는지"를 한 줄로.
#   ◆ <task> 3/7 ▶ <첫 미완료 step>   ← 레포 phases/*/index.json 중 미완료이면서 가장 최근에 바뀐 것
#   ⛔ <step>                         ← 그 step 이 error·blocked
#   💬 "<마지막 요청 앞 40자>"          ← 세션 기록의 last-prompt 줄(사람이 친 요청). 플러그인이 보낸 메시지는 건너뜀
# 아이디어 출처: lcalmsky/deadhd 상태줄(MIT, 코드는 가져오지 않음). 2026-10-18.
# 1000ms 제한(ccstatusline 기본) 안에 끝나야 한다.

export LC_ALL=en_US.UTF-8   # ${var:0:40} 이 글자 단위로 자르게
input=$(cat)
dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
out=""

root=$( [ -n "$dir" ] && git -C "$dir" rev-parse --show-toplevel 2>/dev/null )
if [ -n "$root" ] && [ -d "$root/phases" ]; then
  # 미완료 phase 중 가장 최근에 바뀐 index.json — jq 한 번으로 전부 보고 첫 줄만
  files=$(ls -t "$root"/phases/*/index.json 2>/dev/null)
  line=$( [ -n "$files" ] && printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 jq -r '
      [.steps[]? | select(.status != "obsolete")] as $s
      | ($s | map(select(.status == "completed" or .status == "done")) | length) as $d
      | ($s | map(select(.status != "completed" and .status != "done")) | first) as $n
      | if $n == null then empty
        else "\(input_filename)\t\($d)\t\($s | length)\t\($n.status)\t\($n.name)" end' 2>/dev/null | head -1)
  if [ -n "$line" ]; then
    IFS=$'\t' read -r f d t st name <<<"$line"
    task=$(basename "$(dirname "$f")")
    if [ "$st" = "error" ] || [ "$st" = "blocked" ]; then
      out="\033[1;31m⛔ $task $d/$t $name\033[0m"
    else
      out="\033[36m◆ $task $d/$t ▶ $name\033[0m"
    fi
  fi
fi

if [ -n "$tp" ] && [ -f "$tp" ]; then
  # 파일 끝에서 1MB씩 거슬러 읽으며 사람이 친 마지막 요청(last-prompt 줄)을 찾는다.
  # macOS 기본 grep·tail -c 는 긴 줄이 많은 큰 기록(170MB)에서 1초 가까이 걸려 python 으로 뒤에서부터 읽는다.
  last=$(python3 -I -c '
import json, os, re, sys
skip = re.compile(r"^(The .* plugin sent a message|<)")
with open(sys.argv[1], "rb") as f:
    end = f.seek(0, os.SEEK_END); carry = b""
    while end > 0:
        start = max(0, end - 1048576); f.seek(start)
        lines = (f.read(end - start) + carry).split(b"\n")
        carry = lines.pop(0) if start > 0 else b""
        for ln in reversed(lines):
            if not ln.startswith(b"{\"type\":\"last-prompt\"") or b"\"lastPrompt\":\"" not in ln:
                continue
            t = (json.loads(ln).get("lastPrompt") or "").strip()
            if t and not skip.match(t):
                print(" ".join(t.split())); sys.exit(0)
        end = start
' "$tp" 2>/dev/null)
  if [ -n "$last" ]; then
    short="${last:0:40}"
    [ "${#last}" -gt 40 ] && short="$short…"
    [ -n "$out" ] && out="$out · "
    out="$out\033[2m💬 \"$short\"\033[0m"
  fi
fi

[ -n "$out" ] && printf '%b' "$out"
exit 0
