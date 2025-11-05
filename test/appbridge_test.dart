import 'package:flutter_test/flutter_test.dart';
import 'package:appbridge/appbridge.dart';
import 'package:appbridge/appbridge_platform_interface.dart';
import 'package:appbridge/appbridge_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MockAppbridgePlatform
    with MockPlatformInterfaceMixin
    implements AppbridgePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

class MockFlutterLocalNotificationsPlatform extends MockPlatformInterfaceMixin
    implements FlutterLocalNotificationsPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock FlutterLocalNotificationsPlatform
  FlutterLocalNotificationsPlatform.instance = MockFlutterLocalNotificationsPlatform();

  final AppbridgePlatform initialPlatform = AppbridgePlatform.instance;

  test('$MethodChannelAppbridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAppbridge>());
  });

  test('getPlatformVersion', () async {
    Appbridge appbridgePlugin = Appbridge();
    MockAppbridgePlatform fakePlatform = MockAppbridgePlatform();
    AppbridgePlatform.instance = fakePlatform;

    expect(await appbridgePlugin.getPlatformVersion(), '42');
  });
}
