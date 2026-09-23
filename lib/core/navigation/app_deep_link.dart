/// Destinations available through the app's existing navigation flows.
enum AppDeepLink {
  home,
  menu,
  cart,
  promotions,
  profile,
  orders,
  notifications,
  loyalty;

  static AppDeepLink? fromUri(Uri uri) {
    if (uri.scheme != 'enjoylavash') return null;
    final route = [
      uri.host,
      ...uri.pathSegments,
    ].where((part) => part.isNotEmpty).join('/').toLowerCase();
    for (final destination in values) {
      if (destination.name == route) return destination;
    }
    return null;
  }
}

Uri? supportedBannerLink(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final uri = Uri.tryParse(value.trim());
  if (uri == null) return null;
  if ((uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty) {
    return uri;
  }
  return AppDeepLink.fromUri(uri) == null ? null : uri;
}
