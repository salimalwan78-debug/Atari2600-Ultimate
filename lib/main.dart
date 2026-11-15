import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
          if (message.message == 'pick') {
            _pickRomFile();
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
        ),
      )
      ..loadFlutterAsset('assets/index.html');
  }

  Future<void> _pickRomFile() async {
    if (_pickingFile) return;
    _pickingFile = true;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['a26', 'bin', 'rom'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        await _sendPickerError('تعذر قراءة الملف المختار. حاول اختيار الملف مرة أخرى.');
        return;
      }

      final encodedBytes = base64Encode(bytes);
      final encodedName = jsonEncode(file.name);
      final encodedData = jsonEncode(encodedBytes);

      await _controller.runJavaScript(
        'window.receiveNativeRom($encodedName, $encodedData);',
      );
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
                            const Icon(
                              Icons.sports_esports,
                              size: 54,
                              color: Color(0xFFFFA726),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'ATARI 2600 ULTIMATE',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                value: _progress == 0 ? null : _progress / 100,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'جارٍ تجهيز منصة الألعاب…',
                              style: TextStyle(color: Colors.white60),
                            ),
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
