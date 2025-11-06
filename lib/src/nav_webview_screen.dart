import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:appbridge/appbridge.dart'; // Import Appbridge

class NavWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const NavWebViewScreen({super.key, required this.url, this.title = '导航控制'});

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
    debugPrint('NavWebViewScreen: build method called.'); // New print statement
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle), // Use _currentTitle
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        onWebViewCreated: (controller) {
          debugPrint(
              'NavWebViewScreen: onWebViewCreated called.'); // New print statement
          _webViewController = controller;
          _appbridgePlugin.registerWebViewController(
              _webViewController!); // Register this controller

          // Initialize Appbridge for this WebView
          _appbridgePlugin.initialize(
            _webViewController!,
            context, // Use the context of NavWebViewScreenState
            onNavClose: () {
              debugPrint(
                  'NavWebViewScreen NavCloseCallback: Triggered. Pop current route');
              Navigator.of(context).pop(); // Pop this screen
            },
            onNavReplace: (url, title) {
              debugPrint(
                  'NavWebViewScreen NavReplaceCallback: Triggered with url: $url, title: $title');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      NavWebViewScreen(url: url, title: title),
                ),
              );
            },
            onNavSetTitle: (title) {
              // New: Handle setTitle callback
              setState(() {
                _currentTitle = title;
              });
            },
            onLoadUrl: (url, title) async {
              _appbridgePlugin.nav
                  ?.open(url: url, title: title); // Pass the title
              _appbridgePlugin.ui?.toast(message: '加载URL: $url');
            },
          );
        },
        onLoadStop: (controller, url) {
          debugPrint('NavWebViewScreen finished loading: $url');
          // The JavaScript polling for initSDK() is now handled by the web page itself.
        },
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint(
              'NavWebViewScreen Console Message: ${consoleMessage.message}');
        },
      ),
    );
  }
}
