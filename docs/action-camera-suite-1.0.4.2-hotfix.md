# Action Camera Suite baked defaults hotfix 1.0.4.2

The package includes the 1.0.4.2 files from `Action Camera Suite - Baked Defaults Hotfix 1.0.4.2.zip` (SHA-256 `1752ebf4e415ee7ac7b9fd76332219497f9d0acefefb57770089da30312e48b9`). All 39 payload files matched the archive's SHA-256 manifest before being copied into `client/`.

The hotfix updates native WXL extension defaults, camera/reticle configuration, and addon defaults. The hotfix changes `WXLReticleTooltipPosition.toc` to load `ReticleTooltipPosition.lua`; the ZIP omitted that Lua file, so the matching 1.0.4 source file from the optional addon bundle is included. The hotfix ZIP's author manifest also lists `!ActionCameraAuthorSettings/Core.lua`, but that file was absent from the archive. The addon is not included, was not present in the repo or live AddOns folder, and the final reticle-tooltip TOC does not depend on it.

Six current Aetheria source overlays were synchronized from the installed source tree: `ActionCameraSettings.h`, `ActionCameraPort.cpp`, `FootIKRig.cpp`, `WaistLantern.cpp`, and the Aetheria Action Camera addon Lua/TOC. This keeps the repository aligned with the installed settings persistence, five presets, F9 reticle control, and Foot IK diagnostics. It does not include executable build outputs.

## Copy/install notes

Use this repository as an overlay for the matching Aetheria x64 client. Back up the existing `Extensions/` and `WTF/WXL/` settings before copying; hotfix defaults replace those files and can overwrite local native settings. Addon SavedVariables are separate. Keep the matching addon files and native extension defaults together.

The owner reports creator permission for bundled third-party addon distribution. The WXL reticle-tooltip addon is credited to Project WXL; no standalone license text was located. This is not a substitute for retaining permission evidence or resolving the existing combined-client GPL compatibility review.

No server files or game data are included. Compile status is unchanged; this repository update adds source/configuration files only. Runtime and visual acceptance remain pending owner testing. No commit or remote push was made as part of this local update.