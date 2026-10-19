# Rift Gamma / Hulk · 3.0

A distinct Hulk character controller for **Rift Hub · Hero / Villain**, credited to **N0VA_0100**.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/main.lua?cb=" .. tostring(os.time())))()
```

## Original Hulk motion

**Original** is the default. `src/HulkMotion.lua` contains newly authored, interpolated joint keyframes:

- Hunched breathing idle with wide shoulders.
- Heavy walk and run cycles with alternating strides and arm swings.
- Deepening power crouch, leg extension at takeoff, then fists-forward flight.
- Tucked descent and overhead two-fist meteor dive.
- Compressed landing that recovers into the Hulk stance.
- Gamma Roar: a chest-forward pose with arms spreading outward; moving cancels it.

These motions run locally without animation asset IDs or catalog access. They support Motor6D, AnimationConstraint and Bone rigs. Left and right limbs are mirrored; transforms replace the original motion rather than adding rotations on top of it. Cleanup restores only transforms still owned by this controller. Visual fit on a particular avatar still needs live testing.

The prior game animation IDs, CS_Leap/CS_Downslam/KS_ChaseSlam clips, stock idle/walk/fall IDs and borrowed wind sound have been removed from the executable. No web-swing code is loaded or executed. Motion and effect modules are embedded in `main.lua`; the original Rift logo is retained.

## Optional researched catalog pack

**Motion: Catalog** tries the independently researched [Hulk Smash! Animation Pack by Gentle Blox](https://www.roblox.com/bundles/263899055278099/Hulk-Smash-Animation-Pack). Roblox's bundle and asset metadata were checked on **2026-10-19**:

| Motion | Catalog item ID | Roblox asset type |
| --- | --- | --- |
| Idle | `90553825422454` | 51 / IdleAnimation |
| Walk | `137699728035178` | 55 / WalkAnimation |
| Run | `133167141310794` | 53 / RunAnimation |
| Jump | `102511523957119` | 52 / JumpAnimation |
| Fall | `108019215607685` | 50 / FallAnimation |

These are **catalog containers**, not direct Animation/type-24 clip IDs. The asynchronous resolver inspects only Animation references returned by Roblox, destroys imported objects, and never executes model contents. It never passes a container ID straight to LoadAnimation. Denied access, missing clip references, loading errors or rig mismatches use the original motions. It does not bypass ownership or experience permissions.

The pack's listing and item types are verified; its clip content, access and playback in your destination experience are **not verified**. See [the source record](docs/AnimationAssets.json), including direct Roblox metadata URLs. Power charge, meteor, landing and roar use original keyframes in either mode.

## Controls

| Move | Phone | Desktop |
| --- | --- | --- |
| Power leap | Hold POWER LEAP, release | Hold Z, release |
| Quick bound | Tap BOUND | X |
| Meteor dive | Tap METEOR while airborne | C |
| Gamma Roar pose | Tap GAMMA ROAR on the ground | R |
| Air steering | Normal joystick input | Normal movement keys |

Charge for up to 2.2 seconds. At full charge the launch is 300 studs/second forward and 180 upward; a bound uses 105 forward and 85 upward. Meteor dives at 180 downward. A 0.38-second landing pose finishes the move. Air steering turns existing momentum without adding upward lift. Launch direction uses movement input, camera direction, then character facing.

The control panel has a horizontal power meter, distinct leap/bound/meteor controls and a roar button. Drag the header to reposition it. Effects toggles local impact debris, shockwaves, camera response and FOV. It uses no borrowed wind/ambient audio. Gamma Roar is an animation pose, without a voice recording. Close the panel to unload.

These are client movement and visual moves; no server damage is implemented. The script leaves Workspace gravity, normal controls, root anchoring and WalkSpeed alone. It yields its grounded Hulk poses during movement locks, combat/skill states or equipped tools. Other games determine collisions, damage and whether movement is accepted.

## Files and checks

- `main.lua`: full standalone executable.
- `execute.lua`: loader.
- `src/HulkMotion.lua`: original keyframed Hulk motions.
- `src/AnimationCatalog.lua`: researched item IDs and asynchronous reference resolver.
- `src/Pose.lua`: rig discovery, interpolation application, mirrored limbs and transform restoration.
- `src/HulkLeap.lua`: move state machine, input, controls and diagnostics.
- `src/Effects.lua`: bounded visual impact and camera effects.
- `src/Brand.lua`, `assets/`: original user-supplied Rift logo.
- `docs/Hulk_Editor.html`: complete editable code with Copy and Download buttons.
- `docs/AnimationAssets.json`: animation research provenance and verification limits.

**Copy animation report** shows input/move counts, rig details, resolved sources, clip errors, movement observations and runtime errors. Re-execution unloads the previous instance. Disable, death, respawn and movement locks cancel active movement; charging retains exact touch ownership. Keyboard controls ignore processed input and focused text boxes.

```sh
python build.py
LUAU_BIN=/path/to/luau LUAU_COMPILE_BIN=/path/to/luau-compile python tests/run_checks.py
```

The checks cover original animation sampling, no-asset startup, mode switching, denied catalog fallback, container resolution and cleanup, touch ownership, move transitions, steering limits, rig types, effects, and full-script/editor parity. Simulated checks cannot establish the appearance or server acceptance in Roblox.
