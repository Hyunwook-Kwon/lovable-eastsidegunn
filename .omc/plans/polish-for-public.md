# Plan: Polish for Public Visibility

**Created:** 2026-05-20
**Repo:** Hyunwook-Kwon/lovable-eastsidegunn
**Local:** /Users/kwon/Documents/donggun-hammerspoon
**Status:** Draft — awaiting user confirmation

---

## Scope Decisions (Resolved)

### README strategy → ENRICH, don't split
The current README.md (192L) is already well-structured, bilingual (Korean-primary), personality-driven, and has proper install/hotkey/troubleshooting/architecture sections. It's **already good**. What it's missing:
- Demo GIF embedded (exists at `docs/demo.gif` but not referenced)
- Badges (license, platform, Hammerspoon version)
- Quick "what does this look like?" visual above the fold
- Minor polish (repo structure diagram is stale — missing `docs/demo.gif`)

**Decision:** Enrich README.md in-place. Do NOT split into separate human/agent READMEs — current split (README.md = human, AGENTS.md = agent) is already correct.

### Language → Korean-primary, keep as-is
Already established. No English-only README needed — the bilingual pattern (Korean + short English subtitle) is the voice of the project.

### Demo GIF → Regenerate from sprites via ffmpeg
A `docs/demo.gif` already exists (480×480, 14 frames, 2.8s, 1MB) but it appears to be a single static frame repeated or a very basic cycle. The user specified a **conceptual cycle**: eating → mid1 → mid2 → paused (panic, fast) → paused×N (hang) → mid2 → mid1 → eating (calming, slow). This requires frame-timing that conveys the asymmetric smoothing soul of the project. Regenerate with ffmpeg using variable frame durations.

### "Miscellaneous configs" → Minimum viable polished-OSS set
For a **personal Lua/macOS repo with no external deps**, the proportional-value set is:

| Config | Include? | Rationale |
|---|---|---|
| `.editorconfig` | ✅ YES | 4 lines, prevents tab-vs-space fights across editors. Cheap, universal. |
| `CONTRIBUTING.md` | ✅ YES (minimal) | ~30 lines. Korean-primary. "How to add a food, how to reload, how to submit." Raises GitHub community health score. |
| `.github/ISSUE_TEMPLATE/bug_report.md` | ✅ YES | One template. Guides reporters to include macOS version + Hammerspoon version + console log. |
| `.github/ISSUE_TEMPLATE/feature_request.md` | ❌ NO | Over-engineering for a personal mascot repo. |
| `.github/PULL_REQUEST_TEMPLATE.md` | ❌ NO | Same — this isn't a library. |
| `CODE_OF_CONDUCT.md` | ❌ NO | Personal repo, not community project. |
| `CHANGELOG.md` | ❌ NO | Use GitHub Releases instead. One tag (v1.0.0) with the release. |
| `SECURITY.md` | ❌ NO | No attack surface — localhost-only, no auth, no user data. |
| README badges | ✅ YES | License + macOS + Hammerspoon. 3 badges max. |
| GitHub Release v1.0.0 | ✅ YES | Signals "this is usable." No binary — just a tagged source release. |
| Social preview image | ⚠️ ALREADY SET | OpenGraph is auto-generated. Could upgrade to custom image using existing screenshot.png but LOW priority. |

**What we're NOT doing:** dependabot, CI/CD workflows, npm/pip configs, Discussions, Wiki, Pages, CoC, PR templates, security policy. None add value here.

### AGENTS.md → Targeted enrichment
Current AGENTS.md (146L) is **excellent** — well-organized, covers pitfalls, extension recipes, do-nots. Only needs:
- Update repo structure section (missing `docs/demo.gif`, `.editorconfig`, `.github/`, `CONTRIBUTING.md`)
- Add a "community files" entry to the file responsibility map
- Ensure metadata block is current

---

## Wave Architecture

```
Wave 0 (Setup)           ──── sequential, 1 task
Wave 1 (Parallel Core)   ──── 4 independent tasks
Wave 2 (Integration)     ──── 2 tasks (depend on Wave 1)
Wave 3 (Ship)            ──── 1 task (depends on Wave 2)
QA Gate                  ──── manual verification checklist
```

---

## Wave 0: Setup (Sequential)

