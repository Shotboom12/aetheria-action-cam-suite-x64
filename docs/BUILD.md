# Build notes

This is a source overlay package, not a standalone client. Obtain the matching Aetheria x64 client source and legally obtained WoW 3.3.5a (12340) data separately. Apply source overlays under `client/`; merge addon folders into `Interface/AddOns`. Include `WxlHost.cmake` and all `ActionCameraPort` sources in the native target. Review the overlays against the exact Aetheria source baseline before building; these are not stock-client patches.

Use Aetheria's guarded PowerShell 7 build procedure with exactly four workers. The local integrated build containing these overlays succeeded on 2026-11-04: ZERO_CHECK passed, 20 warnings, 0 errors. Output executable SHA-256: `0533aa1826b8ca4b12b88836abede063dceda54e676c7fe8ddf6b51f815b5998`. This records the local integrated build only; no executable or build output is included in this repository.

Before installing, back up the executable, addon folders, `Extensions/`, and `WTF/WXL/`. The 1.0.4.2 hotfix replaces native WXL defaults/configuration and companion addon files; merge personal settings where needed. Addon SavedVariables are per-character and are not replaced by those defaults.

Compilation does not establish visual/gameplay acceptance. The owner reports the first local native mount-camera check seems to work; the listed ground/flying, transition, and non-local mount checks remain open in [native mount camera notes](native-mount-camera.md).