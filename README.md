# Atari 2600 Ultimate

An Arabic-first Android frontend for Atari 2600, powered by [EmulatorJS](https://github.com/EmulatorJS/EmulatorJS) and its Stella 2014 core.

## Features
- Android application built with Flutter and WebView.
- Arabic right-to-left launcher interface.
- Load Atari 2600 ROM files selected from the device.
- EmulatorJS provides the emulation runtime and on-screen controls.
- Manual APK build through GitHub Actions.

## Build the APK
1. Open the **Actions** tab.
2. Select **Build Atari 2600 APK**.
3. Press **Run workflow** on the `main` branch.
4. Download `Atari2600-Ultimate-APK` from the completed run's Artifacts.

The workflow is intentionally manual so ordinary pushes do not consume build minutes.

## Games and copyright
No commercial ROM images are included. Import only ROMs you created, own, or are otherwise legally authorized to use. The EmulatorJS runtime is loaded from its public stable CDN, so an internet connection is required when starting a game.

## Third-party notices
- EmulatorJS: https://github.com/EmulatorJS/EmulatorJS (GPL-3.0).
- Stella 2014 is the Atari 2600 emulation core used by EmulatorJS.

This is an independent community project and is not affiliated with Atari.
