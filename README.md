# Atari 2600 Ultimate

An Arabic-first Android frontend for Atari 2600, powered by EmulatorJS and its Stella 2014 core.

## Features
- Flutter Android app with Arabic RTL interface.
- Six freely redistributable Atari 2600 homebrew games are offered in the in-app catalog: 2048 2600, Cyloid, Gene Medic, Ms Snake!, Pipes 2600, and Snakes.
- The six catalog ROMs are downloaded from their original developer repositories on first launch, checked against published SHA-256 hashes, and stored locally in the app's IndexedDB library.
- Each game displays developer credit, source repository, and its license link.
- Import personal A26, BIN, and ROM files; manage favorites and delete games.
- EmulatorJS on-screen touch controls.
- Manual APK build through GitHub Actions only.

## Free game credits and licenses
- 2048 2600 — Carlos Duarte do Nascimento (Chester), MIT: https://github.com/chesterbr/2048-2600
- Cyloid — Keith Adler, MIT: https://github.com/keithadler/cyloid
- Gene Medic — Jason H. Moore, MIT: https://github.com/moorejh28/genemedic
- Ms Snake! — Daniele Olmisani, Luca Olmisani and Maria Segnalini, GPL-3.0: https://github.com/mad4j/atari-mssnake
- Pipes 2600 — Alexandre Luiz Brisighello Filho, MIT: https://github.com/albf/pipes-2600
- Snakes — Robin Sergeant, MIT: https://github.com/RobinSergeant/2600-Snakes

ROM files are fetched directly from their original project locations. The app verifies each file's SHA-256 checksum before storing it. The relevant upstream license is linked in the app beside each game. If a download is unavailable or its checksum differs, that game is not installed.

## Build the APK
1. Open Actions.
2. Select **Build Atari 2600 APK**.
3. Press **Run workflow** on `main`.
4. Download the `Atari2600-Ultimate-APK` artifact from the completed run.

The workflow is intentionally manual; ordinary pushes do not trigger builds.

## Emulator and copyright
The app uses EmulatorJS with the Stella 2014 Atari 2600 core. No commercial Atari ROMs are included. Imported personal ROM files remain local to the device. Internet access is required to download the free catalog games on first launch and to load the EmulatorJS runtime when starting a game.

This is an independent community project and is not affiliated with Atari.
