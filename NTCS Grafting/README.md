# NT Grafting FORKED

A compatibility-focused fork of **NT Grafting**.

## Status

This fork includes updated compatibility, graft handling, creature drops, Humanhusk support, and performance improvements for NT Grafting.

## Scope

- Reduce unnecessary per-update Lua work.
- Throttle or replace unintervalled XML status effects where gameplay allows.
- Prevent repeated affliction writes and repeated Endworm limb activation.
- Reduce the cost of the EMP character scan.
- Review grafted appendage physics complexity.
- Preserve the existing NT Grafting behavior as closely as possible.
- Use the optimized image assets copied over the base files, without changing XML texture paths.
- Include the copied creature-drop runtime content from **NT Grafting Creature Drop Lua** for the first release.
- Avoid duplicate XML `itemDrops/` definitions.

## Creature drop handling

The runtime content of the separate local workshop item has been copied into this package for the first release:

- Source mod: `NT Grafting Creature Drop Lua`
- Workshop ID: `3787971278`
- Copied file: `Lua/Autorun/ntg_creature_drop.lua`

The copied script remains the source of creature-drop behavior. The separate workshop package's manifest, metadata, and README were not copied, and no original XML `itemDrops/` definitions were added.

## Optimized image source

The planned image source is:

`C:\Program Files (x86)\Steam\steamapps\common\Barotrauma\LocalMods\NT Grafting Texture Optimization Patch`

All 32 optimized PNG assets have been copied over their corresponding base image files and verified with SHA-256 hashes. Their original texture locations are preserved, and the seven explicit package-token references have been normalized to `%ModDir%`. Image dimensions and image-size optimization are outside the current runtime optimization analysis.

## Dependencies

The implementation is intended to depend on the NT Grafting workshop mod:

- Workshop ID: `3534702008`

Creature-drop runtime content has been copied from the separate `NT Grafting Creature Drop Lua` workshop item:

- Workshop ID: `3787971278`
- Copied file: `Lua/Autorun/ntg_creature_drop.lua`

Do not enable the separate drop package alongside this copied version, or the death hook may be registered twice. This package still excludes the original NT Grafting `itemDrops/` files.

## EMP patch

The EMP patch retains `Character.CharacterList` because no documented LuaCs engine-side character range query was available in the installed environment. It reduces per-explosion work by moving invariant calculations outside the loop, rejecting candidates with a bounding-box check, and using an inline squared-distance test. It intentionally does not add Fractal Eye caching or duplicate NT Cybernetics EMP behavior.

## Random number generation

Item handlers no longer reseed the shared Lua RNG. The package seeds it once during server-side autorun initialization, while preserving all existing `math.random` ranges and skill-check probabilities. The Orangeboy random roll also uses the same shared RNG without per-update reseeding.

## Moloch crack accumulation

Moloch crack strength is calculated from the current head-damage event rather than from the character's accumulated trauma thresholds. Damage resistance is applied before the crack amount is calculated, so the result follows the damage actually received. The current coefficients rank blunt trauma highest, gunshot wounds second, and lacerations third. Each damage type contributes up to `30` crack strength, with a combined per-hit cap of `30`.

The crack meter decays by `0.1` per second below the break threshold and continues growing by `0.5` per second after reaching it. The Moloch shell now correctly grows from its initial implanted strength. Runtime testing is still required to tune the coefficients and the post-break cerebral-hypoxia rate.

## Transplant-item spoilage

The repeated spoilage checks on all 28 transplant and cell item definitions now run once every two seconds with `interval="2"` and `disabledeltatime="true"`, losing `1` condition per interval. This gives the requested decay rate of `1` condition per two seconds while avoiding frame-by-frame container and refrigeration checks.

In-game timing validation remains pending for refrigerated storage, medical fabricators, and items outside storage.

## Enhanced Husks Humanhusk integration

The Humanhusk definition from the local NT Grafting + Enhanced Husks patch has been integrated into `humanTransformations/Humanhusk.xml`.

The integration also includes:

- `Characters/Humanhusk/Modappendage.xml`
- The seven referenced Humanhusk sound files under `Characters/Humanhusk/`
- NT Grafting appendage paths normalized to `%ModDir%`
- Humanhusk animations and ragdolls copied from Enhanced Husks FORKED
- The existing local `filelist.xml` Humanhusk entry

Creature-drop definitions remain excluded; the copied runtime script handles the drops.

A character with Husk gene immunity of `99` or higher can now clear `chimeraHuskInfection`. Runtime compatibility testing with Enhanced Husks variants remains pending.

## Item dispatch and transplant handlers

The local graft handlers use direct identifier lookup instead of a prefix scan. Per-organ transplant utility functions provide the current Neurotrauma-style `xxxremoved`/`xxxswap` state handling and are used by the graft organ-item methods and graft-aware transplant paths. The graft-aware lung, heart, and liver transplant handlers are captured and installed as delayed delegation wrappers around Neurotrauma's current `NT.ItemStartsWithMethods` functions; non-grafted cases continue through the captured base methods. Donor tag and transplant-condition preparation is centralized, while normal organ transplantation and graft extraction remain separate to preserve their different surgery, damage, rejection, and inventory behavior.

The obsolete partial `NT.SutureAfflictions` override was removed so current Neurotrauma swap-state handling remains authoritative. Runtime compatibility testing for normal organ swaps, graft extraction, suture behavior, and the multiscalpel remains pending.

## NT Cybernetics compatibility

When NT Cybernetics Enhanced Forked is loaded, the augmented and cybernetic lung, heart, and liver implant methods are wrapped after the same delayed compatibility window. Non-grafted targets delegate to the captured Cybernetics methods. For a grafted target, the wrapper follows the current Cybernetics `swapAffliction` behavior, installs the replacement, and returns the replaced graft organ when viable without also spawning a duplicate generic organ. Shared organ identification also returns and clears the correct augmented or fully cybernetic lung, heart, or liver item. Kidney and brain methods are not wrapped because this package has no corresponding graft organs.

## Organ-scalpel override

The local item script installs a graft-specific organ-scalpel override after a **1000 ms delay**. It captures the organ-scalpel methods registered at that time, allowing NT Grafting and other compatibility patches to define their overrides first.

When the target has a relevant NT Grafting organ affliction, the local graft-removal method is used. Its removal flow follows Neurotrauma's state progression: a viable first incision creates `xxxswap`, and the next scalpel use changes it to `xxxremoved` while returning the viable graft organ to the surgeon. All other organ-removal cases delegate to the captured base method. This does not copy or implement NT Cybernetics organ-removal logic. Installation is guarded against duplicate wrapping and retries delayed method registration a limited number of times.
