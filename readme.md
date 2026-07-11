# Chromium-for-windows-7-REWORK auto updater

Just NSIS based automatic updater for [Chromium-for-windows-7-REWORK](https://github.com/e3kskoy7wqk/Chromium-for-windows-7-REWORK) just like how Google Chrome updater via GitHub api fetch.

## Plugins

- [nsExec](https://nsis.sourceforge.io/NsExec_plug-in) (Silent process spawning)
- [w7tbp](https://nsis.sourceforge.io/TaskbarProgress_plug-in) (Optional, for taskbar progress)

## External Bundled Tools

- [curl](https://github.com/lordmulder/cURL-build-win32) (32 bit version for legacy Windows)
- [aria2](https://github.com/aria2/aria2) (For multithreaded downloading)
- [jq](https://github.com/jqlang/jq) (For parsing JSON)

Windows 7 compatible, Vista & XP not tested [yet](https://github.com/e3kskoy7wqk/Chromium-for-windows-7-REWORK/issues/6).

## Usage

```shell
# Silent install/update
updater.exe /S

# Update with beta channel
updater.exe /channel=beta

# Force install (will uninstall current)
updater.exe /force

# Force install and remove user data
updater.exe /force /clearuserdata
```

You also can manually register autorun or task scheduler.
