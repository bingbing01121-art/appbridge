import 'base_module.dart';
import '../models/bridge_response.dart';
import 'package:flutter/material.dart'; // Import for Navigator
import '../../payment_info_page.dart'; // Import PaymentInfoPage

import '../../appbridge.dart'; // Add this import

/// Payment模块实现
class PaymentModule extends BaseModule {
  PaymentModule();

  @override
  Future<BridgeResponse> handleMethod(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'pay':
        return await _pay(params);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _pay(Map<String, dynamic> params) async {
    try {
      print('PaymentModule: _pay called with params: $params');
      final productId = params['productId'] as String?;
      final payType = params['payType'] as String?;
      
      if (productId == null || payType == null) {
        return BridgeResponse.error(400, 'ProductId and payType are required');
      }
      
      // 模拟支付结果
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      const status = 'success';

      final currentContext = Appbridge().context;
      if (currentContext == null) {
        return BridgeResponse.error(-1, 'No valid BuildContext available for payment navigation.');
      }
      // 导航到支付信息页面
      Navigator.of(currentContext).push(
        MaterialPageRoute(
          builder: (context) => PaymentInfoPage(
            orderId: orderId,
            productId: productId,
            payType: payType,
            status: status,
          ),
        ),
      );
      
      final result = {
        'orderId': orderId,
        'status': status,
      };
      print('PaymentModule: _pay returning: $result');
      return BridgeResponse.success(result);
    } catch (e) {
      print('PaymentModule: _pay error: $e');
      return BridgeResponse.error(-1, e.toString());
    }
  }
}
