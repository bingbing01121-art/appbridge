import 'base_module.dart';
import '../models/bridge_response.dart';
import 'package:flutter/material.dart'; // Import for Navigator
import '../../payment_info_page.dart'; // Import PaymentInfoPage

import '../../appbridge.dart'; // Add this import

/// Payment模块实现
class PaymentModule extends BaseModule {
  PaymentModule();

  @override
  Future<BridgeResponse> handleMethod(
      String action, Map<String, dynamic> params,
      [BuildContext? context]) async {
    switch (action) {
      case 'pay':
        return await _pay(params);
      default:
        return BridgeResponse.error(-1, 'Unknown action: $action');
    }
  }

  Future<BridgeResponse> _pay(Map<String, dynamic> params) async {
    final currentContext = Appbridge().context;
    if (currentContext == null) {
      return BridgeResponse.error(
          -1, 'No valid BuildContext available for payment operations.');
    }

    // Extract payment details from params
    final String? orderId = params['orderId'] as String?;
    final double? amount = params['amount'] as double?;
    final String? currency = params['currency'] as String?;

    if (orderId == null || amount == null || currency == null) {
      return BridgeResponse.error(
          -1, 'Missing required payment parameters: orderId, amount, currency.');
    }

    // Simulate payment process or navigate to a payment page
    final result = await Navigator.push(
      currentContext,
      MaterialPageRoute(
        builder: (context) => PaymentInfoPage(
          orderId: orderId,
          amount: amount,
          currency: currency,
        ),
      ),
    );

    if (result == true) {
      return BridgeResponse.success({'status': 'success', 'message': 'Payment successful'});
    } else {
      return BridgeResponse.error(-1, 'Payment cancelled or failed');
    }
  }

  @override
  List<String> getCapabilities() {
    return [
      'payment.pay',
    ];
  }
}
