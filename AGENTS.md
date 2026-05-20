# AGENTS.md

Guidance for AI agents (Claude, Codex, Cursor, Devin, opencode, etc.) working on this repo.
Optimized for fast parsing and safe edits.

## 1. Project type

Hammerspoon module — **Lua entrypoint + single-page WebView**. macOS-only. No build step, no package manager, no test suite.

- `donggun/init.lua` — Hammerspoon side: window mgmt, http server, hotkeys, watchers.
- `donggun/donggun.html` — All character behavior: state machine, audio analysis, animations, thoughts.
- `donggun/assets/*.png` — 26 sprite PNGs named `donggun_v5_{food}[_pause_mid{1,2}|_paused].png` plus `donggun_v5_{choking,changing}.png`.

Surrounding community files (do not affect runtime): `README.md` (human), `AGENTS.md` (this), `CONTRIBUTING.md` (contributor flow), `LICENSE` (MIT), `.editorconfig` (whitespace), `.github/ISSUE_TEMPLATE/*.md` (issue forms), `docs/{demo.gif,screenshot.png}` (visuals).

Total LOC: ~200 (Lua) + ~660 (HTML). Read both fully before nontrivial changes.

## 2. Quick context

- Lua side boots `python3 -m http.server 8765` rooted at `scriptDir()` (auto-detected via `debug.getinfo`).
- WebView loads `http://127.0.0.1:8765/donggun.html?auto=1`.
- HTML uses `getUserMedia` → `AudioContext` → averaged FFT bin → asymmetric smoothing → 4-stage ladder mapped to visual states.
- `donggun` Lua variable is **intentionally global** for live debugging from Hammerspoon Console.

## 3. How to test changes

There is no automated test suite. The workflow is **manual reload**:

| Change type | Reload command | Speed |
|---|---|---|
| HTML / CSS / JS (`donggun.html`) | `Cmd+Shift+R` inside overlay | < 1 s |
| `init.lua` | Hammerspoon menubar → **Reload Config** (or `hs.reload()` in Console) | ~2 s |
| New assets | Copy to `donggun/assets/` then `Cmd+Shift+R` | < 1 s |
| Install script | `./install.sh` from repo root (re-runs are idempotent) | ~3 s |

Headless sanity checks:

```bash
lsof -ti:8765                                          # http server alive?
curl -sI http://127.0.0.1:8765/donggun.html            # 200 OK?
curl -sI http://127.0.0.1:8765/assets/donggun_v5_eating.png   # asset accessible?
osascript -e 'tell application "Hammerspoon" to execute lua code "hs.reload()"'   # programmatic reload
```

Visual verification: take a screenshot with `screencapture -m /tmp/check.png` after reload.

## 4. Coding conventions

### Lua (`init.lua`)
- 4-space indent. `local` first. snake_case for locals; `hs.*` API as-is (camelCase).
- Korean comments are fine and preferred for intent ("**왜** 이렇게 했는지"). The existing comments document tricky decisions (`windowLevels.popUpMenu` vs `floating`, `donggun` global, EADDRINUSE retry) — do not delete them.
- Avoid blocking work on the main thread. Use `hs.timer.doAfter`, `hs.timer.doEvery`, `hs.http.asyncGet`.

### JavaScript (`donggun.html`)
- 2-space indent. `const` first. camelCase. Comments mix Korean + English.
- All character constants (`STAGE_HOLD_UP`, `NOISE_LOW`, `SMOOTH_UP`, etc.) sit in a block near the top of `<script>`. Tune there, not inline.
- Preload sprites in the same loop pattern as the existing code (`new Image(); i.src = ...`). Forgetting to preload = first-paint flash.

### Assets
- Filename pattern: `donggun_v5_{food}[_pause_mid{1,2}|_paused].png` for foods; `donggun_v5_{state}.png` for state-only sprites (choking, changing).
- Each food needs exactly 4 sprites (eating + mid1 + mid2 + paused) to support the 4-stage ladder.
- `image-rendering: pixelated` is on — sprites are intentionally not anti-aliased.

## 5. Pitfalls & invariants

- **`WORK_DIR` is computed via `debug.getinfo`.** Never hard-code a path back in — installs can land anywhere (dotfiles, custom location).
- **`donggun` is intentionally global** (not `local`). Required for `donggun:reload()` from Hammerspoon Console. Renaming or scoping it locally breaks the live-debug workflow.
- **Port 8765 is hard-coded** in both `init.lua` (`PORT`) and assumed by webview URL. To change: update `PORT` in init.lua only — HTML uses relative paths.
- **`file://` does NOT work** for the webview. WebKit blocks `getUserMedia` outside http(s)/localhost. The entire localhost server exists for this reason.
- **JS preloads all sprites at load.** If you add a sprite without updating both `FOODS` and the preload `forEach`, you get a first-paint flash.
- **Hammerspoon needs Accessibility + Microphone permissions** — these are user-granted via System Settings, not scriptable.
- **`hs.eventtap` listeners hold strong refs.** Don't recreate them on reload without `:stop()` first (current code accepts the leak; init.lua reload is rare).
- **All Spaces / fullScreen-aux behavior** is set via `windowBehaviors` flags. Removing `fullScreenAuxiliary` makes the overlay invisible over fullscreen apps.

