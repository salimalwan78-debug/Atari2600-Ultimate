# Atari 2600 Ultimate

Arabic-first Android retro game library with a local EmulatorJS runtime.

## Platforms
- Atari 2600 using the Stella 2014 core.
- Nintendo Entertainment System (NES) using the FCEUmm core.

## Features
- Separate Atari, Nintendo NES, and Favorites pages.
- Three persistent visual themes.
- Import personal Atari ROMs (.a26, .bin, .rom) and NES ROMs (.nes).
- Local IndexedDB library for imported games and favorites.
- EmulatorJS runtime and required core data bundled in the APK.
- Local loopback asset server provides an HTTP origin for WebAssembly, fetch, and IndexedDB without depending on a remote CDN.
- Runtime callbacks report when the emulator is ready, when a game starts, and when startup fails; a watchdog reports hangs.
- Free Atari homebrew catalog can be installed manually when internet is available; it is not downloaded automatically at app startup.
- Manual GitHub Actions build only.

## Offline operation
After installing the APK, imported Atari and NES ROMs can be launched without internet. The EmulatorJS loader, JavaScript runtime, CSS, and both normal and legacy core data files are bundled in the APK. Internet is needed only when the user explicitly chooses to download a free catalog game.

## Free game credits and licenses
- 2048 2600 — Carlos Duarte do Nascimento (Chester), MIT: https://github.com/chesterbr/2048-2600
- Cyloid — Keith Adler, MIT: https://github.com/keithadler/cyloid
- Gene Medic — Jason H. Moore, MIT: https://github.com/moorejh28/genemedic
- Ms Snake! — Daniele Olmisani, Luca Olmisani and Maria Segnalini, GPL-3.0: https://github.com/mad4j/atari-mssnake
- Pipes 2600 — Alexandre Luiz Brisighello Filho, MIT: https://github.com/albf/pipes-2600
- Snakes — Robin Sergeant, MIT: https://github.com/RobinSergeant/2600-Snakes

Each catalog entry links to its upstream source and license. SHA-256 is checked before a catalog ROM is stored.

## Automated validation
The manual workflow runs project contract checks, Dart analysis, Flutter tests, JavaScript syntax validation, verifies all required runtime and core payloads are present in the APK, and verifies the APK signature before uploading it. These checks catch packaging and integration regressions; real device gameplay and offline behavior still require testing on a physical Android device.

## Build the APK
1. Open Actions.
2. Select Build Atari 2600 APK.
3. Press Run workflow on main.
4. Enter a version such as V0, V1, or V2.
5. Download the signed APK artifact after all validation steps pass.

The workflow is intentionally manual; ordinary pushes do not trigger builds. Android versionCode increases with the V-number so newer APKs can update older installations signed with the same keystore.

## Technical notes
- EmulatorJS stable runtime files are downloaded during CI and bundled locally.
- Core payloads are downloaded from the stable data directory: stella2014-wasm.data, stella2014-legacy-wasm.data, fceumm-wasm.data, and fceumm-legacy-wasm.data.
- Android serves Flutter assets from a loopback-only HTTP server so WebView can use fetch, IndexedDB and WebAssembly with a local origin.
- No commercial game ROMs are bundled. Users import ROMs they are entitled to use.
- This is an independent community project and is not affiliated with Atari or Nintendo.
