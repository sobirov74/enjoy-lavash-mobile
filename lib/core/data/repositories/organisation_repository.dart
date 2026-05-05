import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/data/models/base_paginate.dart';
import 'package:enjoy_lavash_mobile/core/data/models/organisation.dart';

class OrganisationRepository {
  final ApiClient apiClient;

  OrganisationRepository(this.apiClient);

  Future<PaginatedResponse<Organisation>> getOrganisations({
    int page = 1,
    int size = 20,
    String? corporationId,
    String? organisationType,
    String? name,
  }) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.organisations,
      queryParameters: {
        'page': page,
        'size': size,
        'corporation_id': ?corporationId,
        'organisation_type': ?organisationType,
        'name': ?name,
      },
    );

    return PaginatedResponse<Organisation>.fromJson(
      response.data,
      (json) => Organisation.fromJson(json),
    );
  }
}
