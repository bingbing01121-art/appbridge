import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bridge_response.dart';
import 'base_module.dart';
import 'dart:io';
import 'ui_module.dart'; // Import UIModule

class LiveActivityModule extends BaseModule {
  UIModule? _uiModule; // Make nullable

  LiveActivityModule(this._uiModule); // Modify constructor

  void updateUIModule(UIModule uiModule) {
    _uiModule = uiModule;
  }

  @override
  Future<BridgeResponse> handleMethod(String action, Map<String, dynamic> params) async {
    if (Platform.isIOS) {
      // Implement iOS-specific logic here using MethodChannel to native iOS
      // For now, return a placeholder or not implemented.
      final errorMessage = 'Live Activity $action not implemented for iOS yet.'; // Declare as local variable
      _uiModule?.toast(message:'text'+ errorMessage); // Show toast
      return BridgeResponse.error(-1, errorMessage);
    } else if (Platform.isAndroid) {
      final errorMessage = 'Live Activities are an iOS-specific feature (iOS 16.1+).'; // Declare as local variable
      _uiModule?.toast(message: 'text'+ errorMessage); // Show toast
      return BridgeResponse.error(-1, errorMessage);
    } else {
      final errorMessage = 'Live Activities are not supported on this platform.'; // Declare as local variable
      _uiModule?.toast(message: 'text'+ errorMessage); // Show toast
      return BridgeResponse.error(-1, errorMessage);
    }
  }
}
