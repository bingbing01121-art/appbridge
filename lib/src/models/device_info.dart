/// 设备信息模型
class DeviceInfo {
  final String platform;
  final String systemType;
  final String osVersion;
  final String manufacturer;
  final String brand;
  final String model;
  final String appId;
  final String packageName;
  final String appVersion;
  final String buildNumber;
  final int? sdkInt;
  final int screenWidth;
  final int screenHeight;
  final double pixelRatio;
  final int dpi;
  final int physicalWidth;
  final int physicalHeight;
  final String locale;
  final String region;
  final String timezone;

  DeviceInfo({
    required this.platform,
    required this.systemType,
    required this.osVersion,
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.appId,
    required this.packageName,
    required this.appVersion,
    required this.buildNumber,
    this.sdkInt,
    required this.screenWidth,
    required this.screenHeight,
    required this.pixelRatio,
    required this.dpi,
    required this.physicalWidth,
    required this.physicalHeight,
    required this.locale,
    required this.region,
    required this.timezone,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'systemType': systemType,
      'osVersion': osVersion,
      'manufacturer': manufacturer,
      'brand': brand,
      'model': model,
      'appId': appId,
      'packageName': packageName,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'sdkInt': sdkInt,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'pixelRatio': pixelRatio,
      'dpi': dpi,
      'physicalWidth': physicalWidth,
      'physicalHeight': physicalHeight,
      'locale': locale,
      'region': region,
      'timezone': timezone,
    };
  }
}
