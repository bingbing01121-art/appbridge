import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:appbridge/appbridge.dart'; // Import Appbridge
import 'dart:io'; // Add this import
import 'package:flutter/services.dart' show rootBundle; // Import rootBundle

class NavWebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final ValueChanged<String>? onPageLoaded; // New callback

  const NavWebViewScreen({super.key, required this.url, this.title = '导航控制', this.onPageLoaded});

  @override
  State<NavWebViewScreen> createState() => _NavWebViewScreenState();
}

class _NavWebViewScreenState extends State<NavWebViewScreen> {
  InAppWebViewController? _webViewController;
  // Use the singleton instance
  final _appbridgePlugin = Appbridge(); // Changed to use singleton
  String _currentTitle = ''; // New: for dynamic title

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title; // Initialize with widget title
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The appbridgePlugin.initialize call is now in onWebViewCreated
  }

  @override
  void dispose() {
    // Emit a resume event when returning to the previous screen
    _appbridgePlugin.emitEvent('app.resume', {});

    if (_webViewController != null) {
      _appbridgePlugin.unregisterWebViewController(
          _webViewController!); // Unregister on dispose
    }
    _appbridgePlugin
        .clearContext(); // Clear context when this screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('NavWebViewScreen: build method called.');

    if (Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_currentTitle),
        ),
        body: InAppWebView(
          onWebViewCreated: (controller) async { // Make async to await rootBundle.loadString
            debugPrint('NavWebViewScreen: onWebViewCreated called for iOS.');
            if (!mounted) return; // Moved here
            _webViewController = controller;
            _appbridgePlugin.registerWebViewController(_webViewController!);

            if (widget.url.startsWith('http://') || widget.url.startsWith('https://')) {
              // If it's an external URL, load it directly
              _webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url))); // Corrected call
            } else {
              // Assume it's a local asset path, load its content
              String htmlContent = await rootBundle.loadString(widget.url); // widget.url is 'packages/appbridge/assets/navigation_test.html'

              // Load the HTML content directly
              _webViewController!.loadData(data: htmlContent, baseUrl: WebUri('about:blank'));
            }

            // Initialize Appbridge for this WebView
            _appbridgePlugin.initialize(
              _webViewController!,
              context,
              onNavClose: () {
                debugPrint('NavWebViewScreen NavCloseCallback: Triggered. Pop current route');
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              onNavReplace: (url, title) {
                debugPrint('NavWebViewScreen NavReplaceCallback: Triggered with url: $url, title: $title');
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        NavWebViewScreen(url: url, title: title),
                  ),
                );
              },
              onNavSetTitle: (title) {
                if (!mounted) return;
                setState(() {
                  _currentTitle = title;
                });
              },
              onLoadUrl: (url, title) async {
                if (!mounted) return;
                _appbridgePlugin.nav?.open(url: url, title: title);
                _appbridgePlugin.ui?.toast(message: '加载URL: $url');
              },
            );
          },
          onLoadStop: (controller, url) async {
            debugPrint('NavWebViewScreen finished loading: $url');
            if (widget.onPageLoaded != null) {
              widget.onPageLoaded!(url.toString());
            }
            await _appbridgePlugin.injectJavaScript();
            _webViewController?.evaluateJavascript(
              source: 'flutterIsReady();',
            );
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint('NavWebViewScreen Console Message: ${consoleMessage.message}');
          },
        ),
      );
    } else {
      // For Android and other platforms (keep existing logic)
      WebUri webUri;
      if (Platform.isAndroid) {
        webUri = WebUri('file:///android_asset/flutter_assets/${widget.url}');
      } else {
        webUri = WebUri(widget.url);
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(_currentTitle),
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: webUri),
          onWebViewCreated: (controller) {
            debugPrint('NavWebViewScreen: onWebViewCreated called.');
            _webViewController = controller;
            _appbridgePlugin.registerWebViewController(_webViewController!);

            if (!mounted) return; // Add this line
            _appbridgePlugin.initialize(
              _webViewController!,
              context,
              onNavClose: () {
                debugPrint('NavWebViewScreen NavCloseCallback: Triggered. Pop current route');
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              onNavReplace: (url, title) {
                debugPrint('NavWebViewScreen NavReplaceCallback: Triggered with url: $url, title: $title');
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        NavWebViewScreen(url: url, title: title),
                  ),
                );
              },
              onNavSetTitle: (title) {
                if (!mounted) return;
                setState(() {
                  _currentTitle = title;
                });
              },
              onLoadUrl: (url, title) async {
                if (!mounted) return;
                _appbridgePlugin.nav?.open(url: url, title: title);
                _appbridgePlugin.ui?.toast(message: '加载URL: $url');
              },
            );
          },
          onLoadStop: (controller, url) async {
            debugPrint('NavWebViewScreen finished loading: $url');
            if (widget.onPageLoaded != null) {
              widget.onPageLoaded!(url.toString());
            }
            await _appbridgePlugin.injectJavaScript();
            _webViewController?.evaluateJavascript(
              source: 'flutterIsReady();',
            );
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint('NavWebViewScreen Console Message: ${consoleMessage.message}');
          },
        ),
      );
    }
  }
}