## 18. AI Agent Delegation

Eight agents each own one kind of file. No agent writes outside its own files, and all of them read mechanics, IDs and numbers from one repository.

### Single source of truth

| Path | Holds | Only writer | Change process |
| --- | --- | --- | --- |
| /design/gdd/ | This document, one file per section | Game Director | Change request, Director approval |
| /design/specs/ | Per-feature specs derived from the GDD | Systems Designer | Reviewed by Director |
| /data/id_registry.json | Every ID with type, owner and status | Systems Designer | An ID must be registered before it is used anywhere |
| /data/*.json | Static definitions | Systems Designer (structure, content); Economy Balancer (numeric fields only) | Pull request; schema validation in CI |
| /data/schema/ | JSON Schemas | Technical Architect | Pull request; needs a save-migration note |
| /design/art_bible/ | Art Bible, palette file, sprite templates | UI/UX Designer with the human art lead | Human approval |
| /art_src/, /game/assets/ | Sprites | 2D Asset Agent | Asset lint plus human approval |
| /game/ | Godot project and code | Gameplay Programmer | Pull request; tests; QA sign-off |
| /qa/ | Test plans, reports | QA Agent | – |

Three rules prevent conflict:

- **No invention downstream.** An agent that needs a mechanic, ID or field that does not exist stops and files a change request. It does not create one.

- **Numbers live in data.** Code contains no balance constants. A reviewer rejects any literal that duplicates a data value.

- **Every hand-off is checked by a machine.** Schema validation, reference integrity, unlock reachability, economy exploit test and asset lint all run in CI.

### Agents

| # | Agent | Responsibilities | Required input | Expected output | Constraints | Depends on | Definition of done |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Game Director | Owns the vision, pillars and scope; resolves conflicts; approves change requests | Brief, playtest reports, agent questions | GDD sections; decision log; milestone go or no-go | May not add scope without removing some | – | Each decision is recorded with its reason and the sections it changes |
| 2 | Game Systems Designer | Turns GDD sections into feature specs and data; owns the ID registry | GDD; decision log | Feature specs; /data/*.json structure and content | Uses only mechanics in the GDD; registers IDs first | 1 | Spec has rules, edge cases and acceptance tests; data validates |
| 3 | Economy Balancing Agent | Sets numeric values; runs the simulator; reports exploits | Data files; formulas in section 10; playtest telemetry | Updated numeric fields; simulator report per milestone | Changes numbers only; never structure or IDs | 2, 4 | Income targets met; exploit test passes; changes listed with before and after |
| 4 | Technical Architect | Schemas, save format, simulation core design, test harness, CI | GDD sections 13–14; feature specs | JSON Schemas; architecture notes; CI pipeline; migration plan | No gameplay rules; no balance values | 2 | Schemas validate all data; a save round-trips; CI is green |
| 5 | Gameplay Programmer | Implements features in Godot against specs and schemas | Feature spec; schemas; data; UI spec | Code, scenes, unit tests | Reads all values from data; adds no mechanics | 2, 4, 6 | Spec acceptance tests pass; no balance literals; reviewed |
| 6 | UI/UX Designer | Screen flows, wireframes, UI text, input mapping, the UI part of the Art Bible | Feature spec; Art Bible | Wireframes; UI spec per screen; string table | Shows only information the spec says exists; 640×360 layout | 2 | Every state of the screen is drawn, including empty and error states |
| 7 | 2D Asset Generation Agent | Produces sprites, tiles, icons and animations | Art Bible; asset list with IDs and sizes; sprite templates | PNG sheets and animation metadata, named by ID | Master palette only; listed sizes only; no element copied from reference images or other games | 6, Art Bible | Passes asset lint; approved by the human art lead in the style-sheet scene |
| 8 | QA and Testing Agent | Test plans, automated tests, soak and fuzz runs, bug triage | Specs; acceptance criteria; builds | Test reports; bug list with reproduction steps; milestone verdict | Reports; does not fix | 5 | Every acceptance criterion has a test and a recorded result |

### Task dependency graph

_[Diagram: agent task dependency graph · 8 agents — see the GDD doc]_

An arrow means "needs the output of". The Systems Designer's specs and data feed every later agent; the programmer starts only when schemas, tuned numbers, UI specs and approved sprites exist for the feature.

### What must exist before gameplay code starts

- Sections 0–14 of this document, approved.

- The ID registry with every MVP ID.

- JSON Schemas for all 20 definition and state types.

- MVP data, validated.

- Simulator report showing Phase 1 targets are met.

- Feature specs for M1: time, plots, inventory, merge, orders.

- UI wireframes for M1 screens.

- The Art Bible and the approved style test screen.

### Human gates

Agents propose; people decide three things: scope changes, art approval, and the go or no-go at each milestone.
