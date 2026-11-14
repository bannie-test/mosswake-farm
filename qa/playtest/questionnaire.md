# Playtest questionnaire

Ask after the session, in this order. Record the answers in `answers.csv`.

| # | Question | Column in answers.csv | Section 20 row |
| --- | --- | --- | --- |
| 1 | How many real minutes until your first delivered order? (from the facilitator's notes) | `finished_first_loop_minutes` | Core loop: within 10 minutes |
| 2 | Did the facilitator have to help you at any point? | `needed_help` (yes/no) | Core loop; Research: unaided |
| 3 | In your own words: what does the percentage on the Merge Table mean, and what happens when a merge fails? | notes | Merge experience |
| 4 | Did merging ever feel unfair? | `unfair_merge` (yes/no) | Fewer than 20% say unfair |
| 5 | What is a Gene Fragment for? | notes | Risk 10: genetics confuses players |
| 6 | What was the best moment of the session? | notes | MVP must prove: waking the Rootling is the high point |
| 7 | Now that you have one Rootling, do you want a second spirit? | `wants_second_spirit` (yes/no) | At least 70% say yes |
| 8 | Was there a stretch where the game felt like a chore? When? | notes | Risk 5: automation is mandatory |
| 9 | Was a game day too short, too long, or about right? | notes | Risk 13: day length |
| 10 | Did the game crash or freeze? How many times? | `crashes` (number) | Stability |
| 11 | Did anything in the game remind you of another specific game? Which, and what? | notes | Risks 8 and 9: derivative art, copied workers |

`answers.csv` header:

```csv
tester,finished_first_loop_minutes,needed_help,unfair_merge,wants_second_spirit,crashes
```
