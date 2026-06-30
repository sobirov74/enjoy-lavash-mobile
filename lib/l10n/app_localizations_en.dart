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
}