### Task 0.1: Create directory scaffolding
- **Goal:** Create `.github/ISSUE_TEMPLATE/` directory
- **Delegate to:** quick task
- **Files touched:** `.github/ISSUE_TEMPLATE/` (new dir)
- **QA:** `ls -la .github/ISSUE_TEMPLATE/` succeeds
- **Dependencies:** None

---

## Wave 1: Parallel Core (All independent)

### Task 1.1: Generate demo GIF from sprites
- **Goal:** Create a high-quality animated GIF that shows the full state-transition cycle in one loop. Must convey the "asymmetric panic/calm" soul of donggun in ≤4 seconds.
- **Delegate to:** writing/visual-engineering (ffmpeg specialist)
- **Files touched:** `docs/demo.gif` (overwrite existing)
- **Sprite sequence & timing:**
  ```
  Frame 1:  donggun_v5_eating.png        200ms  (eating, calm)
  Frame 2:  donggun_v5_eating.png        200ms  (eating, calm — linger)
  Frame 3:  donggun_v5_pause_mid1.png     80ms  (startled — FAST)
  Frame 4:  donggun_v5_pause_mid2.png     80ms  (panicking — FAST)
  Frame 5:  donggun_v5_paused.png        300ms  (frozen — hang)
  Frame 6:  donggun_v5_paused.png        300ms  (frozen — hang ×2)
  Frame 7:  donggun_v5_paused.png        300ms  (frozen — hang ×3)
  Frame 8:  donggun_v5_pause_mid2.png    250ms  (calming — SLOW)
  Frame 9:  donggun_v5_pause_mid1.png    250ms  (calming — SLOW)
  Frame 10: donggun_v5_eating.png        200ms  (back to eating)
  ```
  Total: ~2.2s. Loop=infinite. Asymmetry visible: 160ms up vs 500ms down.
- **ffmpeg approach:**
  1. Scale 1024→360 (match overlay window size) with nearest-neighbor (preserve pixel art)
  2. Use `concat` demuxer with per-frame durations
  3. Generate palette first (`palettegen`), then apply (`paletteuse`) for GIF quality
  4. Target: ≤800KB, 360×360, transparent background if possible (or keep sprite BG)
- **QA criteria:**
  - GIF loops smoothly
  - Panic direction is visibly faster than calm direction
  - File size ≤ 1.5MB
  - `ffprobe` confirms multiple distinct frames with varying durations
- **Dependencies:** Wave 0 (for dir), but `docs/` already exists

### Task 1.2: Write `.editorconfig`
- **Goal:** Enforce consistent whitespace across editors
- **Delegate to:** quick task
- **Files touched:** `.editorconfig` (new)
- **Content:**
  ```ini
  root = true

  [*]
  charset = utf-8
  end_of_line = lf
  insert_final_newline = true
  trim_trailing_whitespace = true

  [*.lua]
  indent_style = space
  indent_size = 4

  [*.{html,js,css,json}]
  indent_style = space
  indent_size = 2

  [*.{sh,bash}]
  indent_style = space
  indent_size = 2

  [*.md]
  trim_trailing_whitespace = false
  ```
- **QA:** File exists, matches Lua=4sp / JS=2sp conventions from AGENTS.md
- **Dependencies:** None

### Task 1.3: Write `CONTRIBUTING.md` (Korean-primary, minimal)
- **Goal:** ~30-40 line guide for contributors. Korean tone matching README. Covers: how to add a food, how to test changes, how to submit issues.
- **Delegate to:** writing task
- **Files touched:** `CONTRIBUTING.md` (new)
- **Structure:**
  ```
  # 🤝 기여 가이드
  > 동건이에게 새 음식을 먹이고 싶다면 여기서 시작.

  ## 빠른 시작 (개발 환경)
  - Prerequisites: macOS, Hammerspoon, python3
  - Clone, install.sh, Cmd+Shift+R

  ## 음식 추가하기
  - (reference AGENTS.md extension recipe — don't duplicate)

  ## 변경 테스트
  - (reference AGENTS.md testing table — don't duplicate)

  ## 이슈 & PR
  - 버그는 Issue template 사용
  - 음식 추가 PR 환영
  - 커밋은 한국어/영어 모두 OK

  ## 코딩 컨벤션
  - (link to AGENTS.md §4)
  ```
- **QA:** Korean-primary, references AGENTS.md instead of duplicating, ≤50 lines
- **Dependencies:** None

