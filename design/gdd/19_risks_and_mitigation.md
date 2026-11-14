## 19. Risks and Mitigation

The largest risk is scope: five connected systems for a team of two or three. The others follow from it.

| # | Risk | Likelihood | Impact | Mitigation | Early warning |
| --- | --- | --- | --- | --- | --- |
| 1 | Scope: too many systems to finish | High | High | One vertical slice per system; a release starts only when the last one tests well; cut list in section 15 | A milestone slips more than one week |
| 2 | Merge randomness feels unfair | Medium | High | Visible odds, pity, refund, Stardust, no monetisation; tune base rates up before adding systems | Playtesters stop merging above Advanced |
| 3 | Economy inflation or dead ends | Medium | High | Formula-based prices; simulator; automated exploit and reachability tests | Simulator and playtest income differ by more than 20% |
| 4 | Automation removes the game | Medium | High | Spirits do chores only; zone and Sap limits; decisions stay manual | Session length falls after the first spirit |
| 5 | Automation is mandatory | Medium | Medium | Field costs and order sizes are tuned for hand play up to Phase 4; test: reach Phase 4 with no spirit | Playtesters call Phase 3 a grind |
| 6 | Worker AI and pathfinding overrun | Medium | Medium | Grid A*, one generic job state machine, four weeks reserved, soak test | A spirit gets stuck in the 2-hour soak |
| 7 | AI-generated art drifts from the reference style | High | Medium | Art Bible, master palette, templates, asset lint, human approval, manual cleanup budget of 30 minutes per sprite | Lint failure rate above 25% |
| 8 | Art looks derivative of the reference games | Medium | High | References are for technique only; no traced or reproduced elements; original building and character designs; legal review before the store page | A reviewer can name the source of an asset |
| 9 | Spirit system reads as a copy of another game's workers | Low | Medium | Different fiction (dormant forest caretakers), different loop (dig, clean, vocation, zones), original names and looks | Playtesters use another game's term for them |
| 10 | Genetics confuses casual players | Medium | Medium | Fixed, non-random research yield; breeding odds shown; traits arrive in R2, not the MVP | Players cannot say what a fragment is for after 20 minutes |
| 11 | Agents produce conflicting IDs or mechanics | Medium | Medium | Single source of truth; ID registry; CI checks; change requests | The validator fails on a merge to main |
| 12 | Save breaks between versions | Low | High | Versioned saves, migrations, retired-ID map, round-trip test from M2 | An old save fails to load in CI |
| 13 | Real-time day is too fast or too slow | Medium | Low | Day length is one config value; test 18, 24 and 30 minutes in M1 | Players rush or idle at dusk |
