#!/usr/bin/env bash
# Claude Code 사용자 환경 양방향 동기화.
#   ./sync.sh          이 맥 → 레포(export) → 변경 없으면 pull → 레포 → 이 맥(import)
#   ./sync.sh --first  새 맥 첫 설치. export 를 건너뛰고 받기만 한다
# 레포에 넣는 범위·이유는 README.md 참고.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
FIRST=0
[ "${1-}" = "--first" ] && FIRST=1
C="$HOME/.claude"
A="$HOME/.agents"
CCS="$HOME/.config/ccstatusline"
STATUS_SCRIPTS="statusline-5hr-segment.sh statusline-skill-hints.sh"   # ccstatusline custom-command 가 부르는 스크립트
MY_SKILL_SKIP="synced aside-browser"   # 계정 동기화 · Aside 앱 관리 → 옮기지 않음

die() { echo "✋ $*" >&2; exit 1; }

# ── 1. 도구 확인 ─────────────────────────────────────────────
missing=()
for t in git python3 jq bun ccstatusline claude; do
  command -v "$t" >/dev/null 2>&1 || missing+=("$t")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "필요한 도구가 없습니다: ${missing[*]}"
  echo "  brew install jq oven-sh/bun/bun"
  echo "  bun add -g ccstatusline@2.2.19"
  echo "  Claude Code: https://code.claude.com/docs/en/setup"
  exit 1
fi

# settings.json 처리는 python 한 곳에서 한다. 모드: export | import
settings_py() {
  python3 -I - "$@" <<'PY'
import json, os, sys, re

mode, repo = sys.argv[1], sys.argv[2]
home = os.environ["HOME"]
C = os.path.join(home, ".claude")
CCS = os.path.join(home, ".config", "ccstatusline", "settings.json")
CJ = os.path.join(home, ".claude.json")

# 레포에 넣는 settings.json 키 (허용 목록). 이 밖의 키는 각 맥에 그대로 남는다
KEEP = ["model", "effortLevel", "modelSettings", "tui", "statusLine", "hooks",
        "enabledPlugins", "extraKnownMarketplaces", "permissions",
        "includeCoAuthoredBy", "inputNeededNotifEnabled", "agentPushNotifEnabled", "outputStyle"]
SENSITIVE = ["hooks", "permissions", "enabledPlugins", "extraKnownMarketplaces"]

def load(p, default=None):
    try:
        with open(p) as f:
            return json.load(f)
    except FileNotFoundError:
        return default

def dump(p, obj):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w") as f:
        f.write(json.dumps(obj, indent=2, ensure_ascii=False, sort_keys=True) + "\n")

def walk(obj, fn):
    if isinstance(obj, dict):
        return {k: walk(v, fn) for k, v in obj.items()}
    if isinstance(obj, list):
        return [walk(v, fn) for v in obj]
    return fn(obj) if isinstance(obj, str) else obj

home_re = re.compile(re.escape(home) + r"(?=/|$)")
to_ph = lambda o: walk(o, lambda s: home_re.sub("__HOME__", s))
from_ph = lambda o: walk(o, lambda s: s.replace("__HOME__", home))

def is_orca(h):
    return "ORCA_AGENT_HOOK" in h.get("command", "")

def split_hooks(hooks):
    """hooks 를 (Orca 제외분, Orca 분) 으로 나눈다. 빈 묶음·이벤트는 지운다"""
    mine, orca = {}, {}
    for ev, groups in (hooks or {}).items():
        for g in groups:
            for bucket, keep in ((mine, lambda h: not is_orca(h)), (orca, is_orca)):
                hs = [h for h in g.get("hooks", []) if keep(h)]
                if hs:
                    bucket.setdefault(ev, []).append({**g, "hooks": hs})
    return mine, orca

if mode == "export":
    s = load(os.path.join(C, "settings.json"), {})
    out = {k: s[k] for k in KEEP if k in s}
    if "hooks" in out:
        out["hooks"], _ = split_hooks(out["hooks"])
    dump(os.path.join(repo, "claude/settings.json"), to_ph(out))
    if os.path.exists(CCS):
        dump(os.path.join(repo, "ccstatusline/settings.json"), to_ph(load(CCS)))
    mcp = (load(CJ, {}) or {}).get("mcpServers", {})
    dump(os.path.join(repo, "claude/mcp-servers.json"), to_ph(mcp))

elif mode == "import":
    # 결과를 .pending/ 에 쓰고, 민감 키가 바뀌었으면 그 목록을 남긴다. 적용은 bash 가 확인 뒤 한다
    pend = os.path.join(repo, ".pending")
    os.makedirs(pend, exist_ok=True)
    r = from_ph(load(os.path.join(repo, "claude/settings.json"), {}))
    local = load(os.path.join(C, "settings.json"), {}) or {}
    l_mine, l_orca = split_hooks(local.get("hooks"))
    changed = []
    for k in SENSITIVE:
        before = l_mine if k == "hooks" else local.get(k)
        if (before or None) != (r.get(k) or None):
            changed.append(k)
            print(f"── {k} 변경 ──")
            print("  지금:", json.dumps(before, ensure_ascii=False, sort_keys=True)[:1500])
            print("  레포:", json.dumps(r.get(k), ensure_ascii=False, sort_keys=True)[:1500])
    new = dict(local)
    for k in KEEP:
        if k in r:
            new[k] = r[k]
    hooks = dict(r.get("hooks", {}))
    for ev, groups in l_orca.items():          # 이 맥의 Orca 훅은 그대로 붙여 둔다
        hooks[ev] = hooks.get(ev, []) + groups
    if hooks:
        new["hooks"] = hooks
    with open(os.path.join(pend, "settings.json"), "w") as f:
        f.write(json.dumps(new, indent=2, ensure_ascii=False) + "\n")

    rc = os.path.join(repo, "ccstatusline/settings.json")
    if os.path.exists(rc):
        rcs = from_ph(load(rc))
        if load(CCS) != rcs:
            changed.append("ccstatusline")
            print("── ccstatusline 위젯 변경 ──")
        dump(os.path.join(pend, "ccstatusline.json"), rcs)

    # MCP: 이 맥에 없는 서버만 등록 대상. 이미 있는데 다르면 알리기만 한다
    rm = from_ph(load(os.path.join(repo, "claude/mcp-servers.json"), {}))
    lm = (load(CJ, {}) or {}).get("mcpServers", {})
    with open(os.path.join(pend, "mcp-add.tsv"), "w") as f:
        for name, cfg in rm.items():
            if name not in lm:
                changed.append("mcp:" + name)
                print(f"── MCP 서버 추가: {name} ──\n  ", json.dumps(cfg, ensure_ascii=False))
                f.write(name + "\t" + json.dumps(cfg, ensure_ascii=False) + "\n")
            elif lm[name] != cfg:
                print(f"⚠️  MCP {name} 설정이 레포와 다릅니다. 손으로 확인하세요(자동 변경 안 함)")
    with open(os.path.join(pend, "changed"), "w") as f:
        f.write("".join(c + "\n" for c in changed))
PY
}

