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
