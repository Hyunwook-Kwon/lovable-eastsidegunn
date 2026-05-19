#!/usr/bin/env bash
# 🍙 donggun installer — copies module to ~/.hammerspoon/donggun/ and appends require() line.
# Idempotent: safe to run multiple times. Backs up existing init.lua.
set -euo pipefail

HAMMERSPOON_DIR="$HOME/.hammerspoon"
TARGET_DIR="$HAMMERSPOON_DIR/donggun"
INIT_LUA="$HAMMERSPOON_DIR/init.lua"
REQUIRE_LINE='require("donggun")'
HEADER_COMMENT='-- 🍙 donggun overlay (managed by lovable-eastsidegunn)'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/donggun"

bold()  { printf "\033[1m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }
red()   { printf "\033[31m%s\033[0m\n" "$*"; }

bold "🍙 동건이 데스크탑 오버레이 설치 시작"
echo

# 1. Prerequisites
if [ ! -d "/Applications/Hammerspoon.app" ]; then
  red "❌ Hammerspoon.app 이 /Applications 에 없습니다."
  echo "   설치: https://www.hammerspoon.org/  또는  brew install --cask hammerspoon"
  exit 1
fi
green "✅ Hammerspoon 발견"

if ! command -v python3 >/dev/null 2>&1; then
  red "❌ python3 가 PATH 에 없습니다."
  echo "   xcode-select --install  로 Command Line Tools 설치 후 다시 시도하세요."
  exit 1
fi
green "✅ python3 발견: $(command -v python3)"

# 2. Source dir 확인
if [ ! -d "$SOURCE_DIR" ]; then
  red "❌ 'donggun/' 디렉토리가 install.sh 옆에 없습니다."
  echo "   clone 한 repo 디렉토리에서 ./install.sh 를 실행하세요."
  exit 1
fi

# 3. ~/.hammerspoon 준비
mkdir -p "$HAMMERSPOON_DIR"

# 4. 기존 init.lua 백업 + 기존 donggun-style 코드 감지
BACKUP=""
if [ -f "$INIT_LUA" ]; then
  BACKUP="$INIT_LUA.backup.$(date +%Y%m%d-%H%M%S)"
  cp "$INIT_LUA" "$BACKUP"
  yellow "📦 init.lua 백업 → $BACKUP"

  if ! grep -qF "$REQUIRE_LINE" "$INIT_LUA" && grep -qE "(donggun|🍙)" "$INIT_LUA"; then
    yellow "⚠️  기존 init.lua 에 donggun 관련 코드가 이미 있습니다."
    yellow "   require('donggun') 만 남기고 옛 코드는 정리하는 것을 권장합니다."
    yellow "   이대로 진행하면 webview 가 두 개 뜨거나 :$((8765)) 포트 충돌이 발생할 수 있습니다."
    yellow "   백업이 만들어져 있으니 설치 후 $INIT_LUA 를 편집하세요."
    echo
  fi
fi

# 5. 모듈 복사 (덮어쓰기)
rm -rf "$TARGET_DIR"
cp -R "$SOURCE_DIR" "$TARGET_DIR"
ASSET_COUNT=$(ls "$TARGET_DIR/assets" 2>/dev/null | wc -l | tr -d ' ')
green "✅ 모듈 복사 → $TARGET_DIR (자산 ${ASSET_COUNT}개)"

# 6. require 한 줄 추가 (idempotent)
if [ ! -f "$INIT_LUA" ]; then
  printf '%s\n%s\n' "$HEADER_COMMENT" "$REQUIRE_LINE" > "$INIT_LUA"
  green "✅ 새 init.lua 생성 (require 한 줄)"
elif grep -qF "$REQUIRE_LINE" "$INIT_LUA"; then
  green "✅ require('donggun') 이미 등록됨, skip"
else
  printf '\n%s\n%s\n' "$HEADER_COMMENT" "$REQUIRE_LINE" >> "$INIT_LUA"
  green "✅ init.lua 끝에 require('donggun') 추가"
fi

# 7. Hammerspoon reload (실행 중일 때만)
if pgrep -x Hammerspoon >/dev/null; then
  if open -g "hammerspoon://reload" 2>/dev/null; then
    green "🔄 Hammerspoon reload 트리거"
  else
    yellow "ℹ️  자동 reload 실패. 메뉴바 → Reload Config 를 수동 클릭하세요."
  fi
else
  yellow "ℹ️  Hammerspoon 이 실행 중이 아닙니다. 'open -a Hammerspoon' 으로 시작하세요."
fi

echo
bold "🍙 설치 완료!"
echo
echo "다음 권한을 한 번만 켜주세요 (System Settings → Privacy & Security):"
echo "  • Accessibility   → Hammerspoon ✓   (핫키/드래그)"
echo "  • Microphone      → Hammerspoon ✓   (주변 소음 감지, 옵션)"
echo
echo "핫키:"
echo "  Cmd+Shift+D   동건이 토글"
echo "  Cmd+Shift+R   webview 새로고침"
echo "  Cmd+Shift+H   코너 순환"
echo "  Cmd+Shift+M   마이크 on/off"
echo "  Cmd+Shift+드래그   동건이 자유이동"
echo
[ -n "$BACKUP" ] && echo "기존 init.lua 백업: $BACKUP"
