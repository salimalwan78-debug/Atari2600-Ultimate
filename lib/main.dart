import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const AtariApp());

class AtariApp extends StatelessWidget {
  const AtariApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Atari 2600 Ultimate',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFA726),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0B0E14),
          useMaterial3: true,
        ),
        home: const EmulatorHome(),
      );
}

class EmulatorHome extends StatefulWidget {
  const EmulatorHome({super.key});

  @override
  State<EmulatorHome> createState() => _EmulatorHomeState();
}

class _EmulatorHomeState extends State<EmulatorHome> {
  late final WebViewController _controller;
  HttpServer? _assetServer;
  bool _loading = true;
  int _progress = 0;
  bool _pickingFile = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF080A0F))
      ..addJavaScriptChannel(
        'NativeFilePicker',
        onMessageReceived: (message) {
          if (message.message == 'pick' ||
              message.message == 'pick:nes' ||
              message.message == 'pick:atari:multiple') {
            _pickRomFile(
              nesOnly: message.message == 'pick:nes',
              multiple: message.message == 'pick:atari:multiple',
            );
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() => _loading = false);
            }
          },
        ),
      );
    _loadLocalWebApp();
  }

  Future<void> _loadLocalWebApp() async {
    try {
      // A loopback HTTP origin supports fetch(), IndexedDB and WebAssembly
      // while keeping every app resource local and available offline.
      _assetServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _assetServer!.listen(_serveAsset);
      final uri = Uri(
        scheme: 'http',
        host: '127.0.0.1',
        port: _assetServer!.port,
        path: '/assets/index.html',
      );
      await _controller.loadRequest(uri);
    } catch (error) {
      if (mounted) setState(() => _loading = false);
      debugPrint('Local asset server failed: $error');
    }
  }

  Future<void> _serveAsset(HttpRequest request) async {
    final response = request.response;
    try {
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
        return;
      }
      final decodedPath = Uri.decodeComponent(request.uri.path);
      if (!decodedPath.startsWith('/assets/') ||
          decodedPath.split('/').any((part) => part == '..' || part == '.')) {
        response.statusCode = HttpStatus.notFound;
        return;
      }
      final assetKey = decodedPath.substring(1);
      final data = await rootBundle.load(assetKey);
      response.headers.set(
        HttpHeaders.contentTypeHeader,
        _contentType(assetKey),
      );
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      response.headers.set('X-Content-Type-Options', 'nosniff');
      if (request.method == 'HEAD') {
        response.contentLength = data.lengthInBytes;
      } else {
        response.add(data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        ));
      }
    } on FlutterError {
      response.statusCode = HttpStatus.notFound;
    } catch (error) {
      response.statusCode = HttpStatus.internalServerError;
      debugPrint('Asset request failed for ${request.uri}: $error');
    } finally {
      await response.close();
    }
  }

  String _contentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.html')) return 'text/html; charset=utf-8';
    if (lower.endsWith('.js')) return 'application/javascript; charset=utf-8';
    if (lower.endsWith('.css')) return 'text/css; charset=utf-8';
    if (lower.endsWith('.wasm')) return 'application/wasm';
    if (lower.endsWith('.json')) return 'application/json; charset=utf-8';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.woff2')) return 'font/woff2';
    return 'application/octet-stream';
  }

  Future<void> _pickRomFile({bool nesOnly = false, bool multiple = false}) async {
    if (_pickingFile) return;
    _pickingFile = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: nesOnly
            ? const ['nes']
            : const ['a26', 'bin', 'rom'],
        allowMultiple: multiple,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      if (multiple) {
        var imported = 0;
        var skipped = 0;
        for (final file in result.files) {
          final bytes = file.bytes;
          if (bytes == null || bytes.isEmpty) {
            skipped++;
            continue;
          }
          final encodedName = jsonEncode(file.name);
          final encodedData = jsonEncode(base64Encode(bytes));
          await _controller.runJavaScript(
            'await window.receiveNativeRom($encodedName, $encodedData, false);',
          );
          imported++;
        }
        await _controller.runJavaScript(
          'await window.finishNativeBatchImport($imported, $skipped);',
        );
      } else {
        final file = result.files.single;
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          await _sendPickerError('تعذر قراءة الملف المختار. حاول اختيار الملف مرة أخرى.');
          return;
        }
        final encodedName = jsonEncode(file.name);
        final encodedData = jsonEncode(base64Encode(bytes));
        await _controller.runJavaScript(
          'await window.receiveNativeRom($encodedName, $encodedData);',
        );
      }
    } catch (error) {
      await _sendPickerError('تعذر استيراد اللعبة: $error');
    } finally {
      _pickingFile = false;
    }
  }

  Future<void> _sendPickerError(String message) async {
    if (!mounted) return;
    await _controller.runJavaScript(
      'window.showNativePickerError(${jsonEncode(message)});',
    );
  }

  @override
  void dispose() {
    _assetServer?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final navigator = Navigator.of(context);
          final canGoBack = await _controller.canGoBack();
          if (!mounted) return;
          if (canGoBack) {
            await _controller.goBack();
          } else {
            navigator.maybePop();
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading)
                  Positioned.fill(
                    child: ColoredBox(
                      color: const Color(0xFF0B0E14),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sports_esports,
                                size: 54, color: Color(0xFFFFA726)),
                            const SizedBox(height: 18),
                            const Text('ATARI 2600 ULTIMATE',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2)),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                value: _progress == 0 ? null : _progress / 100,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('جارٍ تجهيز منصة الألعاب…',
                                style: TextStyle(color: Colors.white60)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