# ── 2. export ───────────────────────────────────────────────
if [ $FIRST -eq 0 ]; then
  settings_py export "$REPO"
  cp "$C/CLAUDE.md" "$REPO/claude/CLAUDE.md"
  for s in $STATUS_SCRIPTS; do cp "$C/$s" "$REPO/claude/$s"; done
  rm -rf "$REPO/claude/output-styles"
  [ -d "$C/output-styles" ] && cp -R "$C/output-styles" "$REPO/claude/output-styles"
  rm -rf "$REPO/claude/skills" && mkdir -p "$REPO/claude/skills"
  for d in "$C"/skills/*/; do
    n="$(basename "$d")"
    [ -L "${d%/}" ] && continue                         # npx skills 링크는 agents/ 쪽으로
    case " $MY_SKILL_SKIP " in *" $n "*) continue ;; esac
    cp -R "${d%/}" "$REPO/claude/skills/$n"
  done
  rm -rf "$REPO/agents" && mkdir -p "$REPO/agents"
  cp -R "$A/skills" "$REPO/agents/skills"
  [ -f "$A/.skill-lock.json" ] && cp "$A/.skill-lock.json" "$REPO/agents/skill-lock.json"
  find "$REPO" -name .DS_Store -not -path "*/.git/*" -delete

  # 비밀값·회사 식별자 검사 (실제 키 모양만)
  pat='sk-ant-|ghp_|github_pat_|gho_|AKIA[0-9A-Z]{16}|xox[abp]-|PRIVATE KEY|sellermill|viewus\.co\.kr'
  if hits="$(grep -rEn "$pat" "$REPO" --exclude-dir=.git --exclude-dir=.pending --exclude=sync.sh --exclude=README.md)"; then
    echo "$hits" | cut -c1-200
    die "비밀값 또는 회사 식별자로 보이는 문자열이 있습니다. 위 파일을 확인한 뒤 다시 실행하세요"
  fi
fi

# ── 3. 변경 검사 ─────────────────────────────────────────────
cd "$REPO"
if [ -n "$(git status --porcelain -- . ':!.pending')" ]; then
  git status --short -- . ':!.pending'
  die "이 맥의 변경이 레포에 반영됐습니다. git diff 로 확인 → commit·push 후 다시 ./sync.sh"
fi

# ── 4. pull ─────────────────────────────────────────────────
if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  git pull --rebase --ff-only --quiet || die "pull 실패. 충돌을 해결한 뒤 다시 실행하세요"
else
  echo "ℹ️  upstream 이 없어 pull 을 건너뜁니다"
fi

# ── 5. import ───────────────────────────────────────────────
for f in "$C/settings.json" "$CCS/settings.json" "$C/CLAUDE.md"; do
  [ -L "$f" ] && die "$f 가 심볼릭 링크입니다. 이 스크립트는 복사 방식만 지원합니다"
done

settings_py import "$REPO"
P="$REPO/.pending"
for s in $STATUS_SCRIPTS; do
  cmp -s "$REPO/claude/$s" "$C/$s" 2>/dev/null \
    || { echo "── $s 변경 ──"; echo "$s" >> "$P/changed"; }
done

if [ -s "$P/changed" ]; then
  echo
  echo "위 항목(실행되는 설정)이 바뀝니다: $(tr '\n' ' ' < "$P/changed")"
  read -r -p "적용할까요? [y/N] " ans < /dev/tty
  [ "$ans" = "y" ] || { rm -rf "$P"; die "취소했습니다. 이 맥은 그대로입니다"; }
fi

BK="$C/backups/dotfiles-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK" && chmod 700 "$BK"
for f in "$C/settings.json" "$CCS/settings.json" "$C/CLAUDE.md" $(for s in $STATUS_SCRIPTS; do printf '%s ' "$C/$s"; done); do
  [ -f "$f" ] && cp "$f" "$BK/" || true
done

mkdir -p "$C/skills" "$CCS" "$A/skills"
cp "$P/settings.json" "$C/settings.json"
[ -f "$P/ccstatusline.json" ] && cp "$P/ccstatusline.json" "$CCS/settings.json"
cp "$REPO/claude/CLAUDE.md" "$C/CLAUDE.md"
[ -d "$REPO/claude/output-styles" ] && mkdir -p "$C/output-styles" && cp "$REPO"/claude/output-styles/*.md "$C/output-styles/"
for s in $STATUS_SCRIPTS; do
  cp "$REPO/claude/$s" "$C/$s" && chmod +x "$C/$s"
done

for d in "$REPO"/claude/skills/*/; do
  n="$(basename "$d")"
  rm -rf "$C/skills/$n" && cp -R "${d%/}" "$C/skills/$n"
