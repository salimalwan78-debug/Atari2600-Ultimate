import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const AtariApp());

class AtariApp extends StatelessWidget {
  const AtariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Atari 2600 Ultimate',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFA726),
          brightness: Brightness.dark,
          surface: const Color(0xFF151923),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        useMaterial3: true,
      ),
      home: const EmulatorHome(),
    );
  }
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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF080A0F))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (value) => setState(() => _progress = value),
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadFlutterAsset('assets/index.html');
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await _handleBack() && mounted) {
          Navigator.of(context).pop();
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
                          const Icon(Icons.sports_esports, size: 54, color: Color(0xFFFFA726)),
                          const SizedBox(height: 18),
                          const Text('ATARI 2600 ULTIMATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                          const SizedBox(height: 20),
                          SizedBox(width: 180, child: LinearProgressIndicator(value: _progress == 0 ? null : _progress / 100)),
                          const SizedBox(height: 10),
                          const Text('جارٍ تجهيز منصة الألعاب…', style: TextStyle(color: Colors.white60)),
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
}
