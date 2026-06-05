class ApiEndpoints {
  // Existing admin/store endpoints.
  static const orders = "/api/v1/orders/";
  static const scan = "/api/v1/box-receipts";
  static const me = "/api/v1/auth/me";
  static const organisations = "/api/v1/organisations/";
  static const products = "/api/v1/products/store-access";

  // Customer mobile app endpoints from MOBILE_APP_IMPLEMENTATION.md.
  static const requestOtp = "/auth/request-otp";
  static const verifyOtp = "/auth/verify-otp";
  static const branches = "/branches";
  static const catalog = "/catalog";
  static const activePromotions = "/promotions/active";
  static const cartPreview = "/cart/preview";
  static const clientMe = "/clients/me";
  static const clientAddresses = "/clients/me/addresses";
  static const clientOrders = "/clients/me/orders";
  static const filesUpload = "/files/upload";
  static const filesDelete = "/files/delete";

  static String catalogProduct(String idOrSlug) =>
      "/catalog/products/${Uri.encodeComponent(idOrSlug)}";

  static String clientAddress(String id) =>
      "$clientAddresses/${Uri.encodeComponent(id)}";

  static String clientOrderCancel(String id) =>
      "$clientOrders/${Uri.encodeComponent(id)}/cancel";
}
