# Rift Hub Hulk · 2.0

Hulk movement for **Rift Hub · Hero / Villain**, credited to **N0VA_0100**. Open it from the main hub's Hulk card, or run the standalone:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/main.lua?cb=" .. tostring(os.time())))()
```

## Moves and controls

| Move | Phone | Keyboard | Behavior |
| --- | --- | --- | --- |
| Charged leap | Hold LEAP, then release | Hold Z, then release | Crouch deeper while charging for 2.2 seconds. Full charge launches at 300 studs/second forward and 180 upward. |
| Quick bound | Tap BOUND | X | Shorter traversal jump at 105 forward and 85 upward, with no charge. |
| Air steering | Move the joystick during your leap | Normal movement keys | Gradually turns existing horizontal momentum; preserves vertical velocity. |
| Downward smash | Tap SMASH while airborne | C | Dives at 180 studs/second downward, reducing forward drift, followed by a heavy landing. |

Launches follow movement input, then the camera's horizontal direction when standing still, then character facing. The last 20% of a charged leap adds a smooth distance boost. Holding at 100% waits for release. Releasing a different finger, including your joystick finger, does not release the leap.

A 0.22-second landing pose finishes each jump before the next leap or bound. It does not disable your normal movement controls. Drag the green control dock by its header. Buttons respond to presses and desktop hover. Close the dock to unload the controller. **Effects: On/Off** controls speed FOV, light camera response, wind and landing debris. **Pose: Auto/Built-in** chooses animation clips or local joint poses.

These are local traversal moves and visual impacts. The script does not implement server damage. Distance, collisions and movement acceptance depend on the game and gravity; the controller does not change Workspace gravity, player controls, WalkSpeed or root anchoring.

## Hulk animations

| Stage | Clip |
| --- | --- |
| Charging crouch | `99086193071059` |
| Leap / bound | CS_Leap `74095507765093` |
| Descent | Fall `180436148` |
| Downward smash | CS_Downslam `113926956994381` |
| Landing | KS_ChaseSlam `107995270438202` |

Idle `180435571` and Walk `180426354` remain available in `RiftHulkCharacter.AnimationIds`; normal game locomotion is preserved. All supplied IDs remain editable in the full file.

Clips require asset access and a compatible rig. Failed, zero-length or mismatched clips use built-in Hulk crouch, airborne, smash and landing poses. Motor6D, AnimationConstraint and Bone rigs are supported; incomplete or newly loaded joints are rescanned. Airborne arm transforms replace animated arm rotations so they cannot stack backward. Only transforms still owned by this controller are restored.

**Copy animation report** includes input counts, phase, move counters, rig discovery, clip status, Roblox asset errors, requested launch velocity, charge, observed local travel and runtime/effect errors. Live playback and server acceptance cannot be established by the simulated tests.

## Reference and implementation

Movement inspiration: [WEB-SWING-SYSTEM-WSS by frigocamelo10-lab](https://github.com/frigocamelo10-lab/WEB-SWING-SYSTEM-WSS/blob/main/Loadstring). The reference was read as text; Rift uses its own Hulk controller with charged launches, directional traversal, speed effects and mobile action controls. No reference code is downloaded or executed at runtime. The reference's wind asset `5813077875` is used at low volume during air movement. Availability depends on Roblox asset access.

- `main.lua`: complete executable with embedded modules; only the existing Rift logo is downloaded.
- `execute.lua`: short loader for the full script.
- `src/HulkLeap.lua`: touch/keyboard input, moves, air steering, animation state machine, compact UI and diagnostics.
- `src/Pose.lua`: rig discovery, Hulk poses, forward arm correction and transform ownership.
- `src/Effects.lua`: capped local shockwaves/debris, bounded FOV response, camera offset and wind. Camera changes are restored only when still owned by this controller.
- `src/Brand.lua`, `assets/rift_logo.jpg`, `assets/rift_logo_source.json`: original Rift logo and crop.
- `docs/Hulk_Editor.html`: complete editable code with Copy, Select all and Download buttons.
- `tests/`: simulated movement, effects, rig, input, failure and cleanup checks.

Death, respawn, game movement locks, focus loss during charging, disable and unload cancel the applicable move and restore owned effects. Re-execution unloads the earlier instance. Keyboard controls ignore processed presses and text entry; phone controls retain exact touch ownership. No synthetic inputs, remote calls or gameplay HUD changes are used.

## Build and validate

```sh
python build.py
LUAU_BIN=/path/to/luau LUAU_COMPILE_BIN=/path/to/luau-compile python tests/run_checks.py
```

The suite compiles all modules and executes simulated checks for release ownership, full-charge scaling, steering limits, action transitions, failure fallback, poses, effects, cleanup and standalone startup. It verifies that the editor contains exactly the executable script. Live Roblox appearance and movement still need in-game testing.
