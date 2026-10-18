# Rift Hub Hulk

Standalone Hulk movement for **Rift Hub · Hero / Villain**, credited to **N0VA_0100**. This character controller is separate from the Survive The Hulk game script.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/main.lua"))()
```

Hold **LEAP** to charge for up to 2.2 seconds. The adjacent bar shows power, and the character crouches farther as charge increases. Release to launch upward and forward. The final 20% of the charge smoothly adds a long-leap bonus. At 100%, launch velocity reaches 300 studs/second forward and 180 upward (previously 125 and 140). Partial charges through 80% keep their existing strength. Holding past 100% does not increase power or launch until release. Actual distance depends on gravity, terrain, collisions and server movement rules. Full charge holds until release; lifting another finger, such as the joystick finger, does not trigger the leap. Drag the header to move the control, and close it to unload.

## Animation handling

- Crouch animation ID: `99086193071059`.
- Leap animation: **CS_Leap**, ID `74095507765093`.
- Clips are primed at normal playback speed with zero weight before use. They stay alive during a bounded loading window and explicitly regain full weight when used. Their Animation instances remain alive while Roblox loads them.
- **Pose: Auto** uses a clip when it has loaded and its body targets match the rig. A zero-length, failed or clearly mismatched clip uses a local joint pose instead. Clips with unrecognized target names are tried rather than rejected; target compatibility remains unverified. Late-loading compatible clips can replace the fallback cleanly.
- During a leap, shoulders, elbows and wrists use a fixed forward pose after Animator updates, including when CS_Leap plays. These arm transforms replace the animated arm rotation instead of stacking on top of it. The clip still controls the rest of the body; crouching uses its existing animation or fallback. Landing, cancellation and unloading restore the prior arm transforms.
- **Pose: Built-in** forces the local poses. R15 rigs bend at the hips and knees; R6 rigs use their available torso, hip and shoulder joints. Version 1.3 supports legacy `Motor6D`, newer `AnimationConstraint` rigs and skinned `Bone` hierarchies. It rescans newly loaded joints and incomplete attachment bindings.
- **Copy animation report** includes rig type, clip readiness or error, fallback joint count, current phase and movement errors. The report also includes discovered joint types alongside button presses, releases, launch requests, track playback weights, actual pose-write errors and observed local travel after a launch. Roblox log errors are collected only when they mention one of the two supplied animation IDs. Copy it after trying a charge and leap.

The supplied animations may require permission from their owner and must match the avatar rig. This script cannot grant asset access. The built-in poses use writable joint or bone transforms locally; they restore only transforms still owned by this controller and leave `Animate`, C0, WalkSpeed and player controls alone. Pose appearance and server acceptance of the launch still need live Roblox testing. It does not bypass movement rules or cooldowns.

The upstream custom-rig detection changes from commit `6f8825f` are retained.

## Files

- `main.lua`: complete executable standalone script with embedded controller, pose implementation and logo loader.
- `execute.lua`: the short execution snippet.
- `src/HulkLeap.lua`: charge, touch input, animation handling, impulse and lifecycle.
- `src/Pose.lua`: local fallback for Motor6D, AnimationConstraint and Bone rigs applied after Animator updates, with restoration before the next animation step.
- `src/Brand.lua`, `assets/rift_logo.jpg`, `assets/rift_logo_source.json`: exact user-provided Rift logo and its existing crop.
- `docs/Hulk_Editor.html`: full editable script, Copy all code and Download buttons. Download and open the HTML file to use the editor.
- `tests/`: fixtures for input, animation failures, rig compatibility, pose restoration, startup and cleanup.

## Build and validate

```sh
python build.py
LUAU_BIN=/path/to/luau LUAU_COMPILE_BIN=/path/to/luau-compile python tests/run_checks.py
```

The checks run simulated client behavior and compilation. They do not establish that Roblox authorizes the supplied animation IDs, that every avatar has standard joints, or that a game server accepts the leap.

Version 1.4 switches the leap to CS_Leap and adds the full-charge long leap. The existing crouch and joint fallback stay in place. Diagnostics use the configured asset IDs and show the launch charge.

The other supplied IDs are saved in `RiftHulkCharacter.AnimationIds` for future moves: Idle `180435571`, Walk `180426354`, Fall `180436148`, CS_Downslam `113926956994381`, KS_ChaseSlam `107995270438202`. This update only plays CS_Leap during the leap; it does not replace normal locomotion or add slam attacks.

Version 1.5 corrects airborne arm over-rotation. Forward shoulders and bent elbows replace the airborne arm rotation in both clip and fallback modes, without changing launch strength or normal locomotion.
