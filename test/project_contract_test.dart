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
    expect(html, contains("window.EJS_core=name.toLowerCase().endsWith('.nes')?'nes':'atari2600'"));
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

  test('favorites and theme persistence are present', () {
    expect(html, contains("game.favorite=!game.favorite"));
    expect(html, contains("localStorage.setItem('atari-theme',theme)"));
    expect(html, contains("localStorage.getItem('atari-theme')"));
  });
}
