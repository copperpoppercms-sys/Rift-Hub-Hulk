# Rift Hulk · 4.1 — native animation and movement

Hulk character controller for **Rift Hub · Hero / Villain**, credited to **N0VA_0100**.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/execute.lua?cb=" .. tostring(os.time())))()
```

## Expanded moveset in 4.1

Seven added movement abilities sit below the original leap controls. The compact dock scales to smaller viewports; buttons animate on hover/press and show remaining cooldowns. Original Rift branding and N0VA_0100 credits remain.

| Ability | Behavior | Keyboard |
| --- | --- | --- |
| Sidestep L / R | Camera-relative sideways burst, 76 studs/sec | Buttons |
| Backstep | Burst away from camera-facing direction, 76 studs/sec | B |
| Gamma Rush | Forward burst, 100 studs/sec | V |
| Sky Leap | Mostly vertical leap, 155 up / 18 forward | G |
| Air Surge | Redirect momentum toward camera, 110–170 forward, at least 45 up | T |
| Air Brake | Reduce horizontal momentum to 18%; preserve vertical speed | Y |

Ground bursts share a 0.65-second cooldown. Sky Leap has a 1.2-second cooldown. Air Surge is available once per owned leap; Air Brake has a 0.8-second cooldown. Air actions require the active leap and an airborne character. All moves respect game input and movement locks. These are requested velocities, not guaranteed travel distances or damage abilities.

Native tracks now blend over 0.16 seconds, with a faster leap start, a heavier slowed ascent, faster meteor playback, and locomotion pace matched to horizontal speed. They reuse the researched clips below; this update does not claim newly authored animation assets. The charge meter has a gamma-green gradient. Shockwaves, rubble and camera effects are decorative; movement uses the real character assembly.

## Native animation behavior

The executable now plays **native AnimationTracks on the character's existing Animator**. The local joint-animation system from v3 is no longer embedded or called. It does not write Motor6D/Bone/AnimationConstraint transforms, create a client-only Animator, or scrub TimePosition to imitate a pose. If a native clip is unavailable, it reports the failure and retains ordinary game animation; there is no local pose substitute.

The movement acts on the real character assembly with ApplyImpulse: charged forward/upward leap, quick bound, bounded horizontal steering, and a downward meteor dive. It does not move a visual clone or teleport a dummy. The game still controls whether movement is accepted.

This uses the same **native animation plus character physics approach** discussed for the reference, with Hulk-specific assets and controls. No Spider-Man/web-swing script is downloaded or executed. The main hub remains a separate UI and launches Hulk only from its card.

## Animation selection and sources

The bank resolves the researched [Hulk Smash! Animation Pack](https://www.roblox.com/bundles/263899055278099/Hulk-Smash-Animation-Pack) and [Hulk Smash! emote](https://www.roblox.com/catalog/131436996931059/Hulk-Smash). These catalog containers are never passed directly to LoadAnimation. Only contained Animation.AnimationId references returned by Roblox are used; imported objects are destroyed and their scripts never run.

While a Hulk reference resolves, or if its clip is denied/unavailable, R15 uses Roblox's documented **Werewolf** creature set. This fallback is named honestly in the report; it is not presented as a verified Hulk animation:

| Motion | Native fallback ID | Verified metadata |
| --- | --- | --- |
| Idle / charge stance | `1083195517` | Werewolf Idle, Animation/type 24, Roblox |
| Walk | `1083178339` | Werewolf Walk, Animation/type 24, Roblox |
| Run | `1083216690` | Werewolf Run, Animation/type 24, Roblox |
| Leap | `1083218792` | Werewolf Jump, Animation/type 24, Roblox |
| Fall | `1083189019` | Werewolf Fall, Animation/type 24, Roblox |
| Emote / meteor pose | `1099492820` | Werewolf Pose, Animation/type 24, Roblox |

Charge plays a slowed, looping native stance instead of a locally scrubbed deep squat. Landing returns animation ownership to the game. R6 reads compatible clips from its current Animate script rather than loading R15 pack clips. Missing R6 clips leave the game's animation alone.

Sources: [Roblox catalog animation reference](https://create.roblox.com/docs/animation/using), [Animator documentation](https://create.roblox.com/docs/reference/engine/classes/Animator), and [asset verification record](docs/AnimationAssets.json). Catalog access and actual playback still depend on Roblox permissions and the rig.

An existing Animator avoids creating a known client-only animation path, but the client cannot prove that Animator's server origin. **Visibility to other players is unverified until tested from a second player/client.** Native tracks provide the appropriate playback path; they do not guarantee that every game's server accepts or replicates them.

## Controls

| Action | Phone | Desktop |
| --- | --- | --- |
| Charged leap | Hold POWER LEAP, release | Hold Z, release |
| Quick bound | BOUND | X |
| Downward meteor | METEOR while airborne | C |
| Native Hulk emote | HULK EMOTE | R |
| Steer during a leap | Normal joystick | Normal movement keys |

Full charge takes 2.2 seconds and requests 300 studs/second forward and 180 upward. Bound requests 105 forward and 85 upward. Meteor requests 180 downward. Holding at full power waits for release; releasing the joystick finger does not release the leap. Normal game movement locks are respected.

Drag the header to reposition the panel. **Animations: On/Off** controls this controller's native tracks. **Effects: On/Off** controls local camera response, debris and shockwaves. Those decorations remain client-side and do not implement server damage. Close the panel to unload.

## Diagnostics and files

Copy animation report includes each loaded clip ID, named source, playing state, clip length and asset errors, plus the move counters and observed character travel. It explicitly leaves observer replication and server movement acceptance unverified.

- `main.lua`: complete native executable; `execute.lua`: checked standalone loader.
- `src/NativeAnimations.lua`: existing-Animator binding, native playback, warmup, failure handling and cleanup.
- `src/AnimationCatalog.lua`: asynchronous Hulk reference resolution and documented native fallbacks.
- `src/HulkLeap.lua`: move state machine, real character impulses, touch/keyboard controls and diagnostics.
- `src/Effects.lua`, `src/Brand.lua`, `assets/`: local decoration and the original user-provided Rift logo.
- `docs/Hulk_Editor.html`: complete editable native script, with Copy and Download.
- `src/Pose.lua` and `src/HulkMotion.lua`: preserved v3 source history only; neither is embedded or called by v4.

Re-execution unloads the previous Hulk instance. Owned tracks, effects and event connections are cleaned up on unload. Existing game animations and Animator instances are never destroyed. The controller leaves Workspace gravity, WalkSpeed, anchoring and normal controls unchanged.

```sh
python build.py
LUAU_BIN=/path/to/luau LUAU_COMPILE_BIN=/path/to/luau-compile python tests/run_checks.py
```

Checks cover native tracks, no local Animator/pose substitute, missing Animator recovery, denied clips, bounded retries, asynchronous catalog resolution, R6 clips, real physics requests, touch ownership, move transitions, cleanup and standalone startup. Compilation, simulated checks and editable-file parity do not substitute for live Roblox or a second-client test.