done
for d in "$REPO"/agents/skills/*/; do
  n="$(basename "$d")"
  rm -rf "$A/skills/$n" && cp -R "${d%/}" "$A/skills/$n"
  [ -e "$C/skills/$n" ] || ln -s "../../.agents/skills/$n" "$C/skills/$n"   # 이미 실폴더면 그쪽이 정본
done
[ -f "$REPO/agents/skill-lock.json" ] && cp "$REPO/agents/skill-lock.json" "$A/.skill-lock.json"

while IFS=$'\t' read -r name cfg; do
  [ -n "$name" ] && claude mcp add-json --scope user "$name" "$cfg"
done < "$P/mcp-add.tsv"

if grep -rqs "__HOME__" "$C/settings.json" "$CCS/settings.json"; then
  die "__HOME__ 자리표시가 남았습니다. 백업: $BK"
fi
rm -rf "$P"

# ── 6. 안내 ─────────────────────────────────────────────────
echo "✅ 완료 (백업: $BK)"
echo "   1) Claude Code 를 재시작하세요. 플러그인은 첫 세션에서 자동으로 받습니다(안 보이면 /reload-plugins)"
echo "   2) /status 로 설정 출처를 확인하세요. 회사 managed 정책이 있으면 일부 키는 그쪽이 이깁니다"
