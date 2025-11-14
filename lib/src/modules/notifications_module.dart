import 'package:flutter/material.dart';
import 'base_module.dart';
import '../models/bridge_response.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert'; // Import for jsonEncode

/// Notifications模块实现
typedef EventEmitter = Future<void> Function(
    String event, dynamic payload); // Define EventEmitter here

class NotificationsModule extends BaseModule {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final EventEmitter _eventEmitter; // Store the event emitter

  NotificationsModule(this._eventEmitter) {
    // Accept EventEmitter in constructor
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/icon_h5sdk_new');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        // This callback is triggered when a notification is tapped
        final String? payload = notificationResponse.payload;
        // Add this line
        _eventEmitter('notifications.click', {
          'id': notificationResponse.id.toString(),
          'actionId': notificationResponse.actionId,
          'input': notificationResponse.input,
          'payload': payload != null ? jsonDecode(payload) : null,
        });
      },
    );
  }

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    debugPrint("$action;AAAAAAhandleMethod===params==$params");
    switch (action) {
      case 'check':
        return await _check(params);
      case 'showLocal':
        return await _showLocal(params);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _check(Map<String, dynamic> params) async {
    try {
      final status = await Permission.notification.status;
      return BridgeResponse.success(status.isGranted);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }

  Future<BridgeResponse> _showLocal(Map<String, dynamic> params) async {
    debugPrint('[_showLocal] params: $params');
    try {
      final id = params['id'] as String? ?? '0'; // Notification ID
      final title = params['title'] as String? ?? '';
      final body = params['body'] as String? ?? '';
      final payload =
          params['payload'] as Map<String, dynamic>?; // Get payload from params

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'appbridge_channel', // id
        'AppBridge Notifications', // name
        channelDescription: 'Notifications from AppBridge H5 SDK',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        int.tryParse(id) ?? 0, // Convert String id to int
        title,
        body,
        platformChannelSpecifics,
        payload: payload != null
            ? jsonEncode(payload)
            : null, // Encode payload to string
      );

      return BridgeResponse.success(true);
    } catch (e) {
      return BridgeResponse.error(-1, e.toString());
    }
  }
}
