import 'base_url.dart';

/// Upload paths belong to the backend origin, even if the API has a path prefix.
String? resolveBackendImageUrl(Object? value, {String? backendBaseUrl}) {
  if (value is! String || value.trim().isEmpty) return null;
  final image = Uri.tryParse(value.trim());
  if (image == null) return null;
  final Uri resolved;
  if (image.hasScheme) {
    resolved = image;
  } else {
    final backend = Uri.parse(backendBaseUrl ?? BaseUrl.baseUrl);
    resolved = Uri.parse('${backend.origin}/').resolveUri(image);
  }
  if ((resolved.scheme != 'http' && resolved.scheme != 'https') ||
      resolved.host.isEmpty) {
    return null;
  }
  return resolved.toString();
}
