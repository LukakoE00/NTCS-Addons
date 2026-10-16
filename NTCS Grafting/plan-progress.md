# NT Grafting FORKED — Plan Progress

## Current state

- [x] Create the local mod directory.
- [x] Add the planning README.
- [x] Record the optimized image source directory.
- [x] Copy the NT Grafting base files into this mod.
- [x] Add a local `filelist.xml` for the copied base package.
- [x] Avoid duplicate XML creature drop definitions.
- [x] Copy the runtime creature-drop content from `NT Grafting Creature Drop Lua` (`3787971278`) for the first release.
- [x] Register the copied `Lua/Autorun/ntg_creature_drop.lua` in the package manifest.
- [x] Document that the separate drop package should not be enabled alongside the copied version.
- [x] Copy optimized PNG assets from the source directory while preserving relative paths.
- [x] Overwrite the corresponding base image files in place.
- [x] Keep the original XML texture paths unchanged.
- [x] Compare all 32 optimized PNGs against the overwritten base-path files with SHA-256 hashes.
- [x] Normalize the seven explicit `%ModDir:NT Grafting%` references to `%ModDir%`.
- [ ] Validate runtime resolution of all texture references.

## Optimization and compatibility work

### Phase 1 — Runtime hot paths

- [x] Refactor `hybriddna` with static graft groups, rejection/Ligation-Enhancer-gated recalculation, and corrected hacked/tolerant-DNA logic.
- [x] Optimize `lockedhands` by evaluating inventory directly on the native update cadence.
- [x] Make husk-heart characters bypass normal limb-lock conditions while retaining handcuff enforcement.
- [x] Prevent repeated Endworm limb-affliction additions while preserving gradual propagation on the native update cadence.
- [x] Cache torso clothing/sprite state and avoid unchanged `SetAffliction` calls.
- [x] Process Moloch head damage through the Neurotrauma damage hook instead of every update.
- [x] Rate-limit Orangeboy chitin rolls while preserving the expected batch probability.

### Phase 2 — XML status effects

- [x] Audit every unintervalled `StatusEffect` in `graftedAfflictions.xml`.
- [x] Replace the static Mudraptor `FlowResistance` status effect with a direct `StatValue`.
- [x] Add appropriate intervals to repeated surgery-incision, psychosis, hypoxia, and sprite effects.
- [x] Audit transplant-item spoilage checks and add a one-second interval without changing intended spoilage rates.
- [x] Review `charybdisCure` nearby-character processing and add an event interval.

Audit results and applied fixes:

- `264-267`: `mudraptorLegRightAffliction` now applies `FlowResistance` directly through `StatValue`.
- `321-325`: cracked Moloch effects now run at a one-second interval.
- `351-353`: `graftedWatcherGaze` psychosis now runs at a one-second interval.
- `393-400`: `charybdisCure` now coalesces repeated damage events with a one-second interval.

Transplant-item spoilage:

- [x] Updated all 28 transplant/cell spoilage effects to `interval="2"` with `disabledeltatime="true"`.
- [x] Set the requested decay rate of `1` condition per two seconds.
- [ ] Verify spoilage timing in-game while refrigerated, contained in a medical fabricator, and outside storage.

Moloch crack accumulation:

- [x] Calculate crack strength from the current `attackResult` instead of accumulated trauma thresholds.
- [x] Apply per-affliction damage resistance before calculating crack strength.
- [x] Use blunt trauma as the strongest coefficient, gunshot wounds second, and lacerations third.
- [x] Cap each damage type at `30` crack strength and cap the combined hit at `30`.
- [x] Restore post-break crack growth at `0.5` and reduce sub-threshold decay to `-0.1`.
- [x] Correct the Moloch shell `strengthchange` attribute typo and audit other progressive graft attributes.
- [ ] Tune coefficients and post-break hypoxia in runtime tests.
- The five Endworm and Hammerhead surgery-incision effects also use one-second intervals.
- The two unintervalled effects in the commented-out crawler-tail section remain inactive and require no runtime change.

### Phase 3 — EMP and physics

- [x] Reduce the global `Character.CharacterList` scan cost in the EMP patch with invariant calculations, bounding-box filtering, and inline squared-distance testing.
- [x] Investigate engine-side character-range APIs; no documented LuaCs range query was found, so the global list remains for compatibility.
- [ ] Test Latcher tongue and rope density, stiffness, angular stiffness, and damping.
- [ ] Identify decorative appendage segments that can use `ignorecollisions="True"`.
- [ ] Test reducing crawler-tail and other appendage physics segments without changing gameplay-critical collisions.

