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
close a screen with Esc.

After editing anything in `data/`, run `python3 tools/sync_data.py`. After changing sprites,
run `python3 tools/asset_lint.py`.

## Status

| Milestone | State |
| --- | --- |
| M0 Foundations | Accepted 2026-11-14 |
| M1 First playable | Accepted 2026-11-14 (human playtest items still open, see D-010) |
| M2 Complete farm | Accepted 2026-11-14 |
| M3 Research slice | Built on branch `m3-research-slice`; waiting for the Director's go or no-go |
