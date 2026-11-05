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
- Upstream credits and license files are preserved.

## Requirements and integration

Requires the Aetheria x64 wowdecomp client source, build dependencies, and legally obtained Wrath 3.3.5a build 12340 data. This is an overlay package, not a complete standalone client or stock-client drop-in.

Copy source overlays under `client/` into corresponding paths of the matching Aetheria x64 source tree. Merge addon folders into `Interface/AddOns`. Include WxlHost.cmake and all ActionCameraPort sources in the native target. Review against the exact Aetheria baseline before building. Use the Aetheria guarded PowerShell 7 client build procedure with four workers. Back up the executable, addons, `Extensions/`, and `WTF/WXL/` settings before installing. The 1.0.4.2 hotfix replaces native WXL default/configuration files under `Extensions/` and `WTF/WXL/`; back these up or merge personal changes before copying. Addon SavedVariables are separate and are not replaced by these defaults.

The local test build and 1.0.4.2 hotfix installation completed 2026-11-04. The repository includes the verified hotfix payload and matching current source overlays. Gameplay and visual acceptance remains pending owner testing.

Full Action Combat, launcher integration, and exact bow draw/reload feedback are outside this package. The 1.0.4.2 reticle-tooltip addon TOC references `ReticleTooltipPosition.lua`; its matching Lua source is included. The author manifest listed a legacy `!ActionCameraAuthorSettings/Core.lua` file that was absent from the hotfix archive; that addon is not included and the installed hotfix does not require it.

## License and credits

Michael Noble gave permission to publish the Action Cam port and source. Keep each upstream license and credit with its files.

No blanket license is asserted over combined files. The native host includes WarcraftXL API headers marked GPL-3.0-or-later while the integrated client baseline has GPL-2 terms. Review licensing compatibility before distributing a combined client.

Not affiliated with or endorsed by Blizzard Entertainment.
