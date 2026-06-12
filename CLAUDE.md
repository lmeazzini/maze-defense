# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

**Maze Defense** — a maze-style tower defense game (Desktop TD style). The project is in the pre-code stage: only the design document exists. All design decisions are settled and recorded in `GAME_DESIGN.md` — read it before implementing anything. Do not re-litigate decisions documented there; out-of-scope features (flying enemies, selectable targeting, branching upgrades, mid-game saves) are listed at the bottom of that file.

## Stack

- **Godot 4** (latest stable), **GDScript with static typing** (always type-annotate: `var gold: int`, `func take_damage(amount: int) -> void`)
- Target platform: **Desktop (Windows/Linux)** — no web/mobile export in v1
- Art: CC0 pixel art (Kenney.nl tower defense packs); audio: CC0 packs
- UI language: **pt-BR**. Keep all player-facing strings centralized (single constants file or similar), never hardcoded in scenes/scripts, to allow future translation

## Commands

Godot 4.6.3 (Windows console build, runs fine from WSL) lives at:
`/mnt/c/Users/luis_/godot/Godot_v4.6.3-stable_win64_console.exe`

From the project root (where `project.godot` lives):

```bash
GODOT=/mnt/c/Users/luis_/godot/Godot_v4.6.3-stable_win64_console.exe
"$GODOT" --headless --import --path . --quit       # import/validate resources; ALSO required after adding class_name scripts
"$GODOT" --headless --path . --quit-after 10       # boot the game 10 frames, catches runtime errors
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit   # run unit tests (GUT)
"$GODOT" --editor --path .                         # open editor (GUI, on the user's screen)
"$GODOT" --path .                                  # run the game windowed
```

Gotchas learned the hard way:
- At process exit, Godot reports `2 resources still in use` / `ObjectDB instances leaked` for the looping menu music (`AudioStreamOggVorbis`). This is a known upstream shutdown-ordering quirk with looping Ogg streams, not a real runtime leak — don't chase it. Grep boot output for `SCRIPT ERROR` instead of bare `error` to avoid false positives.
- Scripts run via `-s` (like `tools/screenshot.gd`) compile BEFORE autoloads register: any static reference (preload chains, typed game classes) to scripts that use `GameEvents`/`AudioManager` fails to compile. Use untyped vars and `load()` at runtime inside such tools.
- After creating new `class_name` scripts or addons, run `--import` before tests, or class names won't be registered.
- Never copy an addon with `cp -r src/gut addons/` when `addons/` doesn't exist — it copies the *contents* to `addons/` root, causing UID duplicates. `mkdir -p addons` first.
- The implementation plan (milestones M1-M6, decisões técnicas) is at `/home/luis_/.claude/plans/agora-planeje-detalhadamente-a-misty-snowglobe.md`.

## Architecture (planned)

The core dependency chain — build in this order, lowest first:

1. **Grid + pathfinding foundation** (highest technical risk, everything depends on it):
   - Open grid; enemies path from entry to exit via A* (Godot's `AStarGrid2D` is the natural fit)
   - Anti-block rule: a tower placement that would fully disconnect entry from exit must be rejected (validate by pathing on a hypothetical grid before committing; show red cell preview)
   - Building/selling is allowed mid-wave: every grid mutation triggers immediate path recalculation for all live enemies
2. **Towers**: 4 types × 3 upgrade levels. Targeting is fixed per type (Archer/Cannon/Ice target first-in-path; Sniper targets strongest) — no targeting UI
3. **Enemies + waves**: 4 ground types (Normal, Fast, Tank, Armored) + Boss every 10 waves. Waves are player-triggered with an early-call gold bonus; game speed toggle 1x/2x/3x
4. **Economy**: gold per kill + end-of-wave bonus; selling refunds 70%; 20 lives (boss leak costs 5)
5. **Maps as data**: 3 maps defined declaratively (TileMap/JSON — grid size, entry/exit, fixed obstacles, wave list), not hand-coded per map
6. **Persistence**: JSON in `user://` for unlocked maps, best wave/stars per map, audio preferences. No mid-game save

## Conventions

- Scenes own their nodes; cross-system communication via signals, not direct node path lookups across scenes
- Game data (tower stats, enemy stats, wave compositions, map layouts) lives in data files/resources, not inline in scripts — balancing must not require code edits
