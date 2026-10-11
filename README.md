# claude-dotfiles

내 맥의 Claude Code 환경을 다른 맥에서도 그대로 쓰기 위한 레포다. 명령은 `./sync.sh` 하나다.

## 세 레포의 관계

```
새 맥       claude-dotfiles  ./sync.sh  →  ~/.claude 설정 + 플러그인 자동 설치(claude-harness 포함)
새 프로젝트  /project-new  →  stack-kits 코드 뼈대(degit)  →  /harness-init
기존 레포    /harness-init
```

| 레포 | 맡는 것 | 어디에 남나 | |
|---|---|---|---|
| [claude-dotfiles](https://github.com/jtwjs/claude-dotfiles) | 내 맥의 Claude Code 환경: 전역 CLAUDE.md, 상태줄, 플러그인 목록, 개인 스킬 | `~/.claude/` | 📍 지금 여기 |
| [claude-harness](https://github.com/jtwjs/claude-harness) | 레포에서 AI와 일하는 방식: 스킬, 에이전트, 훅, 템플릿 | 플러그인 + 각 레포의 `.claude/`·`_brain/` | |
| [stack-kits](https://github.com/jtwjs/stack-kits) | 새 프로젝트의 코드 뼈대: kotlin-spring, nextjs, fullstack | 새 레포의 코드 | |

## 빠른 시작

새 맥에서 Claude Code를 설치하고 한 번 로그인한 뒤([설치 방법](https://code.claude.com/docs/en/setup)) 실행한다.

```bash
brew install jq oven-sh/bun/bun
bun add -g ccstatusline@2.2.19
curl -fsSL https://plannotator.ai/install.sh -o /tmp/pn-install.sh && bash /tmp/pn-install.sh --minimal --verify-attestation   # plannotator 바이너리만(훅·설정은 플러그인이 맡는다)
git clone https://github.com/jtwjs/claude-dotfiles.git ~/orca/claude-dotfiles
cd ~/orca/claude-dotfiles && ./sync.sh --first
```

## 무엇이 들었나

| 옮기는 것 | 레포 위치 |
|---|---|
| 상태줄(모델·컨텍스트·사용량·브랜치·스킬 권고) | `ccstatusline/settings.json`, `claude/statusline-*.sh` |
| 모델·effort, 전체 화면 TUI, 알림 토글, 미리 허용한 명령, 알림음 훅 | `claude/settings.json` |
| 플러그인 5개: claude-harness, karpathy-skills, understand-anything, claude-md-management, plannotator | `claude/settings.json` |
| 전역 `CLAUDE.md` | `claude/CLAUDE.md` |
| 내 스킬 4개: grill-me(→ `claude-harness:why-plan` 스텁), notion-writing, slack-writing, redesign-existing-projects | `claude/skills/` |
| `npx skills`로 받은 스킬 20개(같은 이름이면 내 스킬이 우선) | `agents/skills/` |
| MCP 서버 context7 | `claude/mcp-servers.json` |

옮기지 않는 것: autoMode 규칙(회사 정보 포함), Orca 터미널 훅(Orca가 넣는다), aside-browser 스킬(Aside 앱 관리), 로그인·대화 기록·메모리·캐시, claude.ai 커넥터와 동기화 스킬(계정에 따라온다), 아래 키 3개.

확인 생략 키 3개 `skipDangerousModePermissionPrompt`, `skipAutoPermissionPrompt`, `remoteControlAtStartup`는 필요하면 새 맥의 `~/.claude/settings.json`에 직접 넣는다.

## 어떻게 도나

```
./sync.sh
  이 맥 → 레포로 내보낸다. 변경이 생겼나?
    예     → 멈춘다. git diff 확인 → commit·push → 다시 ./sync.sh
    아니오 → git pull → 이 맥에 적용 → Claude Code 재시작
```

`--first`는 내보내기를 건너뛰고 받기만 한다. 재시작 후 플러그인이 안 보이면 `/reload-plugins`, 설정 출처는 `/status`로 본다.

## 원칙·안전장치

- 비밀값(API 키·토큰 모양)이나 회사 식별자가 보이면 `sync.sh`가 멈춘다.
- `.gitignore` 허용 목록에 있는 것만 올라간다.
- 훅·권한·플러그인·상태줄·MCP가 바뀌면 diff를 보여 주고 [y/N] 확인 뒤에만 적용한다.
- 적용 전 원래 파일을 `~/.claude/backups/dotfiles-날짜/`에 백업한다.
- 홈 경로는 `__HOME__`으로 저장해 사용자 이름이 다른 맥에서도 맞는다.

## 관리자용

- 첫 적용 뒤 Claude Code가 설정 형식을 바꿔(예: `opus` → `opus[1m]`) 다음 `./sync.sh`가 멈출 수 있다. 버릴 거면 `git checkout -- .`, 맞으면 commit·push 한다.
- 상태줄 스크립트를 추가하면 `sync.sh`의 `STATUS_SCRIPTS`에도 넣는다.