### Task 1.4: Write `.github/ISSUE_TEMPLATE/bug_report.md`
- **Goal:** One bug report template. Korean-primary. Captures macOS version, Hammerspoon version, console log, reproduction steps.
- **Delegate to:** quick task
- **Files touched:** `.github/ISSUE_TEMPLATE/bug_report.md` (new)
- **Content outline:**
  ```yaml
  ---
  name: 🐛 버그 리포트
  about: 동건이가 이상하게 행동할 때
  labels: bug
  ---

  ## 증상
  <!-- 무엇이 잘못되고 있나요? -->

  ## 재현 방법
  1.
  2.

  ## 환경
  - macOS:
  - Hammerspoon:
  - 마이크 사용 여부:

  ## Hammerspoon 콘솔 로그
  ```
  <!-- Hammerspoon 메뉴바 → Console → 로그 복붙 -->
  ```
  ```
- **QA:** Template renders correctly on GitHub (YAML front matter + markdown body), Korean-primary
- **Dependencies:** Wave 0 (directory exists)

---

## Wave 2: Integration (Depends on Wave 1)

### Task 2.1: Enrich README.md
- **Goal:** Polish the existing README without changing its soul. Add badges, embed demo GIF, update repo structure, minor tweaks.
- **Delegate to:** writing task
- **Files touched:** `README.md` (edit in place)
- **Changes (minimal, surgical):**
  1. **Add 3 badges** after the `<h1>` line, before the blockquote:
     ```markdown
     [![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
     [![macOS](https://img.shields.io/badge/platform-macOS-blue.svg)]()
     [![Hammerspoon](https://img.shields.io/badge/runtime-Hammerspoon-orange.svg)](https://www.hammerspoon.org/)
     ```
  2. **Replace static screenshot with demo GIF** in the hero image area:
     ```markdown
     <p align="center">
       <img src="docs/demo.gif" alt="donggun demo" width="360">
       <br>
       <sub>소음에 놀라서 굳었다가 천천히 다시 먹기 시작하는 동건이</sub>
     </p>
     ```
     Keep screenshot.png as a secondary image or remove the reference (GIF is strictly better for conveying behavior).
  3. **Update repo structure** section to include new files:
     ```
     ├── .editorconfig
     ├── .github/
     │   └── ISSUE_TEMPLATE/
     │       └── bug_report.md
     ├── CONTRIBUTING.md
     ├── docs/
     │   ├── demo.gif
     │   └── screenshot.png
     ```
  4. **Add link to CONTRIBUTING.md** in the "Tone & concept" section or near the bottom:
     ```markdown
     새 음식 추가, 버그 제보 → [CONTRIBUTING.md](CONTRIBUTING.md)
     ```
- **QA criteria:**
  - `demo.gif` renders on GitHub (check raw URL)
  - Badges render (shields.io is external — verify links work)
  - Repo structure matches actual filesystem
  - No content lost from original README
  - Korean tone preserved
- **Dependencies:** Task 1.1 (demo.gif exists), Task 1.2 + 1.3 + 1.4 (files to reference exist)

### Task 2.2: Update AGENTS.md
- **Goal:** Keep agent guide in sync with new files
- **Delegate to:** quick task
- **Files touched:** `AGENTS.md` (edit in place)
- **Changes:**
  1. Update **§1 Project type** or add mention of community files
  2. Update **file responsibility map** (§6) — add rows:
     | `.editorconfig` | Editor whitespace rules | When coding conventions change |
     | `CONTRIBUTING.md` | Human contributor guide | When contribution workflow changes |
     | `.github/ISSUE_TEMPLATE/*` | Issue forms | When bug report needs change |
  3. Update **repo metadata** block (§9) if needed
  4. Verify the repo structure snippet matches reality
- **QA:** All new files mentioned, file responsibility map is complete, no stale references
- **Dependencies:** Wave 1 (all new files exist)

---

## Wave 3: Ship (Depends on Wave 2)

