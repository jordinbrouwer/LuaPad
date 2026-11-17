# Changelog
All notable changes to this project will be documented in this file. Releases are written from the Conventional Commits that change `src/`.

## [Unreleased](https://github.com/jordinbrouwer/LuaPad/compare/1.0.0...main)

## [1.0.0 (2026-11-10)](https://github.com/jordinbrouwer/LuaPad/releases/tag/1.0.0)

First release.

### Added
- `/luapad` (or `/lp`) opens the editor. Type it again or press Esc to close it. The window can be dragged by its title bar. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Snippet list with **+ Simple** and **+ Code**. Each snippet shows its type and state (Active, Disabled or Error) and a `*` when it has unsaved changes. **Delete** asks once more before removing a snippet. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Two starter snippets on first use: a code snippet with the helpers explained, and a Simple rule that alerts you when you enter combat. Both start switched off. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Code editor with syntax colouring, line numbers, a highlighted current line, scroll bars and undo / redo (Ctrl+Z, Ctrl+Y or Ctrl+Shift+Z). Typing a word is one undo step. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- **Save** (Ctrl+S) and **Revert**. Saving a snippet that is on restarts it with the new code. Unsaved changes are kept as a draft, also after `/reload`. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- **Enabled** switch: enabled snippets run after login and `/reload`. A snippet that isn't complete yet can't be switched on, and the reason shows on screen. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Snippets run in their own environment with `On`, `Every`, `After`, `Print`, `Sound`, `Text`, `Flash` and `Status` helpers. `On("PLAYER_LOGIN", ...)` still fires for snippets that start after login. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Saving or switching a snippet off cleans up its events and timers, and silences and hides its frames and hooks. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Status panel next to the editor: **No errors** with the time the snippet started running, **Not running**, **Syntax error**, **Runtime error** or **Will likely fail**, with the line and a short trace. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- **Go to line** jumps to the line of an error, which is also marked in the editor. **Clear error** dismisses it. An error from the saved version that you've since edited shows as **Unsaved fix**. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Live checks while typing: names that don't exist, missing functions on Blizzard tables, and events that don't exist or are blocked for addons (such as the combat log). ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Blocked or forbidden protected calls are reported on the snippet that made them. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Reload popup after saving a snippet that uses `HookScript` / `SetScript`, with **Reload now** and **I'll do that later**. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Error popup when a snippet fails, with the snippet name, the line and the message. Click it to open that snippet. It isn't shown for the snippet you're already looking at. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Simple mode: build a WHEN / ONLY IF / THEN rule without code. Each step can be folded and then shows a one-line summary. Missing fields are named before the rule can be switched on. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- WHEN triggers: always, entering or leaving combat, casting a spell, class resources (Combo Points, Holy Power, Soul Shards, Chi, Arcane Charges, Essence), buffs and debuffs (while active, appearing, fading), cooldowns (coming off cooldown, while ready, while on cooldown), equipping, taking off or wearing an item, a timer, loading screens, login, zone, target, mount, group changes, ready checks, quests, level up and dying. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Buffs and debuffs by name or spell ID, on you, your target, your focus or your pet, with a minimum stack count and from anyone or only yours. The spell icon and name show as a check. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Items by ID, shift-click or drag. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- ONLY IF: up to 4 conditions (combat, group, solo, dungeon or raid, an equipped item, a buff or debuff), combined with AND or OR. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- THEN: one or more actions. Play a sound (8 presets or a custom sound ID), show text on screen, flash the screen or print a chat message. **Test** tries an action straight away. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- On-screen text in 9 colours and 4 sizes. One-off text has a duration and a position (top, centre or lower). ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Text for **While ...** and **Always** rules stays as long as the rule holds, can show the icon and can be dragged anywhere with **Move**. For buffs, debuffs and cooldowns it can have a countdown bar, and `%time`, `%stacks` and `%name` fill in the remaining time, stack count and name. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Simple rules stay quiet instead of erroring when Blizzard hides buffs, debuffs or cooldowns in combat. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- **Convert to code** turns a rule into a normal code snippet. It asks once more, because this is one-way. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Settings panel under Settings > AddOns with an **Open LuaPad** button and the error popup settings: on or off, and how long it stays (3 to 60 seconds). ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- Addon icon. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- README with screenshots of the editor, Simple mode, the live preview and errors. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- CI workflow that runs the project checks: lint, TOC, changelog and release packaging. ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
- CD workflow that packages tagged releases, creates a GitHub release and publishes to CurseForge (requires the `CF_API_TOKEN` and `CF_PROJECT_ID` secrets). ([eedcf92](https://github.com/jordinbrouwer/LuaPad/commit/eedcf92d12e60f4978fdd4423cead0441a360fc8))
