#!/usr/bin/env python3
# ~/.claude/statusline-sdd.py — ccstatusline custom-command(3줄째 한 조각). 창에 돌아왔을 때 "뭘 하던지 · 어디까지"를 한 줄로.
#   트랙 ⛔admin 💤renderer 진행1   ← 지휘 자리(트랙 표가 있는 레포의 기준 worktree)일 때만. claude-harness tracks_status.py --compact
#   bv-admin ⛔fe 진행1 · dash 진행2 ← 지휘 설정(~/.claude/conductor.json)의 seat 폴더면 대상 레포 전부(2026-10-31). 손댈 것 없으면 안 뜬다
#   SDD be-empty-200 3/7 ▸ step     ← 레포 phases/*/index.json 중 미완료이면서 가장 최근에 바뀐 것. error·blocked면 ⛔
#   💬 마지막 요청                   ← 세션 기록의 last-prompt 줄(사람이 친 요청, 플러그인 메시지 제외)
# 좁은 화면: 터미널 폭을 재서(ccstatusline 과 같은 방식: 부모 프로세스 tty → stty) 넘치면
#   요청 → 작업 이름 → 요청 전체 순으로 줄인다. 폭을 못 재면 80칸으로 본다. 한글은 2칸으로 센다.
# 아이디어 출처: lcalmsky/deadhd 상태줄(MIT, 코드는 가져오지 않음). 2026-10-18. 1000ms 제한 안(실측 0.1~0.4s).
import json, os, re, subprocess, sys, unicodedata
from pathlib import Path

HARNESS = Path(os.environ.get("CLAUDE_HARNESS_ROOT") or Path.home() / ".claude/plugins/marketplaces/jtwjs-plugins")
TRACKS = HARNESS / "skills/conductor/scripts/tracks_status.py"
CONDUCTOR = HARNESS / "hooks/lib/conductor.py"
SKIP = re.compile(r"^(The .* plugin sent a message|<)")


def run(args, cwd=None):
    try:
        r = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=0.6)
        return r.stdout.strip() if r.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def cols(s):
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in s)


def clip(s, n):
    if cols(s) <= n:
        return s
    out, w = "", 0
    for c in s:
        cw = 2 if unicodedata.east_asian_width(c) in "WF" else 1
        if w + cw > n - 1:
            break
        out, w = out + c, w + cw
    return out + "…"


def term_width():
    v = os.environ.get("CCSTATUSLINE_WIDTH", "")
    if v.isdigit():
        return int(v)
    pid = os.getppid()
    for _ in range(8):
        out = run(["ps", "-o", "ppid=,tty=", "-p", str(pid)]).split()
        if len(out) < 2:
            break
        ppid, tty = out[0], out[1]
        if tty not in ("??", "-"):
            size = run(["stty", "-f", f"/dev/{tty}", "size"]).split()
            if len(size) == 2 and size[1].isdigit():
                return int(size[1])
        pid = ppid
    return 80


def sdd(root):
    best = None
    for f in sorted(Path(root, "phases").glob("*/index.json"), key=lambda p: -p.stat().st_mtime):
        try:
            steps = [s for s in json.loads(f.read_text()).get("steps", []) if s.get("status") != "obsolete"]
        except (OSError, ValueError):
            continue
        left = [s for s in steps if s.get("status") not in ("completed", "done")]
        if left:
            best = (f.parent.name, len(steps) - len(left), len(steps), left[0])
            break
    return best


def last_prompt(tp):
    try:
        with open(tp, "rb") as f:
            end, carry = f.seek(0, os.SEEK_END), b""
            while end > 0:
                start = max(0, end - 1048576)
                f.seek(start)
                lines = (f.read(end - start) + carry).split(b"\n")
                carry = lines.pop(0) if start > 0 else b""
                for ln in reversed(lines):
                    if ln.startswith(b'{"type":"last-prompt"') and b'"lastPrompt":"' in ln:
                        t = (json.loads(ln).get("lastPrompt") or "").strip()
                        if t and not SKIP.match(t):
                            return " ".join(t.split())
                end = start
    except (OSError, ValueError):
        pass
    return ""


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return
    cwd = (data.get("workspace") or {}).get("current_dir") or data.get("cwd") or ""
    root = run(["git", "-C", cwd, "rev-parse", "--show-toplevel"]) if cwd else ""

    track, track_w = "", 30
    if cwd and TRACKS.exists() and CONDUCTOR.exists() and subprocess.run(
            [sys.executable, "-I", str(CONDUCTOR), "is-seat", cwd], capture_output=True).returncode == 0:
        track, track_w = run([sys.executable, "-I", str(TRACKS), "--compact"], cwd=cwd), 48   # 지휘 자리 — 대상 레포마다 한 조각
    elif root and TRACKS.exists() and Path(root, ".claude/references/tracks.md").exists() \
            and run(["git", "-C", root, "rev-parse", "--git-dir"]) == ".git":   # 기준 worktree(지휘 자리)만
        track = run([sys.executable, "-I", str(TRACKS), "--compact"], cwd=root)

    prog = sdd(root) if root else None
    prompt = last_prompt(data.get("transcript_path") or "")

    width = max(30, term_width() - 4)
    task_w, step_w, ask_w = 16, 22, 40
    for _ in range(6):   # 넘치면 줄인다: 요청 → 작업 이름 → 단계 → 요청 빼기
        parts = []
        if track:
            parts.append(("\033[1;35m", clip(track, track_w)))
        if prog:
            task, d, t, step = prog
            name = clip(step.get("name", ""), step_w)
            head = f"SDD {clip(task, task_w)} {d}/{t}" if task_w else f"SDD {d}/{t}"
            stuck = step.get("status") in ("error", "blocked")
            parts.append(("\033[1;31m" if stuck else "\033[36m", f"{'⛔ ' if stuck else ''}{head} ▸ {name}"))
        if prompt and ask_w:
            parts.append(("\033[2m", "💬 " + clip(prompt, ask_w)))
        plain = " · ".join(p for _, p in parts)
        if cols(plain) <= width:
            break
        if ask_w > 16:
            ask_w = 16
        elif task_w:
            task_w = 0
        elif step_w > 12:
            step_w = 12
        else:
            ask_w = 0
    if parts:
        sys.stdout.write(" · ".join(f"{c}{p}\033[0m" for c, p in parts))


main()
