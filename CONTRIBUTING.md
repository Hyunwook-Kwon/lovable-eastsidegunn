# 🤝 기여 가이드

> 동건이에게 새 음식 먹이고 싶거나, 이상한 행동 잡고 싶으면 여기서 시작.

---

## 🚀 개발 환경 준비

```bash
# 1. Prerequisites
brew install --cask hammerspoon   # 없으면
xcode-select --install            # python3 없으면

# 2. Clone + install
git clone https://github.com/Hyunwook-Kwon/lovable-eastsidegunn.git
cd lovable-eastsidegunn
./install.sh                      # ~/.hammerspoon/donggun/ 에 깔림

# 3. 변경 후 reload
# - donggun.html 만 바꿨으면:  화면 위 동건이에서 Cmd+Shift+R
# - init.lua 도 바꿨으면:      Hammerspoon 메뉴바 → Reload Config
```

자세한 reload 매트릭스는 [AGENTS.md §3](AGENTS.md#3-how-to-test-changes) 참고.

---

## 🍱 새 음식 추가하기

가장 흔한 PR. 스프라이트 4장과 코드 한 줄이면 끝.

자세한 단계는 [AGENTS.md → Extension recipes](AGENTS.md#7-extension-recipes) 에 정리되어 있습니다. 요약:

1. `donggun/assets/` 에 음식 스프라이트 4장 추가
   - `donggun_v5_{음식}.png` (eating)
   - `donggun_v5_{음식}_pause_mid1.png`
   - `donggun_v5_{음식}_pause_mid2.png`
   - `donggun_v5_{음식}_paused.png`
2. `donggun/donggun.html` 의 `FOODS` 배열에 항목 추가
3. webview 에서 `Cmd+Shift+R`

스프라이트는 **1024×1024 RGBA PNG**, `image-rendering: pixelated` 가 켜져 있으므로 픽셀아트 스타일 유지 권장.

---

## 🐛 버그 제보

[GitHub Issues](https://github.com/Hyunwook-Kwon/lovable-eastsidegunn/issues/new/choose) 에서 **🐛 버그 리포트** 템플릿 사용. 다음만 채워주시면 디버깅 빨라집니다:

- macOS 버전
- Hammerspoon 버전 (메뉴바 → About Hammerspoon)
- Hammerspoon 콘솔 로그 (메뉴바 → Console)
- 재현 방법

---

## ✅ 코딩 컨벤션

| 영역 | 스타일 |
|---|---|
| Lua | 4-space indent, snake_case, `local` first |
| JS/HTML/CSS | 2-space indent, camelCase, `const` first |
| Bash | 2-space indent, `set -euo pipefail` |
| 주석 | 한국어 OK — "**왜** 이렇게 했는지" 적는 게 핵심 |

전체 규칙은 [AGENTS.md §4](AGENTS.md#4-coding-conventions) 참고. `.editorconfig` 가 들여쓰기 규칙을 자동으로 강제합니다.

---

## 🚫 절대 건드리지 말 것

- `donggun` Lua 전역 변수 (라이브 디버깅용)
- `WORK_DIR = scriptDir()` 의 동적 경로 탐지
- 비대칭 smoothing (`SMOOTH_UP` vs `SMOOTH_DN`) 과 `PAUSED_HANG_MS` — 캐릭터의 영혼
- 스프라이트 파일명 규칙 (`donggun_v5_{food}[_pause_mid{1,2}|_paused].png`)
- `image-rendering: pixelated` 제거

자세한 건 [AGENTS.md §8 Do not](AGENTS.md#8-do-not).

---

## 📬 PR 제출

- 커밋 메시지는 한국어/영어 모두 OK
- PR 본문에 "어떤 음식 / 어떤 버그 / 어떤 변경" 한 줄로 충분
- CI 가 없으니 본인 환경에서 `./install.sh` 한 번 돌려 검증 후 제출 부탁

응답이 다소 늦을 수 있습니다 (개인 프로젝트). 그래도 PR 환영 🙏
