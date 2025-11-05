/// 环境信息模型
class EnvironmentInfo {
  final String env;
  final String channel;
  final String region;
  final String lang;
  final String timezone;
  final String networkType;
  final bool isDebug;
  final bool isEmulator;
  final String buildType;
  final String? commitHash;
  final List<String>? featureFlags;
  final String appId;
  final bool foreground;
  final bool powerSave;
  final bool vpnEnabled;
  final bool networkRestricted;

  EnvironmentInfo({
    required this.env,
    required this.channel,
    required this.region,
    required this.lang,
    required this.timezone,
    required this.networkType,
    required this.isDebug,
    required this.isEmulator,
    required this.buildType,
    this.commitHash,
    this.featureFlags,
    required this.appId,
    required this.foreground,
    required this.powerSave,
    required this.vpnEnabled,
    required this.networkRestricted,
  });

  Map<String, dynamic> toJson() {
    return {
      'env': env,
      'channel': channel,
      'region': region,
      'lang': lang,
      'timezone': timezone,
      'networkType': networkType,
      'isDebug': isDebug,
      'isEmulator': isEmulator,
      'buildType': buildType,
      if (commitHash != null) 'commitHash': commitHash,
      if (featureFlags != null) 'featureFlags': featureFlags,
      'appId': appId,
      'foreground': foreground,
      'powerSave': powerSave,
      'vpnEnabled': vpnEnabled,
      'networkRestricted': networkRestricted,
    };
  }
}
