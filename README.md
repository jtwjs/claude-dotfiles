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

새 맥에서 처음 적용할 때다. Claude Code가 없으면 먼저 설치하고 한 번 로그인한다([설치 방법](https://code.claude.com/docs/en/setup)).

```bash
brew install jq oven-sh/bun/bun
bun add -g ccstatusline@2.2.19
curl -fsSL https://plannotator.ai/install.sh -o /tmp/pn-install.sh && bash /tmp/pn-install.sh --minimal --verify-attestation   # plannotator 바이너리만(훅·설정은 플러그인이 맡는다)
git clone https://github.com/jtwjs/claude-dotfiles.git ~/orca/claude-dotfiles
cd ~/orca/claude-dotfiles && ./sync.sh --first
```

그다음 Claude Code를 재시작한다. 플러그인은 첫 세션에서 자동으로 내려받고, 안 보이면 `/reload-plugins`를 입력한다. `/status`로 설정이 어디서 왔는지 확인한 뒤, 아래 「새 맥에서 직접 켜야 하는 것」을 필요한 만큼 켠다.

## 무엇이 들었나

### 옮기는 것

| 무엇 | 설명 | 레포 위치 |
|---|---|---|
| 상태줄 | 화면 맨 아래 세 줄: 모델, 컨텍스트 %, 5시간 사용률, 주간 사용량, 브랜치, git 변경, claude-harness가 권하는 스킬(노란 배경, 권고가 있을 때만) | `ccstatusline/settings.json`, `claude/statusline-5hr-segment.sh`, `claude/statusline-skill-hints.sh` |
| 모델·사고 강도 | 기본 모델과 effort 설정 | `claude/settings.json` |
| 화면 모드 | 전체 화면(fullscreen) TUI | `claude/settings.json` |
| 알림음 | 작업이 끝나면 Funk, 입력이 필요하면 Glass | `claude/settings.json`의 hooks |
| 알림 토글 | 입력 대기 알림, 에이전트 푸시 알림 | `claude/settings.json` |
| 미리 허용한 명령 | 묻지 않고 실행할 명령 목록(git, gh, pnpm 등) | `claude/settings.json`의 permissions |
| 플러그인 5개 | claude-harness, karpathy-skills, understand-anything, claude-md-management, plannotator(계획 승인을 브라우저 검토로, 바이너리는 빠른 시작에서 설치)와 각 마켓플레이스 | `claude/settings.json`(재시작하면 자동 설치) |
| 전역 지침 | 모든 프로젝트에 적용되는 `CLAUDE.md`(한국어 격식체, 코딩 규율 등) | `claude/CLAUDE.md` |
| 내가 만든·고친 스킬 4개 | grill-me(claude-harness의 why-plan을 부른다), notion-writing, slack-writing, redesign-existing-projects | `claude/skills/` |
| 설치한 스킬 20개 | `npx skills`로 받은 디자인·백엔드 스킬. 받은 그 버전 그대로(redesign-existing-projects는 내가 고친 본이 우선) | `agents/skills/` |
| MCP 서버 | context7(라이브러리 문서 조회) | `claude/mcp-servers.json` |

### 옮기지 않는 것 (일부러)

| 무엇 | 이유 |
|---|---|
| 자동 모드(autoMode) 규칙 | 회사 조직·도메인 정보가 들어 있어 이 레포에 두지 않는다. 새 맥에서 따로 설정한다 |
| 위험 확인 생략 토글 3개 | 아래 「새 맥에서 직접 켜야 하는 것」 참고 |
| Orca 터미널 훅 | Orca 앱을 설치하면 Orca가 넣는다 |
| aside-browser 스킬 | Aside 앱이 관리한다 |
| 로그인 정보, 대화 기록, 프로젝트 메모리, 캐시 | 기기마다 따로다 |
| claude.ai 커넥터(Slack 등), 동기화 스킬 | 같은 계정으로 로그인하면 따라온다 |

### 새 맥에서 직접 켜야 하는 것

확인 단계를 없애는 설정이라 기기마다 직접 켜게 했다. 필요하면 `~/.claude/settings.json`에 추가한다.

| 키 | 하는 일 |
|---|---|
| `skipDangerousModePermissionPrompt` | 위험 모드에 들어갈 때 확인을 묻지 않음 |
| `skipAutoPermissionPrompt` | 자동 모드에 들어갈 때 확인을 묻지 않음 |
| `remoteControlAtStartup` | 시작할 때 원격 제어를 켬 |

## 어떻게 도나

```
./sync.sh
  이 맥에 커밋 안 된 변경이 있나?
    예   → 멈추고 알린다. git diff 확인 → commit·push → 다시 ./sync.sh
    아니오 → git pull → 이 맥에 적용(훅·권한·플러그인이 바뀌면 diff를 보여 주고 [y/N]) → 재시작
```

- 순서를 이렇게 정해 두어서, 받는 쪽에서 아직 올리지 않은 변경이 말없이 덮어써지지 않는다.
- 적용할 때 원래 파일은 `~/.claude/backups/dotfiles-날짜/`에 백업한다.
- 경로는 `__HOME__`으로 저장했다가 적용할 때 그 맥의 홈 폴더로 바꾼다. 사용자 이름이 다른 맥이어도 된다.

## 원칙·안전장치

- 비밀값(API 키·토큰 모양)이나 회사 식별자가 레포에 들어가려 하면 `sync.sh`가 멈춘다.
- `.gitignore`가 정해진 폴더만 올리도록 막는다.
- 명령이 실행되는 설정(훅·권한·플러그인)은 바뀐 내용을 보여 주고 확인을 받은 뒤에만 적용한다.

## 관리자용

- 평소에는 어느 맥에서든 `cd ~/orca/claude-dotfiles && ./sync.sh` 하나로 맞춘다. 적용한 뒤에는 Claude Code를 재시작한다.
- 새 맥에서 처음 실행하면 Claude Code가 설정을 자기 형식으로 한 번 바꿀 수 있다(예: 모델 이름 `opus` → `opus[1m]`). 그래서 첫 `./sync.sh`가 "변경이 있다"며 멈출 수 있다. `git diff`로 보고, 그대로 둘 거면 `git checkout -- .` 후 다시 `./sync.sh`, 저쪽 값이 맞으면 commit·push 한다.
- 상태줄 스크립트를 새로 추가하면 `sync.sh`의 `STATUS_SCRIPTS` 목록에도 넣는다.