### Task 3.1: Create GitHub Release v1.0.0
- **Goal:** Tag and release v1.0.0 with release notes summarizing what donggun is
- **Delegate to:** quick task (gh CLI)
- **Commands:**
  ```bash
  cd /Users/kwon/Documents/donggun-hammerspoon
  git add -A
  git commit -m "docs: polish for public visibility — badges, demo GIF, contributing guide, issue template, editorconfig"
  git push origin main
  gh release create v1.0.0 --title "🍙 donggun v1.0.0" --notes "$(cat <<'EOF'
  첫 공식 릴리스.

  ## 포함
  - 데스크탑 오버레이 캐릭터 (6종 음식 × 4단계 소음 반응)
  - idempotent 설치/제거 스크립트
  - 26개 v5 스프라이트

  ## 설치
  ```bash
  git clone https://github.com/Hyunwook-Kwon/lovable-eastsidegunn.git
  cd lovable-eastsidegunn && ./install.sh
  ```

  자세한 내용은 [README.md](https://github.com/Hyunwook-Kwon/lovable-eastsidegunn#readme) 참고.
  EOF
  )"
  ```
- **QA:** `gh release view v1.0.0` succeeds, release page renders correctly on GitHub
- **Dependencies:** Wave 2 complete, all files committed

---

## QA Gate: Manual Verification Checklist

Run after Wave 3 completes. All must pass.

| # | Check | Command / Method | Pass Criteria |
|---|---|---|---|
| 1 | README renders on GitHub | `open https://github.com/Hyunwook-Kwon/lovable-eastsidegunn` | Badges visible, demo GIF animates, no broken images |
| 2 | Demo GIF loads | `open https://github.com/Hyunwook-Kwon/lovable-eastsidegunn/blob/main/docs/demo.gif` | Animates, ≤1.5MB, asymmetric timing visible |
| 3 | AGENTS.md accurate | Read AGENTS.md §6 table | All new files listed in file responsibility map |
| 4 | Issue template works | Click "New Issue" on GitHub | Bug report template appears with Korean fields |
| 5 | CONTRIBUTING.md linked | Click link in README | Renders, Korean-primary, links back to AGENTS.md |
| 6 | .editorconfig correct | `cat .editorconfig` | Lua=4sp, JS=2sp, UTF-8, LF |
| 7 | Release exists | `gh release view v1.0.0` | Tag exists, release notes render, Korean text intact |
| 8 | install.sh still works | `./install.sh` (idempotent re-run) | No errors, no duplicate `require("donggun")` lines |
| 9 | Community health score | `open https://github.com/Hyunwook-Kwon/lovable-eastsidegunn/community` | Score ≥ 70% (up from 42%) |
| 10 | Git clean | `git status` | Nothing untracked, working tree clean |

---

## Concrete Deliverable List

| # | File | Action | Size est. |
|---|---|---|---|
| 1 | `docs/demo.gif` | OVERWRITE | ≤1.5MB |
| 2 | `.editorconfig` | NEW | ~200B |
| 3 | `CONTRIBUTING.md` | NEW | ~1.5KB |
| 4 | `.github/ISSUE_TEMPLATE/bug_report.md` | NEW | ~500B |
| 5 | `README.md` | EDIT | ±30 lines |
| 6 | `AGENTS.md` | EDIT | ±15 lines |
| 7 | GitHub Release v1.0.0 | CREATE (gh CLI) | — |

**Total: 4 new files, 2 edits, 1 release. No code changes.**

---

## Librarian Integration Note

A librarian agent (bg_f2ea600f) is gathering GitHub community-standards best practices. When its output arrives:
- **Check against our decisions** — we intentionally skipped CoC, PR template, SECURITY.md, feature request template. If the librarian flags any of these as "highly recommended even for personal repos," reconsider.
- **Plug into Task 1.4** — if the librarian provides a better issue template structure, use it.
- **Plug into Task 2.1** — if the librarian recommends specific badge patterns or README sections we missed, integrate.
- **Otherwise, proceed as planned** — our scope decisions are opinionated and proportional.

---

## Delegation Summary

| Task | Category | Skill | Est. Time |
|---|---|---|---|
| 0.1 | quick | bash | 5s |
| 1.1 | visual-engineering | ffmpeg | 2min |
| 1.2 | quick | file-write | 10s |
| 1.3 | writing | Korean docs | 3min |
| 1.4 | quick | file-write | 30s |
| 2.1 | writing | README edit | 5min |
| 2.2 | quick | AGENTS.md edit | 2min |
| 3.1 | quick | gh CLI | 1min |

**Total estimated: ~15 minutes of agent time, parallelized to ~8 minutes wall clock.**
