-- 🍙 동건이 데스크탑 오버레이 (Hammerspoon)
-- repo:  https://github.com/Hyunwook-Kwon/lovable-eastsidegunn
-- entry: ~/.hammerspoon/init.lua  →  require("donggun")
--
-- 화면 코너에 투명 webview로 동건이를 항상 위에 띄움.
-- 마이크가 켜져 있으면 주변 소음 4단계로 굳어가다가 조용해지면 천천히 다시 먹기.
--
-- 핫키:
--   Cmd+Shift+D  → 보이기/숨기기 토글
--   Cmd+Shift+R  → 새로고침 (donggun.html 수정 후 즉시 반영)
--   Cmd+Shift+H  → 다른 코너로 이동 (우하 → 좌하 → 좌상 → 우상 → 다시 우하)
--   Cmd+Shift+M  → 마이크 켜기/끄기 (Zoom/Discord 시작 전 끄기 용도)
--   Cmd+Shift+드래그 → 동건이를 마우스로 잡고 끌어서 원하는 위치로 이동

-- IPC + AppleScript 활성화 (터미널 자동화 + osascript reload 지원)
require("hs.ipc")
hs.allowAppleScript(true)

-- ===== 자기 위치 동적 탐지 =====
-- 어디에 설치돼도 (~/.hammerspoon/donggun/, dotfiles, custom path …) 자동으로 자기 디렉토리 찾음.
-- Python http.server가 이 디렉토리를 root로 띄우고, donggun.html은 거기서 assets/*.png 참조.
local function scriptDir()
    local src = debug.getinfo(1, "S").source
    if src:sub(1, 1) == "@" then src = src:sub(2) end
    return src:match("(.*/)") or (hs.configdir .. "/donggun/")
end

-- ===== 설정 =====
local PORT       = 8765
local WORK_DIR   = scriptDir()    -- 동적: 보통 ~/.hammerspoon/donggun/
local OVERLAY_W  = 360
local OVERLAY_H  = 360
local MARGIN     = 20    -- 화면 가장자리 여백
local MARGIN_B   = 60    -- 하단은 Dock 피해서 좀 더

-- ===== 로컬 웹서버 (마이크는 file:// 에서 막힘, http://127.0.0.1 필요) =====
-- 포트 사용 중이면 기존 서버 재사용 (Hammerspoon reload 시 EADDRINUSE 방지)
local portCheck = hs.execute("lsof -ti:" .. PORT .. " 2>/dev/null")
local portInUse = portCheck and portCheck:match("%d+") ~= nil

local server = nil
if not portInUse then
    server = hs.task.new(
        "/usr/bin/python3",
        function(exitCode, _, _)
            print("🍙 동건이 서버 종료 exit=" .. tostring(exitCode))
        end,
        {"-m", "http.server", tostring(PORT), "--bind", "127.0.0.1"}
    )
    server:setWorkingDirectory(WORK_DIR)
    server:start()
    print("🍙 새 서버 시작: 127.0.0.1:" .. PORT .. " (root=" .. WORK_DIR .. ")")
else
    print("🍙 기존 서버 재사용: 127.0.0.1:" .. PORT)
end

-- ===== Webview 위치 계산 =====
local CORNERS = {"br", "bl", "tl", "tr"}  -- bottom-right → bottom-left → top-left → top-right
local cornerIdx = 1

local function rectForCorner(corner)
    local s = hs.screen.mainScreen():frame()
    local x, y
    if corner == "br" then
        x = s.x + s.w - OVERLAY_W - MARGIN
        y = s.y + s.h - OVERLAY_H - MARGIN_B
    elseif corner == "bl" then
        x = s.x + MARGIN
        y = s.y + s.h - OVERLAY_H - MARGIN_B
    elseif corner == "tl" then
        x = s.x + MARGIN
        y = s.y + MARGIN
    elseif corner == "tr" then
        x = s.x + s.w - OVERLAY_W - MARGIN
        y = s.y + MARGIN
    end
    return { x = x, y = y, w = OVERLAY_W, h = OVERLAY_H }
end

-- ===== Webview =====
local prefs = {
    developerExtrasEnabled = true,   -- 디버깅 편하라고 켜둠. 우클릭 → Inspect Element
    suppressesIncrementalRendering = false,
}

-- global scope (local 아님) → osascript / Hammerspoon Console 에서 `donggun:reload()` 가능.
-- Local로 두면 webview 캐시된 old HTML이 계속 도는 디버깅 지옥 재발.
donggun = hs.webview.new(rectForCorner(CORNERS[cornerIdx]), prefs)
    :transparent(true)                                  -- 투명 배경
    :allowGestures(false)
    :allowTextEntry(false)
    :windowStyle({"borderless", "closable", "nonactivating"})  -- 테두리 없음, 클릭해도 포커스 안 뺏김
    :level(hs.drawing.windowLevels.popUpMenu)           -- floating으론 다른 앱 floating window에 깔림 → popUpMenu (메뉴/툴팁 level)로 올려야 안 가려짐
    :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces  -- 모든 데스크탑/스페이스에서 보임
            + hs.drawing.windowBehaviors.stationary
            + hs.drawing.windowBehaviors.fullScreenAuxiliary)  -- 풀스크린 앱 위에도 표시
    :url("http://127.0.0.1:" .. PORT .. "/donggun.html?auto=1")

