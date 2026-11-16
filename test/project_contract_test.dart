import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String html;

  setUpAll(() async {
    html = await rootBundle.loadString('assets/index.html');
  });

  test('separate Atari, NES and Favorites navigation exists', () {
    expect(html, contains('data-page="atari"'));
    expect(html, contains('data-page="nes"'));
    expect(html, contains('data-page="favorites"'));
    expect(html, contains('id="atari-panel"'));
    expect(html, contains('id="nes-panel"'));
  });

  test('emulator assets are loaded from the local bundled origin', () {
    expect(html, contains("window.EJS_pathtodata='/assets/emulatorjs/data/'"));
    expect(html, isNot(contains('EJS_pathtodata="https://')));
    expect(html, contains("window.EJS_core=({atari:'atari2600',nes:'nes',gb:'gb',gbc:'gb',gba:'gba',genesis:'segaMD'})[resolvedSystem]"));
  });

  test('emulator lifecycle and diagnostics are configured', () {
    expect(html, contains('window.EJS_terminate'));
    expect(html, contains('window.EJS_ready='));
    expect(html, contains('window.EJS_onGameStart='));
    expect(html, contains("addEventListener('unhandledrejection'"));
    expect(html, contains('launchWatchdog'));
  });

  test('native batch import waits for queued persistence', () {
    expect(html, contains('let nativeImportQueue=Promise.resolve()'));
    expect(html, contains('await nativeImportQueue'));
    expect(html, contains('await storeGame(game)'));
  });

  test('active game deletion stops the emulator and clears touch state', () {
    expect(html, contains('if(activeGameId===id){await stopCurrentEmulator();'));
    expect(html, contains('activeGameId=null'));
    expect(html, contains('window.releaseTouchInput=release'));
  });

  test('touch controls dispatch keyboard events through document', () {
    expect(html, contains("document.dispatchEvent(new KeyboardEvent('keydown'"));
    expect(html, contains("document.dispatchEvent(new KeyboardEvent('keyup'"));
    expect(html, contains("'Space'"));
    expect(html, contains('lostpointercapture'));
  });

  test('all requested systems, controls, backup and save states are present', () {
    for (final page in ['atari', 'nes', 'gb', 'gbc', 'gba', 'genesis']) {
      expect(html, contains('data-page="$page"'));
    }
    for (final platform in ['gb', 'gbc', 'gba', 'genesis']) {
      expect(html, contains('data-import-system="$platform"'));
    }
    expect(html, contains('export-backup'));
    expect(html, contains('import-backup'));
    expect(html, contains('saveState:true'));
    expect(html, contains('loadState:true'));
    expect(html, contains("window.EJS_gameName=resolvedSystem+'-'+name.replace"));
    expect(html, contains('let restored=0,skipped=0'));
    expect(html, contains('data-key="ArrowUp"'));
    expect(html, contains('accept=".a26,.bin,.rom,application/octet-stream"'));
    expect(html, isNot(contains('accept=".a26,.bin,.rom,.nes,application/octet-stream"')));
  });

  test('favorites and theme persistence are present', () {
    expect(html, contains("game.favorite=!game.favorite"));
    expect(html, contains("localStorage.setItem('atari-theme',theme)"));
    expect(html, contains("localStorage.getItem('atari-theme')"));
  });
}
