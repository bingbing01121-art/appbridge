import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appbridge_method_channel.dart';

abstract class AppbridgePlatform extends PlatformInterface {
  /// Constructs a AppbridgePlatform.
  AppbridgePlatform() : super(token: _token);

  static final Object _token = Object();

  static AppbridgePlatform _instance = MethodChannelAppbridge();

  /// The default instance of [AppbridgePlatform] to use.
  ///
  /// Defaults to [MethodChannelAppbridge].
  static AppbridgePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppbridgePlatform] when
  /// they register themselves.
  static set instance(AppbridgePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }
}