local dragMode = false
hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
    local f = e:getFlags()
    dragMode = f.cmd and f.shift
    return false
end):start()

hs.eventtap.new({hs.eventtap.event.types.leftMouseDragged}, function(e)
    if not dragMode then return false end
    local pos = hs.mouse.absolutePosition()
    local f = donggun:frame()
    if pos.x < f.x or pos.x > f.x + f.w or pos.y < f.y or pos.y > f.y + f.h then return false end
    local dx = e:getProperty(hs.eventtap.event.properties.mouseEventDeltaX)
    local dy = e:getProperty(hs.eventtap.event.properties.mouseEventDeltaY)
    f.x = f.x + dx
    f.y = f.y + dy
    donggun:frame(f)
    return true
end):start()

-- 서버 ready 폴링 (race condition 방지: hs.task 비동기 시작이라 즉시 url load 시 -1004 가능)
local function showWhenServerReady(retries)
    retries = retries or 0
    if retries > 25 then
        hs.alert.show("⚠️ 동건이 서버 응답 없음")
        return
    end
    hs.http.asyncGet(
        "http://127.0.0.1:" .. PORT .. "/donggun.html",
        nil,
        function(status, _, _)
            if status == 200 then
                donggun:reload()
                donggun:show()
                hs.alert.show("🍙 동건이 등장 (⌘⇧D 토글)")
            else
                hs.timer.doAfter(0.2, function() showWhenServerReady(retries + 1) end)
            end
        end
    )
end
showWhenServerReady()

-- ===== 핫키 =====

-- Cmd+Shift+D: 보이기/숨기기 토글
hs.hotkey.bind({"cmd", "shift"}, "D", function()
    if donggun:isVisible() then
        donggun:hide()
        hs.alert.show("🍙 동건이 숨김")
    else
        donggun:show()
        hs.alert.show("🍙 동건이 등장")
    end
end)

-- Cmd+Shift+R: 새로고침 (donggun.html 수정 후 즉시 반영)
hs.hotkey.bind({"cmd", "shift"}, "R", function()
    donggun:reload()
    hs.alert.show("🔄 새로고침")
end)

-- Cmd+Shift+H: 다른 코너로 순환 이동
hs.hotkey.bind({"cmd", "shift"}, "H", function()
    cornerIdx = (cornerIdx % #CORNERS) + 1
    donggun:frame(rectForCorner(CORNERS[cornerIdx]))
    hs.alert.show("🍙 → " .. CORNERS[cornerIdx])
end)

-- Cmd+Shift+M: 마이크 토글 (Zoom/Discord 시작할 때 동건이 마이크 양보)
hs.hotkey.bind({"cmd", "shift"}, "M", function()
    donggun:evaluateJavaScript("document.getElementById('micToggle').click(); micEnabled",
        function(result, _)
            hs.alert.show("🎤 마이크 " .. (result and "켜짐" or "꺼짐"))
        end
    )
end)

-- 모니터 구성 바뀌면 위치 다시 잡기 (외부 모니터 연결/해제 등)
hs.screen.watcher.new(function()
    donggun:frame(rectForCorner(CORNERS[cornerIdx]))
end):start()

hs.application.watcher.new(function(name, event, app)
    if name == "Hammerspoon" and event == hs.application.watcher.hidden then
        hs.timer.doAfter(0.1, function() app:unhide() end)
    end
end):start()

local function followActiveSpace()
    local hsbf = donggun:hswindow()
    if not hsbf then return end
    local wid = hsbf:id()
    local screen_uuid = hs.screen.mainScreen():getUUID()
    local active_id = hs.spaces.activeSpaces()[screen_uuid]
    if not active_id then return end
    local win_spaces = hs.spaces.windowSpaces(wid) or {}
    for _, sp in ipairs(win_spaces) do
        if sp == active_id then return end
    end
    pcall(function() hs.spaces.moveWindowToSpace(wid, active_id) end)
end
hs.spaces.watcher.new(followActiveSpace):start()

hs.timer.doEvery(3, function()
    local hs_app = hs.application.applicationsForBundleID("org.hammerspoon.Hammerspoon")[1]
    if hs_app and hs_app:isHidden() then hs_app:unhide() end
    if donggun:isVisible() then donggun:bringToFront(true) end
    followActiveSpace()
end)

print("🍙 동건이 오버레이 로드 완료 → http://127.0.0.1:" .. PORT)
hs.alert.show("🍙 동건이 등장 (Cmd+Shift+D 로 토글)")

return true
