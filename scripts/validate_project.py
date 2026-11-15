#!/usr/bin/env python3
"""Fast pre-build contract checks for the offline Atari/NES application."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
pubspec = (root / "pubspec.yaml").read_text()
html = (root / "assets/index.html").read_text()
main = (root / "lib/main.dart").read_text()
workflow = (root / ".github/workflows/build-apk.yml").read_text()

errors = []
def require(condition, message):
    if not condition:
        errors.append(message)

for asset_dir in ("cores", "src", "localization", "compression"):
    require(f"assets/emulatorjs/data/{asset_dir}/" in pubspec,
            f"Flutter assets must explicitly include the nested {asset_dir} directory.")
for name in ("loader.js", "emulator.min.js", "emulator.min.css",
             "GameManager.js", "compression.js", "emulator.js", "gamepad.js",
             "nipplejs.js", "shaders.js", "socket.io.min.js", "storage.js",
             "ar-AR.json", "extract7z.js", "extractzip.js",
             "libunrar.js", "libunrar.wasm", "emulator.css", "version.json", "cores.json"):
    require(name in workflow, f"Build workflow must fetch {name}.")
require("for core in stella2014 fceumm gambatte mgba genesis_plus_gx" in workflow,
        "Build workflow must download all six-platform EmulatorJS cores.")
require('file="${core}${variant}-wasm.data"' in workflow,
        "Build workflow must download both normal and legacy core payloads.")
for element in ("atari-panel", "nes-panel", "gb-panel", "gbc-panel", "gba-panel", "genesis-panel", "library-panel", "player-panel", "backup-panel"):
    require(f'id="{element}"' in html, f"Missing required UI section: {element}.")
for marker in ("data-page=\"atari\"", "data-page=\"nes\"", "data-page=\"favorites\""):
    require(marker in html, f"Missing navigation page marker: {marker}.")
for marker in ('data-page="gb"', 'data-page="gbc"', 'data-page="gba"', 'data-page="genesis"', 'data-import-system="gb"', 'data-import-system="gbc"', 'data-import-system="gba"', 'data-import-system="genesis"'):
    require(marker in html, f"Missing platform/import marker: {marker}.")
for feature in ("export-backup", "import-backup", "library-search", "grid-view", "data-key=" + '"ArrowUp"', "saveState:true", "loadState:true"):
    require(feature in html, f"Missing requested feature: {feature}.")
require("window.EJS_core=({atari:'atari2600',nes:'nes',gb:'gb',gbc:'gb',gba:'gba',genesis:'segaMD'})[resolvedSystem]" in html,
        "Game Boy and Game Boy Color must both route to the documented GB system.")
require("window.receiveNativeRom=function(name,base64,launch=true,system=null)" in html,
        "Native import bridge must preserve the selected platform.")
require("EJS_pathtodata='/assets/emulatorjs/data/'" in html,
        "EmulatorJS data path must point to the bundled local asset server.")
require("window.EJS_ready=" in html and "window.EJS_onGameStart=" in html,
        "Runtime must expose documented ready and game-start diagnostics.")
require("launchQueue" in html and "EJS_terminate" in html,
        "Previous EmulatorJS sessions must be terminated before relaunch.")

require("if(activeGameId===id){await stopCurrentEmulator();" in html,
        "Deleting the active game must stop the EmulatorJS session.")
require("document.dispatchEvent(new KeyboardEvent('keydown'" in html and "document.dispatchEvent(new KeyboardEvent('keyup'" in html,
        "Touch controls must dispatch keyboard events through the document event path.")
require("window.releaseTouchInput=release" in html and "lostpointercapture" in html,
        "Touch controls must release held keys when pointer capture is lost.")
require("await SystemNavigator.pop();" in main,
        "Android back handling must exit the app when WebView has no history.")
require("_startupError" in main and "تعذر بدء التطبيق" in main,
        "Local asset server startup failures must be visible to the user.")
require("127.0.0.1" in main and "8765" in main and "rootBundle.load(assetKey)" in main,
        "Flutter must serve bundled assets through its local loopback server.")
require("window.receiveNativeRom" in main and "window.finishNativeBatchImport" in main,
        "Native ROM import bridge is incomplete.")
require("flutter test --no-pub" in workflow,
        "CI must run Flutter tests.")
require("node --check /tmp/app-inline.js" in workflow,
        "CI must validate inline JavaScript syntax.")
require("workflow_dispatch:" in workflow and "\n  push:" not in workflow,
        "Build workflow must remain manual-only.")

# Every inline application script is checked separately by node --check in CI.
if errors:
    print("\n".join(f"ERROR: {item}" for item in errors), file=sys.stderr)
    raise SystemExit(1)
print("Project contract checks passed.")
