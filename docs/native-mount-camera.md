# Native x64 mount camera

This update ports the Action Camera Suite's ground and flying mount-camera behavior to Aetheria's native x64 camera and model paths. It uses the 1.0.4.2 Ground/Flying profiles as tuning references and does not copy x86 addresses or native hooks.

## What the package includes

The current package combines the verified 1.0.4.2 UI/default payload with the Aetheria native Action Camera source follow-ups:

- Per-character camera settings persistence, five save/load/rename preset slots, and the F9 camera/reticle button. Mouse-look remains a temporary session control and is not auto-started on login.
- Reticle behavior, the clearer Foot IK mismatch diagnostic, and the `GetRecord(id, &record)` item-display lookup required by the current client DB API.
- Native ground/flying mount camera framing, smooth profile transitions, follow drift, speed-based FOV, turning lean, and local mount banking.
- The 1.0.4.2 baked defaults, companion addon files and retained upstream notices/credits.

The mount behavior stays behind the existing shoulder-camera and corresponding ground/flying mount toggles. It does not force those options on. Banking is applied to the local player's current mount instance transform; shared model data and other riders are not intended to be modified.

## Native mount profiles

These values are copied from the 1.0.4.2 per-race profiles as tuning references. The supported race files share these values; Aetheria runs the behavior through its native APIs.

| Setting | Ground | Flying |
|---|---:|---:|
| Horizontal / vertical camera offset | -1.01 / 0.35 | 0.00 / -0.05 |
| Base field of view | 70° | 65° |
| Follow / settle time | 1195 / 1053 ms | 2500 / 3000 ms |
| Maximum / forward / vertical drift | 8 / 6 / 0 | 12 / 12 / 12 |
| Moving field-of-view increase / easing | 6° / 5000 ms | 20° / 1622 ms |
| Turn deadzone / intensity / maximum | 15 / 15 / 22° | 11 / 19 / 40° |
| Turn easing / release | 260 / 450 ms | 392 / 905 ms |

Shared transition time is 881 ms. Flying mount bank is capped at 40°, with 303 ms easing and 1075 ms release.

## Source overlay paths

- `client/WoW/Source/UIUtil/MountCameraPolicy.h` — profile values, transition/follow/lean/bank policy.
- `client/WoW/Source/UIUtil/Camera.h` and `Camera.cpp` — per-camera state and profile-driven camera behavior.
- `client/WoW/Source/Object/ObjectClient/Unit_C.cpp` — per-instance local mount banking.
- `client/WoW/Source/UIUtil/ActionCameraSettings.h` and `client/Extensions/ActionCameraPort/src/` — persistent settings, reticle, Foot IK diagnostic and item-display lookup.
- `client/Addons/AetheriaActionCamera/` — per-character SavedVariables and F9 action handling.

Apply these overlays only to the matching Aetheria x64 source. Preserve unrelated source changes and inspect the full-file overlays when applying them to a different revision. Use the guarded four-worker Aetheria build procedure. Back up both launch-name executables and relevant configuration/addon files before local installation. The package contains no compiled executable, server files, database data, or launcher/CDN content.

## Local build and acceptance

The integrated Aetheria x64 build succeeded on 2026-11-04 using four workers. ZERO_CHECK passed; the client build reported 20 warnings and 0 errors. The local executable SHA-256 was `0533aa1826b8ca4b12b88836abede063dceda54e676c7fe8ddf6b51f815b5998`; the binary is not distributed here. The owner reports the first local mount-camera test seems to be working. Detailed gameplay and visual acceptance remains open:

- Ground mount framing and turning lean.
- Flying profile, speed FOV, turn/strafe banking.
- Camera/mount toggle transitions and dismount/reset behavior.
- Confirm non-local mounts are unaffected.
- Separately verify settings across logout/relogin, all five preset save/load/rename actions, camera views A–E, reticle selection, and F9 activation after the panel closes.

The Foot IK change improves mismatch reporting; it does not add Human Female rig support. Full Action Combat and exact draw/reload feedback remain outside this package.