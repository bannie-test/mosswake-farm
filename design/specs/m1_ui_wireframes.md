# M1 UI wireframes (640x360, 16 px grid)

Input: move WASD / arrows; act E or Space; next seed Q; backpack Tab or I; close Esc. Every
screen also works with the mouse. Panels are parchment with a wood border, from the palette.

## HUD (always on)

```
+--------------------------------------------------------------------------------+
| (o) 50   Lv 1 [=====-----] 30/80                              Day 1  06:00    |
| > Plant your Carrot seeds in the field                                         |
|                                                                                |
|                                (world)                                         |
|                                                         +2 Carrot              |
|                                                         +1 XP                  |
| [seed icon] Carrot Seeds x6  (Q: next)          [E] Water                      |
+--------------------------------------------------------------------------------+
```
- Top left: coins, level, XP bar. Top right: clock. Second line: the next step (guide).
- Bottom left: selected seed and count; "No seeds" when empty. Bottom centre: the action the act
  key would do on the faced tile or object; hidden when there is none.
- Right: toasts, newest at the bottom, each fades after 2.5 seconds.

## Backpack (Tab)

```
+-- Backpack ---------------------------+
| [c 12][w 18][pc 1][  ][  ][  ][  ][  ] |
| [  ][  ][  ][  ][  ][  ][  ][  ]       |
| [  ][  ][  ][  ][  ][  ][  ][  ]       |
| Carrot - worth 8                       |
+----------------------------------------+
```
- 8x3 slots; icon and count; the focused slot's name and value below. Empty state: empty slots.

## Merge Table

```
+-- Merge Table -----------------------------------------------------------------+
| Recipes            |  Premium Carrot           |  Result                        |
| > Premium Carrot x4|  [c][c][c]                |  [pc] Premium Carrot           |
|   Golden Carrot  x0|  Carrot 12/3              |  worth 30                      |
|                    |  charm: (empty)           |  100%                          |
|                    |                           |  Base 100 = 100%               |
|                    |                           |  Fee 3 coins                   |
|                    |                           |  Cannot fail                   |
|                    |                           |  [ Merge ]  [ Merge x4 ]       |
+--------------------------------------------------------------------------------+
```
- Left: known recipes with how many the player can afford. Unknown ones are silhouettes with
  their source (none in M1).
- Centre: ingredient slots, have / need per input, the charm slot (lucky items arrive in M2).
- Right: output, value, percentage (the number rolled), the breakdown, the fee, and the
  cost-of-failure line ("On failure you keep 1 of 3 Premium Carrots and gain 1 Stardust").
- States: can merge; missing ingredients (button disabled, short reason); not enough coins;
  result banner for 1.5 s, skippable (success, critical "x2", or a soft failure line).

## Order board (Mara)

```
+-- Mara's orders ---------------------------------------------------------------+
| Mara Oakhollow, innkeeper                              Reputation 1 (0/40)      |
| +----------------------------------+ +----------------------------------+      |
| | [c] Carrot 4/4                   | | [pc] Premium Carrot 0/1          |      |
| | Reward: 42 coins, 13 XP, +8 rep  | | Reward: 39 coins, 12 XP, +8 rep  |      |
| | + 4 Carrot Seeds                 | | + 6 Carrot Seeds                 |      |
| | [ Deliver ]                      | | [ Need 1 more ]                  |      |
| +----------------------------------+ +----------------------------------+      |
+--------------------------------------------------------------------------------+
```
- One card per slot. States: can deliver; missing goods (button disabled, shows what is
  missing); refilling ("New order in 0:42").
