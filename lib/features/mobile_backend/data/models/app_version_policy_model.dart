import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/json_helpers.dart';

class AppVersionPolicyModel {
  const AppVersionPolicyModel({
    required this.id,
    required this.platform,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.description,
    required this.appUrl,
    required this.updateAvailable,
    required this.forceUpdate,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String platform;
  final String latestVersion;
  final String minSupportedVersion;
  final String description;
  final String appUrl;
  final bool updateAvailable;
  final bool forceUpdate;

  bool get shouldPrompt => updateAvailable || forceUpdate;

  AppVersionPolicyModel copyWith({bool? updateAvailable, bool? forceUpdate}) {
    return AppVersionPolicyModel(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      platform: platform,
      latestVersion: latestVersion,
      minSupportedVersion: minSupportedVersion,
      description: description,
      appUrl: appUrl,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      forceUpdate: forceUpdate ?? this.forceUpdate,
    );
  }

  AppVersionPolicyModel resolveForCurrentVersion(String? currentVersion) {
    final current = _normalizeVersion(currentVersion);
    if (current == null) return this;

    final latest = _normalizeVersion(latestVersion);
    final minSupported = _normalizeVersion(minSupportedVersion);
    final isDifferentFromLatest = latest != null && current != latest;
    final isBelowMinimum =
        minSupported != null && _compareVersions(current, minSupported) < 0;

    return copyWith(
      updateAvailable: updateAvailable || isDifferentFromLatest,
      forceUpdate: forceUpdate || isBelowMinimum,
    );
  }

  factory AppVersionPolicyModel.fromJson(Map<String, dynamic> json) {
    return AppVersionPolicyModel(
      id: readString(json, const ['id']),
      createdAt: readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: readDateTime(json, const ['updatedAt', 'updated_at']),
      deletedAt: readDateTime(json, const ['deletedAt', 'deleted_at']),
      platform: readString(json, const ['platform']),
      latestVersion: readString(json, const [
        'latestVersion',
        'latest_version',
      ]),
      minSupportedVersion: readString(json, const [
        'minSupportedVersion',
        'min_supported_version',
      ]),
      description: readString(json, const ['description']),
      appUrl: readString(json, const ['appUrl', 'app_url']),
      updateAvailable: readBool(json, const [
        'updateAvailable',
        'update_available',
      ]),
      forceUpdate: readBool(json, const ['forceUpdate', 'force_update']),
    );
  }
}

String? _normalizeVersion(String? version) {
  final trimmed = version?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.startsWith('v') || trimmed.startsWith('V')
      ? trimmed.substring(1)
      : trimmed;
}

int _compareVersions(String left, String right) {
  final leftParts = _versionParts(left);
  final rightParts = _versionParts(right);
  final maxLength = leftParts.length > rightParts.length
      ? leftParts.length
      : rightParts.length;

  for (var i = 0; i < maxLength; i++) {
    final leftPart = i < leftParts.length ? leftParts[i] : 0;
    final rightPart = i < rightParts.length ? rightParts[i] : 0;
    if (leftPart != rightPart) return leftPart.compareTo(rightPart);
  }

  return 0;
}

List<int> _versionParts(String version) {
  final coreVersion = version.split('+').first.split('-').first;
  return coreVersion
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList(growable: false);
}
