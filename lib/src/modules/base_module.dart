import 'package:flutter/widgets.dart';
import '../models/bridge_response.dart';

/// 基础模块抽象类
abstract class BaseModule {
  /// 处理模块方法调用
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]);
}
