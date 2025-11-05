/// 版本信息模型
class VersionInfo {
  final String bridgeVersion;
  final String appId;
  final String appName;
  final String packageName;
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String systemType;
  final String osVersion;
  final String manufacturer;
  final String deviceModel;
  final String brand;
  final int? sdkInt;
  final String channel;
  final String region;
  final String lang;
  final bool isDebug;

  VersionInfo({
    required this.bridgeVersion,
    required this.appId,
    required this.appName,
    required this.packageName,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.systemType,
    required this.osVersion,
    required this.manufacturer,
    required this.deviceModel,
    required this.brand,
    this.sdkInt,
    required this.channel,
    required this.region,
    required this.lang,
    required this.isDebug,
  });

  Map<String, dynamic> toJson() {
    return {
      'bridgeVersion': bridgeVersion,
      'appId': appId,
      'appName': appName,
      'packageName': packageName,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'platform': platform,
      'systemType': systemType,
      'osVersion': osVersion,
      'manufacturer': manufacturer,
      'deviceModel': deviceModel,
      'brand': brand,
      'sdkInt': sdkInt,
      'channel': channel,
      'region': region,
      'lang': lang,
      'isDebug': isDebug,
    };
  }
}
