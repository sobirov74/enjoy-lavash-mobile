// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Enjoy Lavash';

  @override
  String get tabMenu => 'Menu';

  @override
  String get tabCart => 'Cart';

  @override
  String get tabProfile => 'Profile';

  @override
  String get delivery => 'Delivery';

  @override
  String get pickup => 'Pickup';

  @override
  String get specialOffer => 'Special Offer';

  @override
  String get specialOfferDesc => '20% off on lavash until end of week';

  @override
  String get specialOfferCta => '🔥 Order now';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get cartEmptyDesc =>
      'Add dishes from the menu and place your order in a few taps.';

  @override
  String get browseMenu => 'Browse menu';

  @override
  String get cart => 'Cart';

  @override
  String get total => 'Total';

  @override
  String get checkout => 'Checkout';

  @override
  String get orderCreated => 'Order created';

  @override
  String get orderCreateFailed => 'Could not create order. Try again.';

  @override
  String get selectDeliveryAddressFirst => 'Select a delivery address first';

  @override
  String get selectPickupBranchFirst => 'Select a pickup branch first';

  @override
  String get profile => 'Profile';

  @override
  String get guest => 'Guest';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get loyaltyCard => 'Loyalty Card';

  @override
  String get accumulatedPoints => 'Accumulated points';

  @override
  String get showCodeForPoints => 'Show the code at checkout to earn points';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get email => 'Email';

  @override
  String get address => 'Address';

  @override
  String get customerId => 'Customer ID';

  @override
  String get orderHistory => 'Order History';

  @override
  String get completed => 'Completed';

  @override
  String get cashbackSystem => 'Cashback System';

  @override
  String get perOrder => 'Per order';

  @override
  String get perOrderValue => '5% in points';

  @override
  String get onePointEquals => '1 point equals';

  @override
  String get onePointValue => '1 so\'m';

  @override
  String get canSpend => 'Can spend';

  @override
  String get canSpendValue => 'Up to 50% of order';

  @override
  String get shareApp => 'Share App';

  @override
  String get shareAppText =>
      'Try EnjoyLavash: https://play.google.com/store/apps/details?id=com.aurumdev.enjoy_lavash_mobile';

  @override
  String get logout => 'Log out';

  @override
  String get logoutTitle => 'Log out?';

  @override
  String get logoutMessage =>
      'Your saved token will be removed from this device.';

  @override
  String get logoutFailed => 'Could not log out. Try again.';

  @override
  String get notFoundTitle => 'This page is under development';

  @override
  String get goHome => 'Go Home';

  @override
  String get emptyList => 'List is empty';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get save => 'Save';

  @override
  String get skip => 'Skip';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusNew => 'New';

  @override
  String get statusArchive => 'Archive';

  @override
  String get statusNeedAccept => 'Time to accept the goods!';

  @override
  String get tableNumber => 'No.';

  @override
  String get tableName => 'Name';

  @override
  String get tableSent => 'Sent';

  @override
  String get tableReceived => 'Recv.';

  @override
  String get tableDifference => 'Diff.';

  @override
  String get status => 'Status:';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get searchAddress => 'Search address...';

  @override
  String get houseNumber => 'House number';

  @override
  String get houseNumberHint => 'e.g. 25A';

  @override
  String get entranceLabel => 'Entrance';

  @override
  String get floorLabel => 'Floor';

  @override
  String get apartmentLabel => 'Apt.';

  @override
  String get commentLabel => 'Comment';

  @override
  String get commentHint => 'Delivery instructions...';

  @override
  String get confirmAddress => 'Confirm address';

  @override
  String get tapToSelectAddress => 'Tap to select address';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get enableLocation => 'Enable location';

  @override
  String get currentLocation => 'Current location';

  @override
  String get selectBranch => 'Select Branch';

  @override
  String get branchWorkingHours => 'Working hours';

  @override
  String get menu => 'Menu';

  @override
  String get settings => 'Settings';

  @override
  String get aboutUs => 'About Us';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get authorization => 'Authorization';

  @override
  String get tapToSignIn => 'Tap to sign in and view your profile';

  @override
  String get enterPhoneNumber => 'Enter your phone number';

  @override
  String get enterSmsCode => 'Enter SMS code';

  @override
  String get otpSentMessage =>
      'We sent a confirmation code to your phone number.';

  @override
  String get signInToCheckout => 'Sign in to continue checkout from your cart.';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get smsCode => 'SMS code';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String demoCode(String code) {
    return 'Demo code: $code';
  }

  @override
  String get sendCode => 'Send code';

  @override
  String get continueButton => 'Continue';

  @override
  String get promoCodeCopied => 'Promo code copied!';

  @override
  String get promotionDetails => 'Promotion Details';

  @override
  String get promoCode => 'Promo code';

  @override
  String get discount => 'Discount';

  @override
  String validUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get copyCode => 'Copy code';

  @override
  String get close => 'Close';

  @override
  String get orderCreatedPaymentOnline =>
      'Order created. Complete payment online.';

  @override
  String get orderCreatedPaymentPageOpenFailed =>
      'Order created, but payment page could not be opened.';

  @override
  String get enterPromoCode => 'Enter promo code';

  @override
  String get apply => 'Apply';

  @override
  String get couldNotCalculateTotal => 'Could not calculate total';

  @override
  String get createOrderTitle => 'Create order';

  @override
  String get orderType => 'Order type';

  @override
  String get orderItems => 'Order items';

  @override
  String get cancel => 'Cancel';

  @override
  String get createOrderAction => 'Create order';

  @override
  String get payment => 'Payment';

  @override
  String get onlinePayment => 'Online payment';

  @override
  String get payOnReceipt => 'Pay on receipt';

  @override
  String get calculatingTotal => 'Calculating total';

  @override
  String get recalculate => 'Recalculate';

  @override
  String get orderPreview => 'Order preview';

  @override
  String get items => 'Items';

  @override
  String get modifiers => 'Modifiers';

  @override
  String get serviceFee => 'Service fee';

  @override
  String get pickupBranch => 'Pickup branch';

  @override
  String get clientAddress => 'Client address';

  @override
  String get branchId => 'Branch ID';

  @override
  String get addressId => 'Address ID';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCardTerminal => 'Card terminal';

  @override
  String get unknown => 'Unknown';

  @override
  String get errorSlowNetwork => 'Slow network';

  @override
  String get errorConnectionProblem => 'Connection problem';

  @override
  String get errorBackend => 'Backend error';

  @override
  String get errorAuthorizationExpired => 'Authorization expired';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericBody => 'Please try again in a moment.';

  @override
  String get retry => 'Retry';

  @override
  String get searchProducts => 'Search products';

  @override
  String get clearSearch => 'Clear search';

  @override
  String searchProductsResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get noProductsFound => 'No products found';

  @override
  String get findingAddress => 'Finding address...';

  @override
  String get checkingThisLocation => 'Checking this location';

  @override
  String get gettingAddressDetails => 'Getting address details';

  @override
  String get allowNotificationsInSettings =>
      'Allow notifications in phone settings';

  @override
  String get notificationPermissionDenied =>
      'Notification permission was not allowed';

  @override
  String get notificationUpdateFailed =>
      'Could not update notification settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get appearance => 'Appearance';

  @override
  String get chooseAppColorMode => 'Choose the app color mode';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Use the app in your preferred language';

  @override
  String get seeAllOrders => 'See all orders';

  @override
  String get actions => 'Actions';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get accountDeleted => 'Your account has been deleted';

  @override
  String get deleteAccountFailed =>
      'Could not delete the account. Please try again.';

  @override
  String get deleteAccountQuestion => 'Delete account?';

  @override
  String get deleteAccountPermanentWarning =>
      'This action is permanent and cannot be undone';

  @override
  String get deleteAccountItemsTitle => 'The following will be deleted:';

  @override
  String get deleteAccountProfilePhone => 'Profile and phone number';

  @override
  String get deleteAccountSavedAddresses => 'Saved delivery addresses';

  @override
  String get deleteAccountBonusPoints => 'Accumulated bonus points';

  @override
  String get deleteAccountAcknowledgement =>
      'I understand that my data will be deleted permanently';

  @override
  String get deleting => 'Deleting...';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get allOrders => 'All orders';

  @override
  String get ordersSearchHint => 'Search by product, status, or order ID';

  @override
  String get all => 'All';

  @override
  String get anyStatus => 'Any status';

  @override
  String get noOrdersMatchFilters => 'No orders match your filters';

  @override
  String get appVersion => 'App version';

  @override
  String get notificationCheckingPermission =>
      'Checking notification permission';

  @override
  String get notificationsUnavailable =>
      'Notifications are not available on this device';

  @override
  String get notificationsEnabled => 'Order updates and offers are enabled';

  @override
  String get notificationsSubtitleDefault =>
      'Receive order updates and special offers';

  @override
  String get orderStatusCooking => 'Cooking';

  @override
  String get orderStatusReady => 'Ready';

  @override
  String get orderStatusCourierAssigned => 'Courier assigned';

  @override
  String get orderStatusOnTheWay => 'On the way';

  @override
  String get paymentStatusPending => 'Pending';

  @override
  String get paymentStatusPaid => 'Paid';

  @override
  String get paymentStatusFailed => 'Failed';

  @override
  String get paymentStatusRefunded => 'Refunded';

  @override
  String get product => 'Product';

  @override
  String get noProductsInOrder => 'No products in this order';

  @override
  String get paymentLinkUnavailable => 'Payment link is not available yet.';

  @override
  String get completePaymentOnline => 'Complete payment online.';

  @override
  String get paymentPageOpenFailed => 'Payment page could not be opened.';

  @override
  String get retryPaymentFailed => 'Could not retry payment.';

  @override
  String get orderDetails => 'Order details';

  @override
  String get currentStatus => 'Current status';

  @override
  String get created => 'Created';

  @override
  String get scheduledFor => 'Scheduled for';

  @override
  String get lastUpdate => 'Last update';

  @override
  String get paymentStatus => 'Payment status';

  @override
  String get retryPayment => 'Retry payment';

  @override
  String get products => 'Products';

  @override
  String get statusHistory => 'Status history';

  @override
  String get additionalInfo => 'Additional info';

  @override
  String get kitchenOrder => 'Kitchen order';
}
