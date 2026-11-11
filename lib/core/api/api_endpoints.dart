class ApiEndpoints {
  // Customer mobile app endpoints from MOBILE_APP_IMPLEMENTATION.md.
  static const requestOtp = "/auth/request-otp";
  static const verifyOtp = "/auth/verify-otp";
  static const clientRefresh = "/auth/client/refresh";
  static const branches = "/branches";
  static const appVersion = "/app-version";
  static const catalog = "/catalog";
  static const activePromotions = "/promotions/active";
  static const activeBanners = "/banners/active";
  static const paymentMethods = "/payment-methods";
  static const cartPreview = "/clients/me/cart/preview";
  static const clientMe = "/clients/me";
  static const clientAddresses = "/clients/me/addresses";
  static const clientOrders = "/clients/me/orders";
  static const clientPushTokens = "/clients/me/push-tokens";
  static const clientNotifications = "/clients/me/notifications";
  static const clientNotificationsUnreadCount =
      "/clients/me/notifications/unread-count";
  static const clientNotificationsReadAll =
      "/clients/me/notifications/read-all";
  static const clientPromotions = "/clients/me/promotions";
  static const clientLoyaltyWallet = "/clients/me/loyalty/wallet";
  static const clientLoyaltyTransactions = "/clients/me/loyalty/transactions";

  static String branchOrderingStatus(String branchId) =>
      "$branches/${Uri.encodeComponent(branchId)}/ordering-status";

  static String clientAddress(String id) =>
      "$clientAddresses/${Uri.encodeComponent(id)}";

  static String clientOrderRetryPayment(String id) =>
      "$clientOrders/${Uri.encodeComponent(id)}/retry-payment";

  static String clientOrder(String id) =>
      "$clientOrders/${Uri.encodeComponent(id)}";

  static String clientPushTokenRegistration(String registrationId) =>
      "/clients/me/push-token-registrations/"
      "${Uri.encodeComponent(registrationId)}";

  static String clientNotificationRead(String notificationId) =>
      "$clientNotifications/${Uri.encodeComponent(notificationId)}/read";

  static String clientNotificationUnread(String notificationId) =>
      "$clientNotifications/${Uri.encodeComponent(notificationId)}/unread";
}