## 6. File responsibility map

| File | Owns | Touch when |
|---|---|---|
| `donggun/init.lua` | Window, hotkeys, http server, screen/space watchers, drag | Hotkey, position, server, OS integration changes |
| `donggun/donggun.html` | Character behavior, audio analysis, animations, thoughts | Anything visual or auditory |
| `donggun/assets/*.png` | Static visuals only | New food / new state |
| `install.sh` | Idempotent install + init.lua append | Install flow changes |
| `uninstall.sh` | Safe removal | Uninstall flow changes |
| `README.md` | Human-facing onboarding (Korean primary, badges, demo GIF) | When user-visible behavior changes |
| `AGENTS.md` | Agent-facing guidance (this file) | When file structure / invariants change |
| `CONTRIBUTING.md` | Human contributor workflow (Korean) | When contribution flow changes |
| `.editorconfig` | Editor whitespace rules (Lua=4sp, JS=2sp, sh=2sp) | When indent conventions change |
| `.github/ISSUE_TEMPLATE/*.md` | GitHub issue forms (bug report) | When bug-report fields need change |
| `docs/demo.gif` | Asymmetric smoothing animation (eating→paused→eating) | When sprite set or state machine changes |
| `docs/screenshot.png` | Hero shot showing in-context use | When concept/scene changes |

## 7. Extension recipes

### Add a new food (e.g. tteokbokki)

1. Create 4 sprites in `donggun/assets/`:
   - `donggun_v5_tteok.png` (eating)
   - `donggun_v5_tteok_pause_mid1.png`
   - `donggun_v5_tteok_pause_mid2.png`
   - `donggun_v5_tteok_paused.png`
2. Add an entry to the `FOODS` array in `donggun/donggun.html` (~line 220):
   ```js
   { key: 'tteok', eating: 'assets/donggun_v5_tteok.png',
     mid1: 'assets/donggun_v5_tteok_pause_mid1.png',
     mid2: 'assets/donggun_v5_tteok_pause_mid2.png',
     paused: 'assets/donggun_v5_tteok_paused.png',
     thought: '매운 게 정답', name: '떡볶이' },
   ```
3. Press `Cmd+Shift+R` inside the overlay.

### Change a hotkey

Edit `donggun/init.lua` — find `hs.hotkey.bind({"cmd","shift"}, "D", ...)` etc. Hammerspoon menubar → **Reload Config**.

### Tune mic sensitivity

In `donggun/donggun.html` (~line 485): `NOISE_LOW = 7`, `NOISE_MID = 13`, `NOISE_HIGH = 20`. Lower = more easily startled. Press `Cmd+Shift+R` to reload.

### Tune state transition speed

In `donggun/donggun.html` (~line 210):
- `STAGE_HOLD_UP` — ms per ladder step while panicking (default 80, lower = more jittery)
- `STAGE_HOLD_DOWN` — ms per step while calming (default 900, lower = recovers faster)
- `PAUSED_HANG_MS` — how long PAUSED is "stuck" after reaching it (default 1200)

### Move sprites

Don't. The http server roots at `donggun/`, and HTML asset paths are relative to that root. If you really need a different layout, update `scriptDir()` in init.lua to point at the new root and rewrite all `assets/...` paths in HTML.

## 8. Do not

- Don't add a build step, bundler, npm, or transpiler. The whole point is "edit, save, Cmd+Shift+R".
- Don't replace the localhost server with `file://`. Mic access dies.
- Don't make `donggun` a local variable. Live debugging dies.
- Don't hard-code an absolute path back into `WORK_DIR` / `scriptDir()`. Portability dies.
- Don't change the sprite naming pattern without updating the preload loop AND the `FOODS` array.
- Don't delete the asymmetric smoothing or the PAUSED hang time without explicit user request. They are the soul of the animation.
- Don't strip Korean comments to make the code "English-only". They encode intent that isn't visible from the code alone.

## 9. Repo metadata for tools

```yaml
language: lua, html, javascript, css, bash
runtime: hammerspoon, webkit, python3
platform: macos
build: none
test: manual (Cmd+Shift+R reload)
package_manager: none
permissions_required: [Accessibility, Microphone]
network: localhost-only (127.0.0.1:8765)
entrypoint_install: ./install.sh
entrypoint_runtime: ~/.hammerspoon/init.lua → require("donggun")
```
