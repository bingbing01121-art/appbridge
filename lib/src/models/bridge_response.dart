/// AppBridge统一响应格式
class BridgeResponse {
  final int code;
  final dynamic data;
  final String? msg;

  BridgeResponse({
    required this.code,
    this.data,
    this.msg,
  });

  /// 成功响应
  static BridgeResponse success([dynamic data]) {
    return BridgeResponse(code: 0, data: data);
  }

  /// 错误响应
  static BridgeResponse error(int code, [String? msg, dynamic data]) {
    return BridgeResponse(code: code, msg: msg, data: data);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'data': data,
      if (msg != null) 'msg': msg,
    };
  }

  /// 从JSON创建
  factory BridgeResponse.fromJson(Map<String, dynamic> json) {
    return BridgeResponse(
      code: json['code'] ?? -1,
      data: json['data'],
      msg: json['msg'],
    );
  }

  /// 是否成功
  bool get isSuccess => code == 0;

  @override
  String toString() {
    return 'BridgeResponse(code: $code, data: $data, msg: $msg)';
  }
}
