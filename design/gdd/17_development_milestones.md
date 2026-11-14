## 17. Development Milestones

The MVP is seven milestones over about 22 weeks. Each one ends in a build that can be played from a new save, and each adds exactly one new link to the loop.

_[Diagram: MVP milestones · 7 milestones over 22 weeks — see the GDD doc]_

Milestones run one after another with no overlap; the dashed line marks the end of M1, when Plant → Grow → Harvest → Merge → Order → Reward is playable.

### M0. Foundations (2 weeks, complexity: low)

- **Objective:** everything that must exist before gameplay code.

- **Features:** none playable.

- **Dependencies:** this document signed off.

- **Tasks:** repository and folder layout; ID registry; JSON Schemas and validator; MVP data entered; economy simulator; Art Bible style test screen; Godot project settings and layer setup.

- **Deliverables:** validated `/data`; simulator report; one approved 640×360 mock screen; empty project that boots.

- **Acceptance:** validator passes on all MVP data; simulator shows the Phase 1 income target is met; style test approved against reference image 1.

- **Testing:** schema validation and reference-integrity tests in CI.

- **Risks:** art style test takes more than one round. Mitigation: start it on day 1.

### M1. First playable (4 weeks, complexity: medium)

- **Objective:** Plant → Grow → Harvest → Merge → Complete NPC order → Earn reward.

- **Features:** player movement; time system; plots, watering, growth for Carrot and Wheat; inventory; Merge Table with 2 recipes; order board with Mara; coins, XP, levels 1–3.

- **Dependencies:** M0.

- **Tasks:** `advance()` simulation core; plot state machine; inventory model and UI; merge roll and screen; fixed-list order board; reward pipeline; placeholder audio.

- **Deliverables:** build 0.1; a 10-minute loop.

- **Acceptance:** a new player completes the full loop in under 10 minutes with no instructions beyond on-screen prompts.

- **Testing:** unit tests for growth, moisture and merge maths; 5 internal playtests.

- **Risks:** the loop is dull by hand. Mitigation: tune action feel (speed, sound, pop) before adding content.

### M2. Complete farm (3 weeks, complexity: medium)

- **Objective:** a farm worth running for an hour.

- **Features:** Tomato and Sunflower; three animals with hunger, happiness and production; Feed; shop; shipping bin; all 10 recipes with pity, Clover and the probability breakdown; Tobin and Ilse; order generator; field purchase; save and load.

- **Dependencies:** M1.

- **Tasks:** animal state and housing; order generation algorithm with fairness checks; save envelope and migration scaffold; land expansion.

- **Deliverables:** build 0.2; levels 1–6 playable.

- **Acceptance:** 1,000 generated orders at each level 1–10 are all completable (automated); a 60-minute session reaches level 5–6; save and reload reproduces state exactly.

- **Testing:** order fuzz test; save round-trip test; merge distribution test over 100,000 rolls per tier.

- **Risks:** order generator produces dull or unfair orders. Mitigation: the fuzz test plus a designer review of 50 sampled boards.

### M3. Research slice (3 weeks, complexity: medium)

- **Objective:** a rare good opens a door.

- **Features:** Research Station; queue; carrot fragments; first-research bonus; Ancient Carrot blueprint, seed creation and crop; Stardust from failures; four story quests.

- **Dependencies:** M2 merge chain and quests.

- **Tasks:** research queue; blueprint and creation UI; quest system with step types; unlock graph test.

- **Deliverables:** build 0.3; levels 1–8.

- **Acceptance:** 4 of 5 playtesters reach an Ancient Carrot harvest without help; the unlock graph test passes.

- **Testing:** dependency-graph reachability test; quest step tests.

- **Risks:** players sell their Golden Carrot instead of researching it. Mitigation: quest-item warning and Ilse's prompt.

### M4. Spirit slice (4 weeks, complexity: high)

- **Objective:** find, wake and employ one Rootling.

- **Features:** dig site with Root-sense; husk; cleaning interaction; Revival Potion; awakening scene; Rootling behaviour; zone tool; stamina, rest, skill levels 1–3; Sap upkeep.

- **Dependencies:** M3 quests; M2 plots.

- **Tasks:** dig grid; generic job state machine; pathfinding on the farm grid; zone drawing UI; spirit animations; upkeep at dawn.

- **Deliverables:** build 0.4; the whole MVP loop.

- **Acceptance:** a Rootling keeps a 16-tile zone above 0 moisture for 3 game days unattended; it never blocks the player or gets stuck in a 2-hour soak test.

- **Testing:** soak test at 20× speed; pathfinding tests with fenced and crowded layouts.

- **Risks:** worker AI and pathfinding overrun. Mitigation: grid A* only, one job type, 4 weeks reserved, and a cut line: skill levels can slip to M5.

### M5. Content and UX complete (3 weeks, complexity: medium)

- **Objective:** everything in section 15 present with final art and sound.

- **Features:** final sprites and animations; UI pass; contextual tutorial prompts; music and effects; balance pass; settings; gamepad.

- **Dependencies:** M4; Art Bible.

- **Tasks:** replace all placeholders; run the simulator against telemetry from playtests; accessibility options (text size, hold-to-act toggle).

- **Deliverables:** build 0.9, content complete.

- **Acceptance:** asset lint passes on every sprite; no placeholder remains; simulator and playtest income agree within 20%.

- **Testing:** asset lint in CI; full playthrough by QA on Windows, Linux and Steam Deck.

- **Risks:** generated assets drift in style. Mitigation: the pipeline in the Art Bible, with a human gate.

### M6. Polish and outside playtest (3 weeks, complexity: low to medium)

- **Objective:** a demo strangers can finish.

- **Features:** none new.

- **Dependencies:** M5.

- **Tasks:** 15 outside playtesters; fix the top issues; performance pass; crash reporting; store demo build.

- **Deliverables:** MVP 1.0 demo; playtest report; go or no-go for R1.

- **Acceptance:** section 20 in full.

- **Testing:** regression suite; 60 fps on Steam Deck with 36 plots, 12 animals and 1 spirit.

- **Risks:** playtests show a system is not fun. Mitigation: one week of M6 is unallocated for exactly this.
