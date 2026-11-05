# Porting the suite to another x64 client

This repository is a source package for Aetheria's customized 64-bit Wrath 3.3.5a client. It is not a binary plugin that can be copied into any 64-bit game folder. Another x64 client can use the feature ideas and some Lua/config assets, but the native camera code must be adapted to that client's source and interfaces.

## Decide what you want to port

- **Lua addons and UI assets:** merge selected folders into the target client's `Interface/AddOns`, check each `.toc` interface version and its dependency list, then test the addon APIs in that client. Do not assume every bundled UI addon works with every 3.3.5a fork.
- **Camera profiles and WXL config defaults:** use these as examples only if the target has the matching native modules and config formats. Merge settings instead of replacing a player's existing `WTF` or extension configuration.
- **Native camera, presets UI, mount framing and banking:** these require native client source integration. A 64-bit executable alone is not sufficient.

For a minimal port, choose one feature group first. The package includes more than the mount camera: per-character settings, five presets, F9 action-camera activation, reticle behavior, Foot IK diagnostics, waist-lantern options and companion addon defaults each have their own source or runtime dependencies.

## Adapt the native code

1. **Pin the target.** Record the exact source repository and commit, 3.3.5a build, compiler/toolchain, x64 ABI, build options, and how the target loads extensions. Confirm you have the source and rights needed to modify and build it.
2. **Map the camera lifecycle.** Find the target's active player camera, update path, camera FOV and view-offset APIs, mount-state transitions, and logout/world teardown behavior. Compare real declarations and call sites in that source; do not infer compatibility from matching class or function names.
3. **Map player and mount identity.** Identify reliable ground-versus-flying state, the local player's GUID, movement/turn inputs, and the mount model instance transform. Apply banking only to the local mount instance after its transform is built. Avoid writing shared model data or changing unrelated units.
4. **Port each interface contract.** The current native extension consumes the `AetheriaActionCameraProfile` Lua table and the `AetheriaActionCameraCenterHover` signal. Its F9 panel and native settings bridge depend on Aetheria's `WxlHost` extension system. Reimplement these contracts through the target's supported addon/native interface, or omit the dependent feature. Do not create fake APIs that only compile but cannot be reached at runtime.
5. **Adapt settings and lifecycle.** Preserve existing camera and mount toggles. Keep per-character SavedVariables separate from global WXL defaults, validate loaded values, and flush settings safely on logout/teardown. Ensure mouse-look activation waits until menus, targeting and cursor capture are clear.
6. **Integrate in the target's build system.** Add only the ported source and required dependencies to the target. Reconfigure and build with that project's documented process. Do not copy the full `Camera.cpp`, `Camera.h`, or `Unit_C.cpp` over a different fork; those are complete Aetheria source overlays and can overwrite unrelated code. Use them as references for small, reviewed patches.

Never reuse the original Action Camera Suite's x86 addresses, signatures, inline assembly or binary hooks in a different x64 executable. Do not turn on arbitrary hooks as a substitute for a verified native API. The source overlays in this repository are tied to Aetheria and may need substantial adaptation for another fork.

## Install and verify on the target client

Keep the game closed for file replacement. Back up the target executable and every addon/config file you change. Install only the newly built executable and the selected addon/config files; keep the backup paths and hashes together. Restore changed files from those backups if the client fails to start or the feature behaves incorrectly. Do not change the target server or database for this client-side camera feature unless a separate dependency is established.

Test in stages on a disposable character/profile before wider use:

1. Build and launch the target client with the feature toggles off; verify existing camera behavior remains intact.
2. On a ground mount, check framing, follow smoothing, speed FOV, turning lean, camera transitions, toggle-off, and dismount reset.
3. On a flying mount, check framing, FOV, turning and strafe banking, transitions, and landing/dismount reset.
4. Confirm banking affects only the local player's current mount; test another nearby mount and passenger/view changes.
5. If ported, verify settings survive logout/relogin, save/load/rename for all five presets, camera views A–E, reticle selection and F9 activation after the settings panel closes.
6. Check logs and target-specific edge cases such as death, vehicle mounts, combat transitions, cursor capture, map changes and reconnects.

Record the target source commit, files changed, build configuration, warnings/errors, executable hash, addon/config hashes, backup/rollback instructions, and which in-game checks passed. A successful compile or addon load is not gameplay acceptance. The Aetheria owner reports the first local mount-camera check seems to work; broader ground/flying and non-local-mount acceptance is still pending, and other clients have not been validated by this repository.

## Compatibility and redistribution

The source package targets the Aetheria 64-bit Wrath 3.3.5a API surface. It does not establish compatibility with other x64 forks, stock clients, or a retail client. `ActionCameraPort` also depends on Aetheria's extension host unless the target supplies an equivalent bridge.

Preserve all upstream licenses, notices, and credits when copying files. Review the target client's licenses and every selected addon/module's terms before distributing a combined client. The package's existing review flags a GPL-3.0-or-later WXL API header alongside the Aetheria GPL-2 client baseline; that compatibility issue remains unresolved for combined-client distribution.