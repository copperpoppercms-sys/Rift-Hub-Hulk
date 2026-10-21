# Rift Hulk · 4.2

Standalone Hulk controller for Rift Hub · Hero / Villain. Credits: **N0VA_0100**.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/execute.lua?cb=" .. tostring(os.time())))()
```

## Charge and movement

Holding POWER LEAP now visibly bends the hips/knees, lowers the torso and brings the arms into a charge stance. The crouch gets deeper as the meter fills and clears on release, cancellation, death, respawn or unload. This authored **charge-only pose is local**; visibility to other players is not claimed. It supports named Motor6D, AnimationConstraint and Bone joints. Unsupported custom rigs retain their native stance and report the missing binding. It never changes HipHeight or locks normal controls.

Native AnimationTracks on the character's existing Animator still handle idle, locomotion, leap, fall, meteor and the emote. No client-only Animator is created. The charge pose is isolated from airborne playback so arms do not retain the crouch offset after takeoff.

Sidesteps, Backstep and Gamma Rush have been removed.

| Action | Behavior | Key |
| --- | --- | --- |
| Power Leap | Hold to charge, release to launch; full charge requests 300 forward / 180 up | Z |
| Bound | Quick forward/upward leap | X |
| Meteor | Dive downward during an active leap | C |
| Hulk Emote | Native pose; move to cancel | R |
| Super Speed | Toggle running speed to at least 52 studs/sec; steer normally | V |
| Overdrive | Three-second burst at at least 90 studs/sec; eight-second cooldown | B |
| Sky Leap | Mostly vertical leap: 155 up / 18 forward | G |
| Air Surge | Redirect momentum toward the camera once per leap | T |
| Air Brake | Reduce horizontal momentum to 18%, preserving vertical speed | Y |
| Feather Fall | Four-second controlled descent; downward speed limited to 25 | H |

Every ability has a phone button. Hold/release leap tracks the specific touch, so releasing the joystick finger does not trigger it. The dock scales for smaller viewports and its header is draggable. Native movement tracks blend between actions and match playback speed to locomotion. Effects toggle controls local camera response, rubble and shockwaves, which are decorations and do not implement damage.

Super Speed and Overdrive restore the prior WalkSpeed when toggled off, expired, charging, respawning or unloading. If the game changes WalkSpeed, ownership is relinquished and that game value is preserved instead of being overwritten repeatedly. Overdrive replaces an active speed toggle and returns to normal when it ends. Feather Fall ends on landing/cancellation and does not interfere with Meteor. Game movement/input locks are respected.

These are requested client movement changes. Games may restrict or correct them; neither server acceptance nor visibility from another player has been verified. No anti-cheat bypass or damage mechanism is included.

## Animation assets

The bank tries the researched [Hulk Smash! Animation Pack](https://www.roblox.com/bundles/263899055278099/Hulk-Smash-Animation-Pack) and [Hulk Smash! emote](https://www.roblox.com/catalog/131436996931059/Hulk-Smash). Catalog containers are resolved to contained Animation references; imported objects are destroyed and scripts are never executed.

When unavailable, R15 uses Roblox's documented Werewolf creature set: idle `1083195517`, walk `1083178339`, run `1083216690`, jump `1083218792`, fall `1083189019`, pose `1099492820`. This is named as a fallback, not claimed to be a verified Hulk clip. R6 reads its current game's compatible Animate clips. Missing animations are reported; the authored crouch can still operate independently of asset access.

Sources: [Roblox animation reference](https://create.roblox.com/docs/animation/using), [Animator documentation](https://create.roblox.com/docs/reference/engine/classes/Animator), [metadata record](docs/AnimationAssets.json).

## Files and validation

- `main.lua`: full executable; `execute.lua`: checked loader.
- `docs/Hulk_Editor.html`: complete editable script with Copy / Select / Download.
- `src/HulkLeap.lua`: controls, moves, speed ownership and diagnostics.
- `src/NativeAnimations.lua`, `src/AnimationCatalog.lua`: native playback and fallbacks.
- `src/ChargePose.lua`: charge-only authored crouch, with owned transform cleanup.
- `src/Effects.lua`, `src/Brand.lua`: local effects and original Rift logo.
- `src/Pose.lua`, `src/HulkMotion.lua`: historical v3 modules, not embedded or called.

Re-execution unloads the previous instance. Tracks, crouch offsets, speed changes, effects and event listeners owned by this controller are cleaned up. Copy animation report includes asset errors, move state, speed mode and observed local movement.

```sh
python build.py
LUAU_BIN=/path/to/luau LUAU_COMPILE_BIN=/path/to/luau-compile python tests/run_checks.py
```

Simulated checks cover asset fallbacks, touch ownership, impulses, charge depth and restoration, speed toggling/expiration, preservation of game overrides, air limits, locks, respawn and cleanup. Live Roblox playback, real physics and a second-client observation still need in-game testing.