### Phase 4 — Item and package cleanup

- [x] Remove repeated `math.randomseed(os.time())` calls from item handlers.
- [x] Seed the shared RNG once during server-side autorun initialization and remove the duplicate module-level seed.
- [x] Remove the unused forced network synchronization helper; no networking references remain in the package.
- [x] Remove seven unused `rejectionchance` calculations from graft insertion/removal handlers.
- [x] Review the item dispatch prefix scan and duplicated transplant-handler logic.
- [ ] Evaluate whether creature overrides can be reduced to minimal or generated override fragments.

Item dispatch and transplant-handler results:

- [x] Converted the seven exact local graft handlers from prefix dispatch to direct identifier lookup.
- [x] Removed the local prefix scan and unused prefix table.
- [x] Refactored graft-aware lung, heart, and liver transplant handlers into delayed delegation wrappers around Neurotrauma's current methods.
- [x] Aligned grafted transplant paths with current Neurotrauma support for both `xxxremoved` and `xxxswap` states.
- [x] Added reusable lung, heart, and liver transplant utilities and routed graft organ-item methods through them.
- [x] Removed redundant transplant-identifier assignments in graft-removal handlers.
- [x] Consolidated repeated donor tag and transplant-condition preparation into shared helpers.
- [x] Removed the obsolete partial `NT.SutureAfflictions` override so current Neurotrauma swap-state handling remains authoritative.
- [x] Added conditional NT Cybernetics Enhanced Forked wrappers for augmented/cybernetic lung, heart, and liver replacement, using its swap-aware base behavior and returning viable graft organs without duplicate generic organs.
- [x] Extended shared organ identification to return and clear augmented/cybernetic lung, heart, and liver items by Cybernetics tier.
- [x] Updated grafted organ-scalpel removal to follow `xxxswap` -> `xxxremoved` and immediately return the viable graft organ.
- [ ] Runtime-test normal organ swaps, graft extraction, Cybernetics replacement, suture behavior, and multiscalpel compatibility.
- [ ] Align package game-version metadata before final profiling.

### Enhanced Husks Humanhusk integration

- [x] Copy the patched Humanhusk definition into `humanTransformations/Humanhusk.xml`.
- [x] Copy `Characters/Humanhusk/Modappendage.xml`.
- [x] Copy all seven Humanhusk sound files referenced by the definition.
- [x] Normalize NT Grafting appendage references to `%ModDir%`.
- [x] Copy the Enhanced Husks FORKED Humanhusk animation and ragdoll files into the fork package.
- [ ] Test Humanhusk behavior with Enhanced Husks FORKED, Enhanced Husks, and neither variant.
- [x] Cure `chimeraHuskInfection` when Husk gene immunity reaches `99` or higher.

### Organ-scalpel override

- [x] Add a delayed graft-specific organ-scalpel override with a 1000 ms initial delay.
- [x] Capture currently registered base methods after the delay.
- [x] Route relevant NT Grafting grafts through the local removal methods.
- [x] Delegate non-grafted organ removal to the captured base methods.
- [x] Avoid copying NT Cybernetics organ-removal implementation into this mod.
- [ ] Test load order with NT Grafting, NT Cybernetics, and other organ patches.
- [ ] Test living, dead, grafted, augmented, and cybernetic organ removal.

## Optimized image inclusion plan

Source:

`C:\Program Files (x86)\Steam\steamapps\common\Barotrauma\LocalMods\NT Grafting Texture Optimization Patch`

Planned handling:

1. Copy the source directory's optimized PNG assets over the corresponding base image files.
2. Preserve the original base paths so existing XML references remain unchanged.
3. Include only the required overwritten image assets in the eventual package.
4. Validate that every copied PNG has a corresponding reference and that all texture tokens resolve within this package.
5. Test the optimized assets separately from runtime Lua/XML changes.

## Verification plan

- [ ] Compare server update performance with no grafts, one grafted character, and several grafted characters.
- [ ] Test repeated EMP explosions with and without Fractal Guardian eye grafts.
- [ ] Test Endworm, Moloch, Latcher, Watcher, and Orangeboy graft behavior.
- [ ] Test multiplayer status synchronization.
- [ ] Test compatibility with the existing NT Grafting Texture Optimization Patch and creature compatibility patches.
- [ ] Confirm that no duplicate drop logic or duplicate overrides are introduced.
- [ ] Add and validate only the optimized overrides needed by this local package.
