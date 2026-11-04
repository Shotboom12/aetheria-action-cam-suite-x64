# Aetheria Action Cam Suite x64

Public test source package for AzerothCore Action Camera Suite camera features ported to the Aetheria 64-bit Wrath 3.3.5a client.

This repository contains source overlays and installable addon folders. It does not contain a game client, Blizzard MPQs, proprietary game data, server source, credentials, or build outputs.

## Contents

- `client/Engine` and `client/WoW`: source overlays required by the camera port.
- `client/Extensions/ActionCameraPort`: native x64 camera integration, Hunter cosmetic quiver, waist lantern, nameplate compatibility, and experimental foot placement.
- `client/Extensions/WxlHost`: embedded extension host and dependencies required by ActionCameraPort.
- `client/Addons/AetheriaActionCamera`: camera and reticle addon.
- `client/Interface/AddOns`: 12 tested UI addons from the 1.0.4 public test package.
- Upstream credits and license files are preserved.

## Requirements and integration

Requires the Aetheria x64 wowdecomp client source, build dependencies, and legally obtained Wrath 3.3.5a build 12340 data. This is an overlay package, not a complete standalone client or stock-client drop-in.

Copy source overlays under `client/` into corresponding paths of the matching Aetheria x64 source tree. Merge addon folders into `Interface/AddOns`. Include WxlHost.cmake and all ActionCameraPort sources in the native target. Review against the exact Aetheria baseline before building. Use the Aetheria guarded PowerShell 7 client build procedure with four workers. Back up executable, addons, and WTF settings before installing.

The local test build completed 2026-11-04. Gameplay and visual acceptance remains pending owner testing.

Full Action Combat, launcher integration, and exact bow draw/reload feedback are outside this package. Three optional addons remain excluded.

## License and credits

Michael Noble gave permission to publish the Action Cam port and source. The owner confirms addon creator permission for included third-party addon distribution. Keep each upstream license and credit with its files.

No blanket license is asserted over combined files. The native host includes WarcraftXL API headers marked GPL-3.0-or-later while the integrated client baseline has GPL-2 terms. Review licensing compatibility before distributing a combined client.

Not affiliated with or endorsed by Blizzard Entertainment.
