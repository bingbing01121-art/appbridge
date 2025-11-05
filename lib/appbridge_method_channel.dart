import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appbridge_platform_interface.dart';

/// An implementation of [AppbridgePlatform] that uses method channels.
class MethodChannelAppbridge extends AppbridgePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appbridge');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
