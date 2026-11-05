# Aetheria Action Cam Suite x64

Public test source package for AzerothCore Action Camera Suite camera features ported to the Aetheria 64-bit Wrath 3.3.5a client.

This repository contains source overlays and installable addon folders. It does not contain a game client, Blizzard MPQs, proprietary game data, server source, credentials, or build outputs.

## Contents

- `client/Engine` and `client/WoW`: source overlays required by the camera port.
- `client/Extensions/ActionCameraPort`: native x64 camera integration, Hunter cosmetic quiver, waist lantern, nameplate compatibility, and experimental foot placement.
- `client/Extensions/WxlHost`: embedded extension host and dependencies required by ActionCameraPort.
- `client/Addons/AetheriaActionCamera`: camera and reticle addon.
- `client/Interface/AddOns`: the tested UI addons from the 1.0.4 package, plus the WXL reticle-tooltip position addon required by hotfix 1.0.4.2.
- 1.0.4.2 baked defaults for native WXL extensions, companion UI addons, and reticle-tooltip placement.
- Per-character camera settings and five editable presets, F9 camera/reticle activation, and native ground/flying mount-camera behavior.
- Upstream credits and license files are preserved.

## Requirements and integration

Requires the Aetheria x64 wowdecomp client source, build dependencies, and legally obtained Wrath 3.3.5a build 12340 data. This is an overlay package, not a complete standalone client or stock-client drop-in. The native port currently targets Aetheria's x64 APIs; another x64 client is not a drop-in target. A client developer can adapt the source to a compatible fork using the [porting guide](docs/porting-to-other-x64-clients.md).

Copy source overlays under `client/` into corresponding paths of the matching Aetheria x64 source tree. Merge addon folders into `Interface/AddOns`. Include WxlHost.cmake and all ActionCameraPort sources in the native target. Review against the exact Aetheria baseline before building. Use the Aetheria guarded PowerShell 7 client build procedure with four workers. Back up the executable, addons, `Extensions/`, and `WTF/WXL/` settings before installing. The 1.0.4.2 hotfix replaces native WXL default/configuration files under `Extensions/` and `WTF/WXL/`; back these up or merge personal changes before copying. Addon SavedVariables are separate and are not replaced by these defaults.

The local x64 build including the native mount-camera update completed on 2026-11-04 with the guarded four-worker process (20 warnings, 0 errors). Its executable SHA-256 was `0533aa1826b8ca4b12b88836abede063dceda54e676c7fe8ddf6b51f815b5998`; no executable is included here. The owner reports the first local mount-camera test seems to be working; detailed ground, flight, transition, and non-local-mount acceptance remains pending. See [native mount camera notes](docs/native-mount-camera.md) for integration and test scope.

Full Action Combat, launcher integration, and exact bow draw/reload feedback are outside this package. The 1.0.4.2 reticle-tooltip addon TOC references `ReticleTooltipPosition.lua`; its matching Lua source is included. The author manifest listed a legacy `!ActionCameraAuthorSettings/Core.lua` file that was absent from the hotfix archive; that addon is not included and the installed hotfix does not require it.

## License and credits

Michael Noble gave permission to publish the Action Cam port and source. Keep each upstream license and credit with its files.

No blanket license is asserted over combined files. The native host includes WarcraftXL API headers marked GPL-3.0-or-later while the integrated client baseline has GPL-2 terms. Review licensing compatibility before distributing a combined client.

Not affiliated with or endorsed by Blizzard Entertainment.
