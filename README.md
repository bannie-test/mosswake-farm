# Mosswake Farm

A cozy pixel-art farming game with recipe merging, gene research and Tree Spirit (Ma Cây)
automation. Godot 4.7.2, GDScript, 640x360 internal resolution.

The design is the GDD in `design/gdd/` (one file per section). Nothing in this repository may
add a mechanic, ID or number that the GDD or the decision log does not contain.

## Layout (GDD section 18: single source of truth)

| Path | Holds |
| --- | --- |
| `design/gdd/` | The Game Design Document |
| `design/decision_log.md` | Approved and provisional decisions, open findings |
| `design/specs/` | Per-feature specs (start in M1) |
| `design/art_bible/` | Master palette, approved style test screens |
| `data/` | Static definitions, `id_registry.json`, `schema/` |
| `game/` | The Godot project (`game/data` is a copy of `data/`, made by `tools/sync_data.py`) |
| `tools/` | Validator, economy simulator, asset lint, placeholder art, check runner |
| `qa/` | Tests, fixtures (the GDD's own JSON examples), reports |

## Commands

```bash
tools/run_checks.sh
```

```bash
python3 tools/economy_sim.py --report qa/reports/economy_sim_m0.md
```

```bash
godot --path game
```

Controls: move with WASD or the arrow keys, act with E or Space, change seed with Q, backpack with Tab,
close a screen or open the menu with Esc. Gamepad: stick or D-pad, A act, X seed, Y backpack, B or Start menu.

After editing anything in `data/`, run `python3 tools/sync_data.py`. After changing sprites,
run `python3 tools/asset_lint.py`.

## Demo build

With Godot 4.7.2 and its export templates installed:

```bash
godot --headless --path game --export-release "Windows Desktop"
```

```bash
godot --headless --path game --export-release "Linux"
```

The builds land in `build/` (not committed). Ship the executable together with its `.pck`.

## Playtest

`qa/playtest/facilitator_guide.md` and `qa/playtest/questionnaire.md` describe the outside playtest.
The game writes a session log to its user folder; `tools/playtest_report.py` turns the collected
logs and answers into the playtest rows of GDD section 20. `qa/reports/mvp_acceptance.md` holds the
status of every acceptance row.

## Status

| Milestone | State |
| --- | --- |
| M0 Foundations | Accepted 2026-11-14 |
| M1 First playable | Accepted 2026-11-14 (human playtest items still open, see D-010) |
| M2 Complete farm | Accepted 2026-11-14 |
| M3 Research slice | Accepted 2026-11-14 |
| M4 Spirit slice | Accepted 2026-11-14 |
| M5 Content and UX | Accepted 2026-11-14 with open items (art, balance with real players) |
| M6 Polish and outside playtest | Tooling, demo build and playtest kit built on branch `m6-polish-playtest`; the playtest waits for demo 0.10 |
| Revision 2 (GDD section 21) | Step R2-A (data, schemas, sprites, economy derivation) built on branch `r2a-data`; steps R2-B to R2-F not started |
