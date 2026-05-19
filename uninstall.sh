#!/usr/bin/env bash
# 🍙 donggun uninstaller — removes ~/.hammerspoon/donggun/ and the require() line from init.lua.
set -euo pipefail

HAMMERSPOON_DIR="$HOME/.hammerspoon"
TARGET_DIR="$HAMMERSPOON_DIR/donggun"
INIT_LUA="$HAMMERSPOON_DIR/init.lua"

green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }

# 1. donggun 모듈 삭제
if [ -d "$TARGET_DIR" ]; then
  rm -rf "$TARGET_DIR"
  green "✅ 삭제: $TARGET_DIR"
else
  yellow "ℹ️  $TARGET_DIR 가 없음, skip"
fi

# 2. init.lua 에서 require + header 라인 제거
if [ -f "$INIT_LUA" ]; then
  TMP=$(mktemp)
  # 빈 줄이 require 줄 위에 추가됐던 케이스도 같이 정리
  sed \
    -e '/^-- 🍙 donggun overlay (managed by lovable-eastsidegunn)$/d' \
    -e '/^require("donggun")$/d' \
    "$INIT_LUA" > "$TMP"

  if ! cmp -s "$INIT_LUA" "$TMP"; then
    BACKUP="$INIT_LUA.uninstall-backup.$(date +%Y%m%d-%H%M%S)"
    cp "$INIT_LUA" "$BACKUP"
    mv "$TMP" "$INIT_LUA"
    green "✅ init.lua 에서 require('donggun') 제거 (백업: $BACKUP)"
  else
    rm "$TMP"
    yellow "ℹ️  init.lua 에 donggun reference 없음, skip"
  fi
fi

# 3. Hammerspoon reload
if pgrep -x Hammerspoon >/dev/null; then
  open -g "hammerspoon://reload" 2>/dev/null || true
  green "🔄 Hammerspoon reload 트리거"
fi

echo
echo "🍙 동건이 작별. (Hammerspoon.app 은 그대로)"
