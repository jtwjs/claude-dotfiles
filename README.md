# claude-dotfiles

내 맥의 Claude Code 환경을 다른 맥에서도 그대로 쓰기 위한 비공개 레포입니다.
명령은 `./sync.sh` 하나입니다.

---

## 새 맥에 처음 적용하기 (5분)

### 1. 필요한 도구 설치

터미널에 그대로 붙여 넣습니다.

```bash
brew install jq oven-sh/bun/bun
bun add -g ccstatusline@2.2.19
```

Claude Code가 아직 없다면 먼저 설치하고 한 번 로그인합니다. 설치 방법: https://code.claude.com/docs/en/setup

### 2. 레포 받기

```bash
gh auth login            # jtwjs 계정으로 (비공개 레포라 필요)
git clone https://github.com/jtwjs/claude-dotfiles.git ~/orca/claude-dotfiles
cd ~/orca/claude-dotfiles
```

### 3. 적용

```bash
./sync.sh --first
```

- 훅·권한·플러그인처럼 **명령이 실행되는 설정**이 바뀌면, 바뀌는 내용을 보여 주고 `적용할까요? [y/N]`를 묻습니다. 내용을 확인한 뒤 `y`를 누릅니다.
- 원래 있던 파일은 `~/.claude/backups/dotfiles-날짜/`에 백업됩니다.

### 4. 마무리

1. Claude Code를 **재시작**합니다. 플러그인은 첫 세션에서 자동으로 내려받습니다. 안 보이면 `/reload-plugins`를 입력합니다.
2. `/status`로 설정이 어디서 왔는지 확인합니다.
3. 아래 「새 맥에서 직접 켜야 하는 것」을 필요한 만큼 켭니다.

> 💡 새 맥에서 처음 실행하면 Claude Code가 설정을 자기 형식으로 한 번 바꿀 수 있습니다(예: 모델 이름 `opus` → `opus[1m]`). 그래서 첫 `./sync.sh`에서 "변경이 있다"며 멈출 수 있습니다. `git diff`로 보고 그대로 둘 거면 `git checkout -- .` 후 다시 `./sync.sh`, 저쪽 값이 맞으면 commit·push 하면 됩니다.

---

## 무엇이 옮겨지나

| 무엇 | 쉽게 말하면 | 레포 위치 |
|---|---|---|
| **상태줄** | 화면 맨 아래 세 줄. 모델, 컨텍스트 %, 5시간 사용률, 주간 사용량, 브랜치, git 변경, 그리고 claude-harness가 권하는 스킬(노란 배경, 권고가 있을 때만) | `ccstatusline/settings.json` · `claude/statusline-5hr-segment.sh` · `claude/statusline-skill-hints.sh` |
| **모델·사고 강도** | 기본 모델과 effort 설정 | `claude/settings.json` |
| **화면 모드** | 전체 화면(fullscreen) TUI | `claude/settings.json` |
| **알림음** | 작업이 끝나면 Funk 소리, 입력이 필요하면 Glass 소리 | `claude/settings.json`의 hooks |
| **알림 토글** | 입력 대기 알림, 에이전트 푸시 알림 | `claude/settings.json` |
| **미리 허용한 명령** | 묻지 않고 실행할 명령 목록(git·gh·pnpm 등) | `claude/settings.json`의 permissions |
| **플러그인** | claude-harness, karpathy, understand-anything, claude-md-management, 그리고 각 마켓플레이스 | `claude/settings.json` (재시작하면 자동 설치) |
| **전역 지침** | 모든 프로젝트에 적용되는 `CLAUDE.md` (한국어 격식체, 코딩 규율 등) | `claude/CLAUDE.md` |
| **내가 만든·고친 스킬** | grill-me · notion-writing · slack-writing · redesign-existing-projects | `claude/skills/` |
| **설치한 스킬 20개** | `npx skills`로 받은 디자인·백엔드 스킬들. 받은 그 버전 그대로(redesign-existing-projects는 내가 고친 본이 우선) | `agents/skills/` |
| **MCP 서버** | context7 (라이브러리 문서 조회) | `claude/mcp-servers.json` |

## 옮기지 않는 것 (일부러)

| 무엇 | 이유 |
|---|---|
| 자동 모드(autoMode) 규칙 | 회사 조직·도메인 정보가 들어 있어 개인 레포에 두지 않습니다. 새 맥에서 따로 설정합니다 |
| 위험 확인 생략 토글 3개 | 아래 「직접 켜야 하는 것」 참고 |
| Orca 터미널 훅 | Orca 앱을 설치하면 Orca가 알아서 넣습니다 |
| aside-browser 스킬 | Aside 앱이 관리합니다 |
| 로그인 정보, 대화 기록, 프로젝트 메모리, 캐시 | 기기마다 따로입니다 |
| claude.ai 커넥터(Slack 등), 동기화 스킬 | 같은 계정으로 로그인하면 자동으로 따라옵니다 |

## 새 맥에서 직접 켜야 하는 것

확인 단계를 없애는 설정이라 기기마다 직접 켜게 했습니다. 필요하면 `~/.claude/settings.json`에 추가합니다.

| 키 | 하는 일 |
|---|---|
| `skipDangerousModePermissionPrompt` | 위험 모드에 들어갈 때 확인을 묻지 않음 |
| `skipAutoPermissionPrompt` | 자동 모드에 들어갈 때 확인을 묻지 않음 |
| `remoteControlAtStartup` | 시작할 때 원격 제어를 켬 |

---

## 평소에 맞추기 (두 맥 모두 같은 방법)

어느 맥에서든 설정을 바꿨거나 다른 맥의 변경을 받고 싶으면 실행합니다.

```bash
cd ~/orca/claude-dotfiles && ./sync.sh
```

- **이 맥에 바뀐 게 있으면** 멈추고 알려 줍니다. `git diff`로 확인한 뒤 commit·push하고 다시 `./sync.sh`를 실행합니다.
- **바뀐 게 없으면** 레포의 최신 내용을 받아 이 맥에 적용합니다. 적용한 뒤에는 Claude Code를 재시작합니다.

이렇게 순서를 정해 두어서, 받는 쪽에서 아직 올리지 않은 변경이 말없이 덮어써지는 일이 없습니다.

## 안전장치

- 비밀값(API 키·토큰 모양)이나 회사 식별자가 레포에 들어가려 하면 멈춥니다.
- `.gitignore`가 정해진 폴더만 올리도록 막아 둡니다.
- 사용자 이름이 다른 맥이어도 됩니다. 경로는 `__HOME__`으로 저장했다가 적용할 때 그 맥의 홈 폴더로 바꿉니다.
