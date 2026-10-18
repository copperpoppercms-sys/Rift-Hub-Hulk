# Rift Hub Hulk

Standalone Hulk movement for **Rift Hub · Hero / Villain**, credited to **N0VA_0100**. This character controller is separate from the Survive The Hulk game script.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/main.lua"))()
```

Hold **LEAP** to charge for up to 2.2 seconds. The adjacent bar shows power, and the character crouches farther as charge increases. Release to launch upward and forward. Full charge holds until release; lifting another finger, such as the joystick finger, does not trigger the leap. Drag the header to move the control, and close it to unload.

## Animation handling

- Crouch animation ID: `99086193071059`.
- Leap animation ID: `74116059836265`.
- Clips are primed at normal playback speed with zero weight before use. Their Animation instances remain alive while Roblox loads them.
- **Pose: Auto** uses a clip when it has loaded and its body targets match the rig. A zero-length, failed, mismatched or unverified clip uses a local joint pose instead. Late-loading compatible clips can replace the fallback cleanly.
- **Pose: Built-in** forces the local poses. R15 rigs bend at the hips and knees; R6 rigs use their available torso, hip and shoulder joints.
- **Copy animation report** includes rig type, clip readiness or error, fallback joint count, current phase and movement errors. Copy it after trying a charge and leap.

The original supplied animations may require permission from their owner and must match the avatar rig. This script cannot grant asset access. The built-in poses use Motor6D transforms locally; they restore only transforms still owned by this controller and leave `Animate`, C0, WalkSpeed and player controls alone. Pose appearance and server acceptance of the launch still need live Roblox testing. It does not bypass movement rules or cooldowns.

## Files

- `main.lua`: complete executable standalone script with embedded controller, pose implementation and logo loader.
- `execute.lua`: the short execution snippet.
- `src/HulkLeap.lua`: charge, touch input, animation handling, impulse and lifecycle.
- `src/Pose.lua`: R6/R15 local pose fallback applied after Animator updates, with restoration before the next animation step.
- `src/Brand.lua`, `assets/rift_logo.jpg`, `assets/rift_logo_source.json`: exact user-provided Rift logo and its existing crop.
- `docs/Hulk_Editor.html`: full editable script, Copy all code and Download buttons. Download and open the HTML file to use the editor.
- `tests/`: fixtures for input, animation failures, rig compatibility, pose restoration, startup and cleanup.

## Build and validate

```sh
python build.py
LUAU_BIN=/path/to/luau LUAU_COMPILE_BIN=/path/to/luau-compile python tests/run_checks.py
```

The checks run simulated client behavior and compilation. They do not establish that Roblox authorizes the supplied animation IDs, that every avatar has standard joints, or that a game server accepts the leap.
