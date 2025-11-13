import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Added for CupertinoActionSheet
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'base_module.dart';
import '../models/bridge_response.dart';
import '../../appbridge.dart';

/// UI模块实现
class UIModule extends BaseModule {
  OverlayEntry? _loadingOverlayEntry;

  UIModule();

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'toast':
        return await _toast(params);
      case 'alert':
        return await _alert(params);
      case 'confirm':
        return await _confirm(params);
      case 'actionSheet':
        return await _actionSheet(params);
      case 'loading':
        return await _loading(params);
      case 'haptics':
        return await _haptics(params);
      case 'safeArea':
        return await _safeArea();
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _toast(Map<String, dynamic> params) async {
    final text = params['text'] as String?;
    try {
      Fluttertoast.showToast(msg: text.toString());
      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  // Public toast method
  Future<void> toast({required String message, int duration = 2000}) async {
    try {
      Fluttertoast.showToast(
        msg: message,
        toastLength: duration <= 2000 ? Toast.LENGTH_SHORT : Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: (duration / 1000).round(),
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      debugPrint('Error showing toast: $e');
    }
  }

  Future<BridgeResponse> _alert(Map<String, dynamic> params) async {
    try {
      final title = params['title'] as String?;
      final message = params['message'] as String? ?? '';
      final okText = params['okText'] as String? ?? '确定';

      final currentContext = Appbridge().context;
      if (currentContext == null) {
        return BridgeResponse.error(
            -1, 'No valid BuildContext available for UI operations.');
      }

      await showDialog<void>(
        // Added showDialog call
        context: currentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: title != null ? Text(title) : null,
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: Text(okText),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ); // Added closing parenthesis and semicolon
      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _confirm(Map<String, dynamic> params) async {
    try {
      final title = params['title'] as String?;
      final message = params['message'] as String? ?? '';
      final okText = params['okText'] as String? ?? '确定';
      final cancelText = params['cancelText'] as String? ?? '取消';

      final currentContext = Appbridge().context;
      if (currentContext == null) {
        return BridgeResponse.error(
            -1, 'No valid BuildContext available for UI operations.');
      }

      final bool? result = await showDialog<bool>(
        context: currentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: title != null ? Text(title) : null,
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: Text(cancelText),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(okText),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );
      return BridgeResponse.success({'ok': result ?? false});
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _actionSheet(Map<String, dynamic> params) async {
    try {
      final title = params['title'] as String?;
      final items = params['items'] as List<dynamic>? ?? [];

      final currentContext = Appbridge().context;
      if (currentContext == null) {
        return BridgeResponse.error(
            -1, 'No valid BuildContext available for UI operations.');
      }

      final String? selectedId = await showModalBottomSheet<String>(
        context: currentContext,
        builder: (BuildContext context) {
          return CupertinoActionSheet(
            title: title != null
                ? Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            actions: items.map((item) {
              return CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop(item['id'] as String?);
                },
                child: Text(
                  item['text'] as String? ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消', style: TextStyle(fontSize: 16)),
            ),
          );
        },
      );
      return BridgeResponse.success({'id': selectedId});
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _loading(Map<String, dynamic> params) async {
    try {
      final visible = params['visible'] as bool? ?? true;
      final text = params['text'] as String? ?? '加载中...';

      if (visible) {
        if (_loadingOverlayEntry != null) {
          // If already showing, update text
          // For simplicity, we'll just return success if already visible.
          return BridgeResponse.success(true);
        }

        _loadingOverlayEntry = OverlayEntry(
          builder: (context) => Stack(
            children: [
              // Darken background with a subtle blur effect (if possible, otherwise just darken)
              ModalBarrier(
                dismissible: true, // Allow dismissing by tapping outside
                color: Colors.black.withAlpha((255 * 0.5).round()),
                onDismiss: () {
                  _loadingOverlayEntry?.remove();
                  _loadingOverlayEntry = null;
                },
              ),
              Center(
                child: Material(
                  color: Colors.transparent,
                  // Make Material transparent to show custom background
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((255 * 0.9).round()),
                      // Slightly transparent white background
                      borderRadius: BorderRadius.circular(12),
                      // Slightly larger border radius
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.1).round()),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CupertinoActivityIndicator(radius: 15),
                        // iOS-style loading indicator
                        const SizedBox(height: 15),
                        // Increased spacing
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 15.0, // Slightly larger font size
                            color: Colors.grey[800], // Darker text color
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        final currentContext = Appbridge().context;
        if (currentContext == null) {
          return BridgeResponse.error(
              -1, 'No valid BuildContext available for UI operations.');
        }
        Overlay.of(currentContext)
            .insert(_loadingOverlayEntry!); // Use currentContext here

        // Return a function to dismiss the loading indicator
        return BridgeResponse.success(() {
          _loadingOverlayEntry?.remove();
          _loadingOverlayEntry = null;
        });
      } else {
        _loadingOverlayEntry?.remove();
        _loadingOverlayEntry = null;
        return BridgeResponse.success(true);
      }
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _haptics(Map<String, dynamic> params) async {
    try {
      final style = params['style'] as String? ?? 'light';
      debugPrint("AAA震动样式style==$style");
      switch (style) {
        case 'light':
          HapticFeedback.lightImpact();
          break;
        case 'medium':
          HapticFeedback.mediumImpact();
          break;
        case 'heavy':
          HapticFeedback.heavyImpact();
          break;
        default:
          HapticFeedback.lightImpact();
      }

      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _safeArea() async {
    final currentContext = Appbridge().context;
    if (currentContext == null) {
      return BridgeResponse.error(
          -1, 'No valid BuildContext available for UI operations.');
    }

    final MediaQueryData mediaQuery = MediaQuery.of(currentContext);
    final EdgeInsets viewInsets = mediaQuery.viewInsets;
    final EdgeInsets viewPadding = mediaQuery.viewPadding;

    return BridgeResponse.success({
      'top': viewPadding.top,
      'bottom': viewPadding.bottom,
      'left': viewPadding.left,
      'right': viewPadding.right,
      'keyboardTop': viewInsets.top,
      'keyboardBottom': viewInsets.bottom,
      'keyboardLeft': viewInsets.left,
      'keyboardRight': viewInsets.right,
    });
  }

  @override
  List<String> getCapabilities() {
    return [
      'ui.toast',
      'ui.alert',
      'ui.confirm',
      'ui.actionSheet',
      'ui.loading',
      'ui.haptics',
      'ui.safeArea',
    ];
  }
}
