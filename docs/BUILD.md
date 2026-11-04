# Build notes

Source overlay only. Obtain Aetheria x64 client source and WoW 3.3.5a data separately. Apply overlays under `client/`, include WxlHost.cmake and all ActionCameraPort sources in the native target, then use the existing guarded build procedure with PowerShell 7 and four workers. Back up executable, addons and WTF before installation.

Tested local executable SHA-256: `4e55b1d2fc578cb86600b78afce5cab66bb8cef4188dc6f84978422e4f0480b2`. No executable is included.
