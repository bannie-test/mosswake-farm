# Playtest guide for the facilitator (M6)

Goal: 15 outside players, each alone, playing the demo from a new farm. The numbers come from the
game's own session logs; the questionnaire covers what a log cannot know.

## Before the session

1. Give the tester the demo build for their system (see `README.md`, "Demo build").
2. Tell them only this: "It is a farming game. Play as long as you like. Say out loud what confuses you."
   Do not explain any system. The criteria of GDD section 20 are about what players manage unaided.
3. The game keeps a playtest log by default (Esc menu, "Keep a playtest log on this computer").
   It stays on their computer; nothing is sent anywhere. Tell them so, and let them switch it off.

## During the session

- Do not help. If the tester is stuck for more than five minutes, help, and note it: the tester
  then counts as "needed help" in the questionnaire.
- Note the real time at which they first deliver an order after planting, growing, harvesting and
  merging (the first loop).
- Note every crash or freeze, with what they were doing.
- A tester may stop at any time and come back later; each run of the game writes its own log file.

## After the session

1. Ask the questions in `questionnaire.md` and record the answers in `answers.csv` (one row per tester).
2. Collect the tester's logs: Esc menu, "Open the folder with logs and playtest notes". Copy the
   whole `playtest` folder (the session files) and the `logs` folder (error logs).
3. Put the session files in `sessions/<tester name>/`.

## Making the report

```bash
python3 tools/playtest_report.py sessions --answers answers.csv --out qa/reports/playtest_report.md
```

The report fills in the playtest rows of section 20 and says which rows still lack data. The
go or no-go for release R1 is the Director's, on the report plus `qa/reports/mvp_acceptance.md`.

## Day length test (carried over from M1)

Run three testers each at 18, 24 and 30 real minutes per game day by changing
`time.realSecondsPerGameHour` in `data/config.json` to 45, 60 or 75 (then run
`python3 tools/sync_data.py`). Ask question 9 of the questionnaire.
