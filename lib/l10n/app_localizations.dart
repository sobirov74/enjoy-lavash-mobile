import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In uz, this message translates to:
  /// **'Enjoy Lavash'**
  String get appTitle;

  /// No description provided for @tabMenu.
  ///
  /// In uz, this message translates to:
  /// **'Menyu'**
  String get tabMenu;

  /// No description provided for @tabCart.
  ///
  /// In uz, this message translates to:
  /// **'Savat'**
  String get tabCart;

  /// No description provided for @tabProfile.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @delivery.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib beriş'**
  String get delivery;

  /// No description provided for @pickup.
  ///
  /// In uz, this message translates to:
  /// **'Olib ketiş'**
  String get pickup;

  /// No description provided for @cartEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Savat böş'**
  String get cartEmpty;

  /// No description provided for @cartEmptyDesc.
  ///
  /// In uz, this message translates to:
  /// **'Menyudan taom qöşing va bir neça bosişda buyurtma bering.'**
  String get cartEmptyDesc;

  /// No description provided for @browseMenu.
  ///
  /// In uz, this message translates to:
  /// **'Menyuga ötiş'**
  String get browseMenu;

  /// No description provided for @cart.
  ///
  /// In uz, this message translates to:
  /// **'Savat'**
  String get cart;

  /// No description provided for @total.
  ///
  /// In uz, this message translates to:
  /// **'Jami'**
  String get total;

  /// No description provided for @checkout.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma beriş'**
  String get checkout;

  /// No description provided for @viewCart.
  ///
  /// In uz, this message translates to:
  /// **'Savatni oçiş'**
  String get viewCart;

  /// No description provided for @cartItemsCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta mahsulot'**
  String cartItemsCount(int count);

  /// No description provided for @itemAddedToCart.
  ///
  /// In uz, this message translates to:
  /// **'{product} savatga qöşildi'**
  String itemAddedToCart(String product);

  /// No description provided for @itemRemovedFromCart.
  ///
  /// In uz, this message translates to:
  /// **'{product} savatdan olib taşlandi'**
  String itemRemovedFromCart(String product);

  /// No description provided for @undo.
  ///
  /// In uz, this message translates to:
  /// **'Qaytariş'**
  String get undo;

  /// No description provided for @increaseQuantity.
  ///
  /// In uz, this message translates to:
  /// **'Miqdorni oşiriş'**
  String get increaseQuantity;

  /// No description provided for @decreaseQuantity.
  ///
  /// In uz, this message translates to:
  /// **'Miqdorni kamaytiriş'**
  String get decreaseQuantity;

  /// No description provided for @menuLoading.
  ///
  /// In uz, this message translates to:
  /// **'Menyu tayyorlanmoqda...'**
  String get menuLoading;

  /// No description provided for @orderSuccessTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmangiz qabul qilindi!'**
  String get orderSuccessTitle;

  /// No description provided for @orderSuccessMessage.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma oşxonaga yuborildi. Holatini profilingizda kuzatib boring.'**
  String get orderSuccessMessage;

  /// No description provided for @orderSuccessNumber.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma #{number}'**
  String orderSuccessNumber(String number);

  /// No description provided for @trackOrder.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani kuzatiş'**
  String get trackOrder;

  /// No description provided for @orderSuccessPaymentOpening.
  ///
  /// In uz, this message translates to:
  /// **'Xavfsiz tölov sahifasi oçilmoqda…'**
  String get orderSuccessPaymentOpening;

  /// No description provided for @orderSuccessPaymentOpened.
  ///
  /// In uz, this message translates to:
  /// **'Oçilgan sahifada tölovni yakunlang.'**
  String get orderSuccessPaymentOpened;

  /// No description provided for @orderSuccessPayOnReceipt.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani olganda tölov qilasiz.'**
  String get orderSuccessPayOnReceipt;

  /// No description provided for @orderSuccessPaymentPaid.
  ///
  /// In uz, this message translates to:
  /// **'Tölov qabul qilindi. Hammasi tayyor.'**
  String get orderSuccessPaymentPaid;

  /// No description provided for @orderSuccessPaymentFailed.
  ///
  /// In uz, this message translates to:
  /// **'Tölov yakunlanmadi. Keyingi qadamni buyurtma tafsilotlarida köring.'**
  String get orderSuccessPaymentFailed;

  /// No description provided for @orderSuccessPaymentRefunded.
  ///
  /// In uz, this message translates to:
  /// **'Uşbu tölov qaytarildi.'**
  String get orderSuccessPaymentRefunded;

  /// No description provided for @orderCreateFailed.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma yaratib bölmadi. Qayta urinib köring.'**
  String get orderCreateFailed;

  /// No description provided for @selectDeliveryAddressFirst.
  ///
  /// In uz, this message translates to:
  /// **'Avval yetkazib beriş manzilini tanlang'**
  String get selectDeliveryAddressFirst;

  /// No description provided for @selectPickupBranchFirst.
  ///
  /// In uz, this message translates to:
  /// **'Avval olib ketiş filialini tanlang'**
  String get selectPickupBranchFirst;

  /// No description provided for @paymentMethodsUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Tölov usullari vaqtinça mavjud emas. Qayta urinib köring.'**
  String get paymentMethodsUnavailable;

  /// No description provided for @profile.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @guest.
  ///
  /// In uz, this message translates to:
  /// **'Mehmon'**
  String get guest;

  /// No description provided for @lightTheme.
  ///
  /// In uz, this message translates to:
  /// **'Yoruğ'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In uz, this message translates to:
  /// **'Qoronği'**
  String get darkTheme;

  /// No description provided for @address.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get address;

  /// No description provided for @orderHistory.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar tarixi'**
  String get orderHistory;

  /// No description provided for @shareApp.
  ///
  /// In uz, this message translates to:
  /// **'Ilovani ulaşiş'**
  String get shareApp;

  /// No description provided for @shareAppText.
  ///
  /// In uz, this message translates to:
  /// **'EnjoyLavash ilovasini köring: https://play.google.com/store/apps/details?id=com.aurumdev.enjoy_lavash_mobile'**
  String get shareAppText;

  /// No description provided for @logout.
  ///
  /// In uz, this message translates to:
  /// **'Çiqiş'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In uz, this message translates to:
  /// **'Akkauntdan çiqasizmi?'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan token uşbu qurilmadan öçiriladi.'**
  String get logoutMessage;

  /// No description provided for @logoutFailed.
  ///
  /// In uz, this message translates to:
  /// **'Çiqib bölmadi. Qayta urinib köring.'**
  String get logoutFailed;

  /// No description provided for @emptyList.
  ///
  /// In uz, this message translates to:
  /// **'Röyxat böş'**
  String get emptyList;

  /// No description provided for @no.
  ///
  /// In uz, this message translates to:
  /// **'Yöq'**
  String get no;

  /// No description provided for @skip.
  ///
  /// In uz, this message translates to:
  /// **'Ötkazib yuboriş'**
  String get skip;

  /// No description provided for @statusCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlangan'**
  String get statusCompleted;

  /// No description provided for @statusAccepted.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qilingan'**
  String get statusAccepted;

  /// No description provided for @statusCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Rad etilgan'**
  String get statusCancelled;

  /// No description provided for @statusFailed.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilingan'**
  String get statusFailed;

  /// No description provided for @statusNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangi'**
  String get statusNew;

  /// No description provided for @status.
  ///
  /// In uz, this message translates to:
  /// **'Holat:'**
  String get status;

  /// No description provided for @deliveryAddress.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib beriş manzili'**
  String get deliveryAddress;

  /// No description provided for @searchAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni qidiring...'**
  String get searchAddress;

  /// No description provided for @houseNumber.
  ///
  /// In uz, this message translates to:
  /// **'Uy raqami'**
  String get houseNumber;

  /// No description provided for @houseNumberHint.
  ///
  /// In uz, this message translates to:
  /// **'masalan 25A'**
  String get houseNumberHint;

  /// No description provided for @entranceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Kiriş'**
  String get entranceLabel;

  /// No description provided for @floorLabel.
  ///
  /// In uz, this message translates to:
  /// **'Qavat'**
  String get floorLabel;

  /// No description provided for @apartmentLabel.
  ///
  /// In uz, this message translates to:
  /// **'Xona'**
  String get apartmentLabel;

  /// No description provided for @commentLabel.
  ///
  /// In uz, this message translates to:
  /// **'Izoh'**
  String get commentLabel;

  /// No description provided for @commentHint.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer uçun körsatmalar...'**
  String get commentHint;

  /// No description provided for @confirmAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni tasdiqlaş'**
  String get confirmAddress;

  /// No description provided for @tapToSelectAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni tanlaş uçun bosing'**
  String get tapToSelectAddress;

  /// No description provided for @selectBranch.
  ///
  /// In uz, this message translates to:
  /// **'Filialni tanlang'**
  String get selectBranch;

  /// No description provided for @menu.
  ///
  /// In uz, this message translates to:
  /// **'Menyu'**
  String get menu;

  /// No description provided for @settings.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settings;

  /// No description provided for @authorization.
  ///
  /// In uz, this message translates to:
  /// **'Avtorizatsiya'**
  String get authorization;

  /// No description provided for @tapToSignIn.
  ///
  /// In uz, this message translates to:
  /// **'Kiriş va profilingizni köriş uçun bosing'**
  String get tapToSignIn;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamingizni kiriting'**
  String get enterPhoneNumber;

  /// No description provided for @enterSmsCode.
  ///
  /// In uz, this message translates to:
  /// **'SMS kodni kiriting'**
  String get enterSmsCode;

  /// No description provided for @otpSentMessage.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamingizga tasdiqlaş kodi yuborildi.'**
  String get otpSentMessage;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Sevimli taomlaringizni buyurtma qiling va amaldagi aksiyalardan ball oling.'**
  String get authWelcomeSubtitle;

  /// No description provided for @phoneNumber.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami'**
  String get phoneNumber;

  /// No description provided for @smsCode.
  ///
  /// In uz, this message translates to:
  /// **'SMS kod'**
  String get smsCode;

  /// No description provided for @nameOptional.
  ///
  /// In uz, this message translates to:
  /// **'Ism (ixtiyoriy)'**
  String get nameOptional;

  /// No description provided for @birthDateTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sizning tuğilgan kuningiz 🎂'**
  String get birthDateTitle;

  /// No description provided for @birthDate.
  ///
  /// In uz, this message translates to:
  /// **'Tuğilgan sana'**
  String get birthDate;

  /// No description provided for @selectBirthDate.
  ///
  /// In uz, this message translates to:
  /// **'Tuğilgan sanani tanlang'**
  String get selectBirthDate;

  /// No description provided for @birthDateSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Bir neça aylantirişda tanlang. Tuğilgan kuningiz uçun maxsus sovğalar tayyorlaymiz.'**
  String get birthDateSubtitle;

  /// No description provided for @birthDateDay.
  ///
  /// In uz, this message translates to:
  /// **'Kun'**
  String get birthDateDay;

  /// No description provided for @birthDateMonth.
  ///
  /// In uz, this message translates to:
  /// **'Oy'**
  String get birthDateMonth;

  /// No description provided for @birthDateYear.
  ///
  /// In uz, this message translates to:
  /// **'Yil'**
  String get birthDateYear;

  /// No description provided for @otpCodeExpiresIn.
  ///
  /// In uz, this message translates to:
  /// **'Kod {time} dan keyin tugaydi'**
  String otpCodeExpiresIn(String time);

  /// No description provided for @otpCodeExpired.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlaş kodining muddati tugadi.'**
  String get otpCodeExpired;

  /// No description provided for @resendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni qayta yuboriş'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In uz, this message translates to:
  /// **'{time} dan keyin qayta yuboriş'**
  String resendCodeIn(String time);

  /// No description provided for @tryAgainIn.
  ///
  /// In uz, this message translates to:
  /// **'{time} dan keyin qayta urining'**
  String tryAgainIn(String time);

  /// No description provided for @sendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kod yuboriş'**
  String get sendCode;

  /// No description provided for @continueButton.
  ///
  /// In uz, this message translates to:
  /// **'Davom etiş'**
  String get continueButton;

  /// No description provided for @promoCodeCopied.
  ///
  /// In uz, this message translates to:
  /// **'Promokod nusxalandi!'**
  String get promoCodeCopied;

  /// No description provided for @promotionDetails.
  ///
  /// In uz, this message translates to:
  /// **'Aksiya tafsilotlari'**
  String get promotionDetails;

  /// No description provided for @promoCode.
  ///
  /// In uz, this message translates to:
  /// **'Promokod'**
  String get promoCode;

  /// No description provided for @discount.
  ///
  /// In uz, this message translates to:
  /// **'Çegirma'**
  String get discount;

  /// No description provided for @validUntil.
  ///
  /// In uz, this message translates to:
  /// **'{date} gaça amal qiladi'**
  String validUntil(String date);

  /// No description provided for @close.
  ///
  /// In uz, this message translates to:
  /// **'Yopiş'**
  String get close;

  /// No description provided for @orderCreatedPaymentPageOpenFailed.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma yaratildi, ammo tölov sahifasi oçilmadi.'**
  String get orderCreatedPaymentPageOpenFailed;

  /// No description provided for @enterPromoCode.
  ///
  /// In uz, this message translates to:
  /// **'Promokodni kiriting'**
  String get enterPromoCode;

  /// No description provided for @apply.
  ///
  /// In uz, this message translates to:
  /// **'Qöllaş'**
  String get apply;

  /// No description provided for @couldNotCalculateTotal.
  ///
  /// In uz, this message translates to:
  /// **'Jami summani hisoblab bölmadi'**
  String get couldNotCalculateTotal;

  /// No description provided for @createOrderTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma beriş'**
  String get createOrderTitle;

  /// No description provided for @orderType.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma turi'**
  String get orderType;

  /// No description provided for @orderItems.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma mahsulotlari'**
  String get orderItems;

  /// No description provided for @cancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qiliş'**
  String get cancel;

  /// No description provided for @createOrderAction.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma beriş'**
  String get createOrderAction;

  /// No description provided for @createOrderFor.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma beriş · {price}'**
  String createOrderFor(String price);

  /// No description provided for @change.
  ///
  /// In uz, this message translates to:
  /// **'Özgartiriş'**
  String get change;

  /// No description provided for @payment.
  ///
  /// In uz, this message translates to:
  /// **'Tölov'**
  String get payment;

  /// No description provided for @onlinePayment.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn tölov'**
  String get onlinePayment;

  /// No description provided for @payOnReceipt.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qilganda tölaş'**
  String get payOnReceipt;

  /// No description provided for @calculatingTotal.
  ///
  /// In uz, this message translates to:
  /// **'Jami hisoblanmoqda'**
  String get calculatingTotal;

  /// No description provided for @recalculate.
  ///
  /// In uz, this message translates to:
  /// **'Qayta hisoblaş'**
  String get recalculate;

  /// No description provided for @orderPreview.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma hisobi'**
  String get orderPreview;

  /// No description provided for @viewOrderDetails.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma tafsilotlarini köriş'**
  String get viewOrderDetails;

  /// No description provided for @deliveryBranch.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib beruvçi filial'**
  String get deliveryBranch;

  /// No description provided for @deliveryDestination.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib beriş manzili'**
  String get deliveryDestination;

  /// No description provided for @deliveryDistance.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib beriş masofasi'**
  String get deliveryDistance;

  /// No description provided for @distanceMeters.
  ///
  /// In uz, this message translates to:
  /// **'{distance} m'**
  String distanceMeters(String distance);

  /// No description provided for @distanceKilometers.
  ///
  /// In uz, this message translates to:
  /// **'{distance} km'**
  String distanceKilometers(String distance);

  /// No description provided for @roadRoute.
  ///
  /// In uz, this message translates to:
  /// **'Yöl böyiça marşrut'**
  String get roadRoute;

  /// No description provided for @estimatedRoute.
  ///
  /// In uz, this message translates to:
  /// **'Taxminiy marşrut'**
  String get estimatedRoute;

  /// No description provided for @previewEstimateNotice.
  ///
  /// In uz, this message translates to:
  /// **'Filial, marşrut, ballar va yakuniy summa buyurtma yaratilganda tasdiqlanadi.'**
  String get previewEstimateNotice;

  /// No description provided for @items.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar'**
  String get items;

  /// No description provided for @modifiers.
  ///
  /// In uz, this message translates to:
  /// **'Qöşimçalar'**
  String get modifiers;

  /// No description provided for @serviceFee.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat haqi'**
  String get serviceFee;

  /// No description provided for @pickupBranch.
  ///
  /// In uz, this message translates to:
  /// **'Olib ketiş filiali'**
  String get pickupBranch;

  /// No description provided for @clientAddress.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz manzili'**
  String get clientAddress;

  /// No description provided for @branchId.
  ///
  /// In uz, this message translates to:
  /// **'Filial ID'**
  String get branchId;

  /// No description provided for @addressId.
  ///
  /// In uz, this message translates to:
  /// **'Manzil ID'**
  String get addressId;

  /// No description provided for @paymentCash.
  ///
  /// In uz, this message translates to:
  /// **'Naqd'**
  String get paymentCash;

  /// No description provided for @paymentCardTerminal.
  ///
  /// In uz, this message translates to:
  /// **'Terminal'**
  String get paymentCardTerminal;

  /// No description provided for @unknown.
  ///
  /// In uz, this message translates to:
  /// **'Noma\'lum'**
  String get unknown;

  /// No description provided for @errorSlowNetwork.
  ///
  /// In uz, this message translates to:
  /// **'Internet sekin'**
  String get errorSlowNetwork;

  /// No description provided for @errorConnectionProblem.
  ///
  /// In uz, this message translates to:
  /// **'Ulanişda muammo'**
  String get errorConnectionProblem;

  /// No description provided for @errorBackend.
  ///
  /// In uz, this message translates to:
  /// **'Server xatosi'**
  String get errorBackend;

  /// No description provided for @errorAuthorizationExpired.
  ///
  /// In uz, this message translates to:
  /// **'Avtorizatsiya muddati tugadi'**
  String get errorAuthorizationExpired;

  /// No description provided for @errorGenericTitle.
  ///
  /// In uz, this message translates to:
  /// **'Nimadir notöğri ketdi'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericBody.
  ///
  /// In uz, this message translates to:
  /// **'Birozdan keyin qayta urinib köring.'**
  String get errorGenericBody;

  /// No description provided for @noProductsFound.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot topilmadi'**
  String get noProductsFound;

  /// No description provided for @findingAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzil aniqlanmoqda...'**
  String get findingAddress;

  /// No description provided for @checkingThisLocation.
  ///
  /// In uz, this message translates to:
  /// **'Bu joy tekşirilmoqda'**
  String get checkingThisLocation;

  /// No description provided for @gettingAddressDetails.
  ///
  /// In uz, this message translates to:
  /// **'Manzil ma\'lumotlari olinmoqda'**
  String get gettingAddressDetails;

  /// No description provided for @allowNotificationsInSettings.
  ///
  /// In uz, this message translates to:
  /// **'Telefon sozlamalarida bildirişnomalarga ruxsat bering'**
  String get allowNotificationsInSettings;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In uz, this message translates to:
  /// **'Bildirişnomalarga ruxsat berilmadi'**
  String get notificationPermissionDenied;

  /// No description provided for @notificationUpdateFailed.
  ///
  /// In uz, this message translates to:
  /// **'Bildirişnoma sozlamalarini yangilab bölmadi'**
  String get notificationUpdateFailed;

  /// No description provided for @pushReminderTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bildirişnomalarni yoqing'**
  String get pushReminderTitle;

  /// No description provided for @pushReminderBody.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmangiz qabul qilinganda, tayyor bölganda va yölga çiqqanda xabar beramiz, şaxsiy promokodlar va ballar haqida eslatib turamiz.'**
  String get pushReminderBody;

  /// No description provided for @pushReminderSettingsHint.
  ///
  /// In uz, this message translates to:
  /// **'Bildirişnomalar telefon sozlamalarida öçirilgan. Sozlamalarni oçing, «Bildirişnomalar» bölimiga öting va ruxsat bering.'**
  String get pushReminderSettingsHint;

  /// No description provided for @pushReminderAllow.
  ///
  /// In uz, this message translates to:
  /// **'Ruxsat beriş'**
  String get pushReminderAllow;

  /// No description provided for @pushReminderOpenSettings.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalarni oçiş'**
  String get pushReminderOpenSettings;

  /// No description provided for @pushReminderLater.
  ///
  /// In uz, this message translates to:
  /// **'Hozir emas'**
  String get pushReminderLater;

  /// No description provided for @pushReminderNever.
  ///
  /// In uz, this message translates to:
  /// **'Boşqa eslatmang'**
  String get pushReminderNever;

  /// No description provided for @notifications.
  ///
  /// In uz, this message translates to:
  /// **'Bildirişnomalar'**
  String get notifications;

  /// No description provided for @notificationInbox.
  ///
  /// In uz, this message translates to:
  /// **'Xabarlar'**
  String get notificationInbox;

  /// No description provided for @notificationInboxSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangiliklar va takliflar bir joyda'**
  String get notificationInboxSubtitle;

  /// No description provided for @filterOrders.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar'**
  String get filterOrders;

  /// No description provided for @filterPromotions.
  ///
  /// In uz, this message translates to:
  /// **'Aksiyalar'**
  String get filterPromotions;

  /// No description provided for @noNotificationsForFilter.
  ///
  /// In uz, this message translates to:
  /// **'Bu filtrga mos bildirişnoma yöq.'**
  String get noNotificationsForFilter;

  /// No description provided for @markAllRead.
  ///
  /// In uz, this message translates to:
  /// **'Barçasini öqilgan qiliş'**
  String get markAllRead;

  /// No description provided for @markUnread.
  ///
  /// In uz, this message translates to:
  /// **'Öqilmagan qiliş'**
  String get markUnread;

  /// No description provided for @noNotifications.
  ///
  /// In uz, this message translates to:
  /// **'Hozirça xabarlar yöq'**
  String get noNotifications;

  /// No description provided for @noNotificationsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma yangiliklari va şaxsiy takliflar şu yerda körinadi.'**
  String get noNotificationsSubtitle;

  /// No description provided for @myPromotions.
  ///
  /// In uz, this message translates to:
  /// **'Mening promokodlarim'**
  String get myPromotions;

  /// No description provided for @myPromotionsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Siz uçun ajratilgan maxsus promokodlardan foydalaning.'**
  String get myPromotionsSubtitle;

  /// No description provided for @personalOffers.
  ///
  /// In uz, this message translates to:
  /// **'Siz uçun takliflar'**
  String get personalOffers;

  /// No description provided for @activePromotions.
  ///
  /// In uz, this message translates to:
  /// **'Faol'**
  String get activePromotions;

  /// No description provided for @allPromotions.
  ///
  /// In uz, this message translates to:
  /// **'Barçasi'**
  String get allPromotions;

  /// No description provided for @noAssignedPromotions.
  ///
  /// In uz, this message translates to:
  /// **'Faol promokod yöq'**
  String get noAssignedPromotions;

  /// No description provided for @noAssignedPromotionsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi şaxsiy taklif berilganda bu yerda paydo böladi.'**
  String get noAssignedPromotionsSubtitle;

  /// No description provided for @reward.
  ///
  /// In uz, this message translates to:
  /// **'Foyda'**
  String get reward;

  /// No description provided for @conditions.
  ///
  /// In uz, this message translates to:
  /// **'Şartlar'**
  String get conditions;

  /// No description provided for @validity.
  ///
  /// In uz, this message translates to:
  /// **'Amal qiliş muddati'**
  String get validity;

  /// No description provided for @usage.
  ///
  /// In uz, this message translates to:
  /// **'Foydalaniş'**
  String get usage;

  /// No description provided for @remainingUses.
  ///
  /// In uz, this message translates to:
  /// **'{count} marta foydalaniş mumkin'**
  String remainingUses(int count);

  /// No description provided for @validFrom.
  ///
  /// In uz, this message translates to:
  /// **'{date} dan amal qiladi'**
  String validFrom(String date);

  /// No description provided for @usePromo.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmada işlatiş'**
  String get usePromo;

  /// No description provided for @promoReadyForCheckout.
  ///
  /// In uz, this message translates to:
  /// **'{code} promokodi buyurtma uçun tanlandi'**
  String promoReadyForCheckout(String code);

  /// No description provided for @promoStatusActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol'**
  String get promoStatusActive;

  /// No description provided for @promoStatusNotStarted.
  ///
  /// In uz, this message translates to:
  /// **'Tez orada'**
  String get promoStatusNotStarted;

  /// No description provided for @promoStatusUsed.
  ///
  /// In uz, this message translates to:
  /// **'Işlatilgan'**
  String get promoStatusUsed;

  /// No description provided for @promoStatusExpired.
  ///
  /// In uz, this message translates to:
  /// **'Muddati tugagan'**
  String get promoStatusExpired;

  /// No description provided for @promoStatusRevoked.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilingan'**
  String get promoStatusRevoked;

  /// No description provided for @promoStatusInactive.
  ///
  /// In uz, this message translates to:
  /// **'Faol emas'**
  String get promoStatusInactive;

  /// No description provided for @promoStatusLimitReached.
  ///
  /// In uz, this message translates to:
  /// **'Limit tugagan'**
  String get promoStatusLimitReached;

  /// No description provided for @marketingOffers.
  ///
  /// In uz, this message translates to:
  /// **'Aksiya va takliflar'**
  String get marketingOffers;

  /// No description provided for @marketingOffersSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Sizga mos promokod va çegirmalar haqida xabar oling'**
  String get marketingOffersSubtitle;

  /// No description provided for @appearance.
  ///
  /// In uz, this message translates to:
  /// **'Köriniş'**
  String get appearance;

  /// No description provided for @chooseAppColorMode.
  ///
  /// In uz, this message translates to:
  /// **'Ilova rang rejimini tanlang'**
  String get chooseAppColorMode;

  /// No description provided for @language.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get language;

  /// No description provided for @actions.
  ///
  /// In uz, this message translates to:
  /// **'Amallar'**
  String get actions;

  /// No description provided for @deleteAccount.
  ///
  /// In uz, this message translates to:
  /// **'Hisobni öçiriş'**
  String get deleteAccount;

  /// No description provided for @accountDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Hisobingiz öçirildi'**
  String get accountDeleted;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In uz, this message translates to:
  /// **'Hisobni öçirib bölmadi. Qayta urinib köring.'**
  String get deleteAccountFailed;

  /// No description provided for @deleteAccountQuestion.
  ///
  /// In uz, this message translates to:
  /// **'Hisob öçirilsinmi?'**
  String get deleteAccountQuestion;

  /// No description provided for @deleteAccountPermanentWarning.
  ///
  /// In uz, this message translates to:
  /// **'Bu amalni ortga qaytarib bölmaydi'**
  String get deleteAccountPermanentWarning;

  /// No description provided for @deleteAccountItemsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Quyidagilar öçiriladi:'**
  String get deleteAccountItemsTitle;

  /// No description provided for @deleteAccountProfilePhone.
  ///
  /// In uz, this message translates to:
  /// **'Profil va telefon raqami'**
  String get deleteAccountProfilePhone;

  /// No description provided for @deleteAccountSavedAddresses.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan yetkazib beriş manzillari'**
  String get deleteAccountSavedAddresses;

  /// No description provided for @deleteAccountBonusPoints.
  ///
  /// In uz, this message translates to:
  /// **'Töplangan bonus ballari'**
  String get deleteAccountBonusPoints;

  /// No description provided for @deleteAccountAcknowledgement.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarim butunlay öçirilişini tuşunaman'**
  String get deleteAccountAcknowledgement;

  /// No description provided for @deleting.
  ///
  /// In uz, this message translates to:
  /// **'Öçirilmoqda...'**
  String get deleting;

  /// No description provided for @deleteMyAccount.
  ///
  /// In uz, this message translates to:
  /// **'Hisobimni öçiriş'**
  String get deleteMyAccount;

  /// No description provided for @allOrders.
  ///
  /// In uz, this message translates to:
  /// **'Barça buyurtmalar'**
  String get allOrders;

  /// No description provided for @ordersSearchHint.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot, holat yoki buyurtma raqami'**
  String get ordersSearchHint;

  /// No description provided for @all.
  ///
  /// In uz, this message translates to:
  /// **'Barçasi'**
  String get all;

  /// No description provided for @anyStatus.
  ///
  /// In uz, this message translates to:
  /// **'Har qanday holat'**
  String get anyStatus;

  /// No description provided for @noOrdersMatchFilters.
  ///
  /// In uz, this message translates to:
  /// **'Filtrlarga mos buyurtma yöq'**
  String get noOrdersMatchFilters;

  /// No description provided for @appVersion.
  ///
  /// In uz, this message translates to:
  /// **'Ilova versiyasi'**
  String get appVersion;

  /// No description provided for @profilePointsLabel.
  ///
  /// In uz, this message translates to:
  /// **'BALLARIM'**
  String get profilePointsLabel;

  /// No description provided for @viewPoints.
  ///
  /// In uz, this message translates to:
  /// **'Köriş'**
  String get viewPoints;

  /// No description provided for @profileOrdersSection.
  ///
  /// In uz, this message translates to:
  /// **'BUYURTMALAR'**
  String get profileOrdersSection;

  /// No description provided for @profileOrderCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta'**
  String profileOrderCount(int count);

  /// No description provided for @myAddresses.
  ///
  /// In uz, this message translates to:
  /// **'Mening manzillarim'**
  String get myAddresses;

  /// No description provided for @profileAddressCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta'**
  String profileAddressCount(int count);

  /// No description provided for @editProfile.
  ///
  /// In uz, this message translates to:
  /// **'Profilni tahrirlaş'**
  String get editProfile;

  /// No description provided for @profileName.
  ///
  /// In uz, this message translates to:
  /// **'Ism'**
  String get profileName;

  /// No description provided for @profileUpdated.
  ///
  /// In uz, this message translates to:
  /// **'Profil yangilandi'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In uz, this message translates to:
  /// **'Profilni yangilab bölmadi'**
  String get profileUpdateFailed;

  /// No description provided for @savedAddresses.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan manzillar'**
  String get savedAddresses;

  /// No description provided for @noSavedAddresses.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan manzil yöq'**
  String get noSavedAddresses;

  /// No description provided for @noSavedAddressesSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani tezroq rasmiylaştiriş uçun manzil qöşing.'**
  String get noSavedAddressesSubtitle;

  /// No description provided for @addAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzil qöşiş'**
  String get addAddress;

  /// No description provided for @addressLabel.
  ///
  /// In uz, this message translates to:
  /// **'Manzil nomi'**
  String get addressLabel;

  /// No description provided for @addressLabelHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan, Uy'**
  String get addressLabelHint;

  /// No description provided for @setAsDefault.
  ///
  /// In uz, this message translates to:
  /// **'Asosiy qiliş'**
  String get setAsDefault;

  /// No description provided for @defaultAddress.
  ///
  /// In uz, this message translates to:
  /// **'Asosiy'**
  String get defaultAddress;

  /// No description provided for @addressSaved.
  ///
  /// In uz, this message translates to:
  /// **'Manzil saqlandi'**
  String get addressSaved;

  /// No description provided for @addressSaveFailed.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni saqlab bölmadi'**
  String get addressSaveFailed;

  /// No description provided for @addressDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Manzil öçirildi'**
  String get addressDeleted;

  /// No description provided for @addressDeleteFailed.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni öçirib bölmadi'**
  String get addressDeleteFailed;

  /// No description provided for @deleteAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni öçiriş'**
  String get deleteAddress;

  /// No description provided for @profileNotificationsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma holati va takliflar'**
  String get profileNotificationsSubtitle;

  /// No description provided for @orderStatusCooking.
  ///
  /// In uz, this message translates to:
  /// **'Tayyorlanmoqda'**
  String get orderStatusCooking;

  /// No description provided for @orderStatusReady.
  ///
  /// In uz, this message translates to:
  /// **'Tayyor'**
  String get orderStatusReady;

  /// No description provided for @orderStatusCourierAssigned.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer biriktirildi'**
  String get orderStatusCourierAssigned;

  /// No description provided for @orderStatusOnTheWay.
  ///
  /// In uz, this message translates to:
  /// **'Yölda'**
  String get orderStatusOnTheWay;

  /// No description provided for @paymentStatusPending.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmoqda'**
  String get paymentStatusPending;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In uz, this message translates to:
  /// **'Tölangan'**
  String get paymentStatusPaid;

  /// No description provided for @paymentStatusFailed.
  ///
  /// In uz, this message translates to:
  /// **'Tölanmadi'**
  String get paymentStatusFailed;

  /// No description provided for @paymentStatusRefunded.
  ///
  /// In uz, this message translates to:
  /// **'Qaytarilgan'**
  String get paymentStatusRefunded;

  /// No description provided for @product.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot'**
  String get product;

  /// No description provided for @noProductsInOrder.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmada mahsulot yöq'**
  String get noProductsInOrder;

  /// No description provided for @paymentLinkUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Tölov havolasi hali mavjud emas.'**
  String get paymentLinkUnavailable;

  /// No description provided for @completePaymentOnline.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn tölovni yakunlang.'**
  String get completePaymentOnline;

  /// No description provided for @paymentPageOpenFailed.
  ///
  /// In uz, this message translates to:
  /// **'Tölov sahifasini oçib bölmadi.'**
  String get paymentPageOpenFailed;

  /// No description provided for @retryPaymentFailed.
  ///
  /// In uz, this message translates to:
  /// **'Tölovni qayta uriniş imkoni bölmadi.'**
  String get retryPaymentFailed;

  /// No description provided for @orderDetails.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma tafsilotlari'**
  String get orderDetails;

  /// No description provided for @currentStatus.
  ///
  /// In uz, this message translates to:
  /// **'Joriy holat'**
  String get currentStatus;

  /// No description provided for @created.
  ///
  /// In uz, this message translates to:
  /// **'Yaratilgan'**
  String get created;

  /// No description provided for @scheduledFor.
  ///
  /// In uz, this message translates to:
  /// **'Rejalaştirilgan'**
  String get scheduledFor;

  /// No description provided for @lastUpdate.
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi yangilaniş'**
  String get lastUpdate;

  /// No description provided for @paymentStatus.
  ///
  /// In uz, this message translates to:
  /// **'Tölov holati'**
  String get paymentStatus;

  /// No description provided for @retryPayment.
  ///
  /// In uz, this message translates to:
  /// **'Tölovni qayta uriniş'**
  String get retryPayment;

  /// No description provided for @products.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar'**
  String get products;

  /// No description provided for @statusHistory.
  ///
  /// In uz, this message translates to:
  /// **'Holatlar tarixi'**
  String get statusHistory;

  /// No description provided for @additionalInfo.
  ///
  /// In uz, this message translates to:
  /// **'Qöşimça ma\'lumot'**
  String get additionalInfo;

  /// No description provided for @requiredChoice.
  ///
  /// In uz, this message translates to:
  /// **'Majburiy'**
  String get requiredChoice;

  /// No description provided for @optionalChoice.
  ///
  /// In uz, this message translates to:
  /// **'Ixtiyoriy'**
  String get optionalChoice;

  /// No description provided for @chooseAtLeastOptions.
  ///
  /// In uz, this message translates to:
  /// **'Kamida {count} ta tanlang'**
  String chooseAtLeastOptions(int count);

  /// No description provided for @addToCartFor.
  ///
  /// In uz, this message translates to:
  /// **'Qöşiş · {price}'**
  String addToCartFor(String price);

  /// No description provided for @kitchenOrder.
  ///
  /// In uz, this message translates to:
  /// **'Oşxona buyurtmasi'**
  String get kitchenOrder;

  /// No description provided for @loyaltyWallet.
  ///
  /// In uz, this message translates to:
  /// **'Mening ballarim'**
  String get loyaltyWallet;

  /// No description provided for @spendablePoints.
  ///
  /// In uz, this message translates to:
  /// **'Sarflaş uçun mavjud'**
  String get spendablePoints;

  /// No description provided for @reservedPoints.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar uçun band qilingan'**
  String get reservedPoints;

  /// No description provided for @loyaltyDebt.
  ///
  /// In uz, this message translates to:
  /// **'Ballar böyiça qarz'**
  String get loyaltyDebt;

  /// No description provided for @loyaltyDebtHint.
  ///
  /// In uz, this message translates to:
  /// **'Yangi ballar avval uşbu qarzni qoplaydi.'**
  String get loyaltyDebtHint;

  /// No description provided for @pointsExpiringSoon.
  ///
  /// In uz, this message translates to:
  /// **'7 kun içida tugaydi'**
  String get pointsExpiringSoon;

  /// No description provided for @nextPointsExpiry.
  ///
  /// In uz, this message translates to:
  /// **'Eng yaqin tugaş sanasi'**
  String get nextPointsExpiry;

  /// No description provided for @loyaltyHistory.
  ///
  /// In uz, this message translates to:
  /// **'Ballar tarixi'**
  String get loyaltyHistory;

  /// No description provided for @loyaltyHistoryEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Ballar bilan amallar şu yerda körinadi.'**
  String get loyaltyHistoryEmpty;

  /// No description provided for @loyaltyProgramUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Ballar dasturi vaqtinça mavjud emas.'**
  String get loyaltyProgramUnavailable;

  /// No description provided for @loyaltyRedemptionUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Hozir ballarni sarflaş imkoni yöq.'**
  String get loyaltyRedemptionUnavailable;

  /// No description provided for @loyaltyHowItWorks.
  ///
  /// In uz, this message translates to:
  /// **'Ballar qanday işlaydi'**
  String get loyaltyHowItWorks;

  /// No description provided for @loyaltyPointValueInfo.
  ///
  /// In uz, this message translates to:
  /// **'1 ball 1 sömga teng.'**
  String get loyaltyPointValueInfo;

  /// No description provided for @loyaltyEarningInfo.
  ///
  /// In uz, this message translates to:
  /// **'Ball miqdori buyurtma yetkazilgandagi faol aksiyaga boğliq.'**
  String get loyaltyEarningInfo;

  /// No description provided for @loyaltyValidityInfo.
  ///
  /// In uz, this message translates to:
  /// **'Olingan ballar körsatilgan muddat davomida amal qiladi.'**
  String get loyaltyValidityInfo;

  /// No description provided for @loyaltyFeesDeliveryAllowed.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib berişni ballar bilan tölaş mumkin.'**
  String get loyaltyFeesDeliveryAllowed;

  /// No description provided for @loyaltyFeesDeliveryNotAllowed.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib berişni ballar bilan tölab bölmaydi.'**
  String get loyaltyFeesDeliveryNotAllowed;

  /// No description provided for @loyaltyFeesServiceAllowed.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat haqini ballar bilan tölaş mumkin.'**
  String get loyaltyFeesServiceAllowed;

  /// No description provided for @loyaltyFeesServiceNotAllowed.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat haqini ballar bilan tölab bölmaydi.'**
  String get loyaltyFeesServiceNotAllowed;

  /// No description provided for @validForDays.
  ///
  /// In uz, this message translates to:
  /// **'Amal qiliş muddati (kun)'**
  String get validForDays;

  /// No description provided for @usePoints.
  ///
  /// In uz, this message translates to:
  /// **'Ballar bilan tölaş'**
  String get usePoints;

  /// No description provided for @pointsAvailable.
  ///
  /// In uz, this message translates to:
  /// **'Mavjud ballar'**
  String get pointsAvailable;

  /// No description provided for @pointsInputHint.
  ///
  /// In uz, this message translates to:
  /// **'Butun ball kiriting'**
  String get pointsInputHint;

  /// No description provided for @useMaximum.
  ///
  /// In uz, this message translates to:
  /// **'Maksimumini işlatiş'**
  String get useMaximum;

  /// No description provided for @continueWithoutPoints.
  ///
  /// In uz, this message translates to:
  /// **'Ballarsiz davom etiş'**
  String get continueWithoutPoints;

  /// No description provided for @pointsDebtCheckout.
  ///
  /// In uz, this message translates to:
  /// **'Qarz mavjud paytda ballarni işlatib bölmaydi.'**
  String get pointsDebtCheckout;

  /// No description provided for @fullyPaidWithPoints.
  ///
  /// In uz, this message translates to:
  /// **'Töliq ballar bilan tölandi'**
  String get fullyPaidWithPoints;

  /// No description provided for @orderBeforePoints.
  ///
  /// In uz, this message translates to:
  /// **'Ballargaça buyurtma summasi'**
  String get orderBeforePoints;

  /// No description provided for @pointsUsed.
  ///
  /// In uz, this message translates to:
  /// **'Işlatilgan ballar'**
  String get pointsUsed;

  /// No description provided for @amountToPay.
  ///
  /// In uz, this message translates to:
  /// **'Tölov summasi'**
  String get amountToPay;

  /// No description provided for @estimatedPoints.
  ///
  /// In uz, this message translates to:
  /// **'Taxminiy ballar'**
  String get estimatedPoints;

  /// No description provided for @estimatedPointsHint.
  ///
  /// In uz, this message translates to:
  /// **'Yakuniy miqdor buyurtma yetkazilganda aniqlanadi.'**
  String get estimatedPointsHint;

  /// No description provided for @loyaltyPending.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazilgandan söng hisoblanadi'**
  String get loyaltyPending;

  /// No description provided for @loyaltyEarned.
  ///
  /// In uz, this message translates to:
  /// **'Ballar qöşildi'**
  String get loyaltyEarned;

  /// No description provided for @loyaltyNoReward.
  ///
  /// In uz, this message translates to:
  /// **'Ball berilmadi'**
  String get loyaltyNoReward;

  /// No description provided for @loyaltyReversed.
  ///
  /// In uz, this message translates to:
  /// **'Ball beriş bekor qilindi'**
  String get loyaltyReversed;

  /// No description provided for @loyaltyRestored.
  ///
  /// In uz, this message translates to:
  /// **'Ballar qaytarildi'**
  String get loyaltyRestored;

  /// No description provided for @transactionEarn.
  ///
  /// In uz, this message translates to:
  /// **'Ballar olindi'**
  String get transactionEarn;

  /// No description provided for @transactionSpend.
  ///
  /// In uz, this message translates to:
  /// **'Ballar işlatildi'**
  String get transactionSpend;

  /// No description provided for @transactionRelease.
  ///
  /// In uz, this message translates to:
  /// **'Ballar qaytarildi'**
  String get transactionRelease;

  /// No description provided for @transactionExpiry.
  ///
  /// In uz, this message translates to:
  /// **'Ballar muddati tugadi'**
  String get transactionExpiry;

  /// No description provided for @transactionReversal.
  ///
  /// In uz, this message translates to:
  /// **'Ball beriş bekor qilindi'**
  String get transactionReversal;

  /// No description provided for @transactionDebtRepayment.
  ///
  /// In uz, this message translates to:
  /// **'Qarz qoplandi'**
  String get transactionDebtRepayment;

  /// No description provided for @transactionOpeningBalance.
  ///
  /// In uz, this message translates to:
  /// **'Boşlanğiç balans'**
  String get transactionOpeningBalance;

  /// No description provided for @transactionBalanceUpdate.
  ///
  /// In uz, this message translates to:
  /// **'Balans yangilandi'**
  String get transactionBalanceUpdate;

  /// No description provided for @retry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta uriniş'**
  String get retry;

  /// No description provided for @tabHome.
  ///
  /// In uz, this message translates to:
  /// **'Boş sahifa'**
  String get tabHome;

  /// No description provided for @homeGreeting.
  ///
  /// In uz, this message translates to:
  /// **'Assalomu alaykum, {name}.'**
  String homeGreeting(String name);

  /// No description provided for @loyaltyMoneyHint.
  ///
  /// In uz, this message translates to:
  /// **'1 ball 1 sömga teng · 50% gaça'**
  String get loyaltyMoneyHint;

  /// No description provided for @repeatOrderTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yana takrorlaymizmi?'**
  String get repeatOrderTitle;

  /// No description provided for @repeatOrderAction.
  ///
  /// In uz, this message translates to:
  /// **'Takrorlaş · {amount}'**
  String repeatOrderAction(String amount);

  /// No description provided for @save.
  ///
  /// In uz, this message translates to:
  /// **'Saqlaş'**
  String get save;

  /// No description provided for @markAllReadShort.
  ///
  /// In uz, this message translates to:
  /// **'Barçasini öqiş'**
  String get markAllReadShort;

  /// No description provided for @cartOpen.
  ///
  /// In uz, this message translates to:
  /// **'Savatni oçiş'**
  String get cartOpen;

  /// No description provided for @changePhoneNumber.
  ///
  /// In uz, this message translates to:
  /// **'Raqamni özgartiriş'**
  String get changePhoneNumber;

  /// No description provided for @caloriesLabel.
  ///
  /// In uz, this message translates to:
  /// **'{value} kkal'**
  String caloriesLabel(int value);

  /// No description provided for @weightGramsLabel.
  ///
  /// In uz, this message translates to:
  /// **'{value} g'**
  String weightGramsLabel(int value);

  /// No description provided for @cookingMinutesLabel.
  ///
  /// In uz, this message translates to:
  /// **'{value} daq'**
  String cookingMinutesLabel(int value);

  /// No description provided for @loyaltyBalancePoints.
  ///
  /// In uz, this message translates to:
  /// **'{value} ball'**
  String loyaltyBalancePoints(String value);

  /// No description provided for @useInOrder.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmada işlatiş'**
  String get useInOrder;

  /// No description provided for @promotionGift.
  ///
  /// In uz, this message translates to:
  /// **'Sovğa'**
  String get promotionGift;

  /// No description provided for @backToHome.
  ///
  /// In uz, this message translates to:
  /// **'Boş sahifaga'**
  String get backToHome;

  /// No description provided for @orderingAvailability.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma mavjudligi'**
  String get orderingAvailability;

  /// No description provided for @orderingChecking.
  ///
  /// In uz, this message translates to:
  /// **'Filial iş vaqti tekşirilmoqda…'**
  String get orderingChecking;

  /// No description provided for @orderingOpen.
  ///
  /// In uz, this message translates to:
  /// **'Hozir oçiq'**
  String get orderingOpen;

  /// No description provided for @orderingClosed.
  ///
  /// In uz, this message translates to:
  /// **'Hozir mavjud emas'**
  String get orderingClosed;

  /// No description provided for @pickupAvailability.
  ///
  /// In uz, this message translates to:
  /// **'Olib ketiş'**
  String get pickupAvailability;

  /// No description provided for @deliveryAvailability.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib beriş'**
  String get deliveryAvailability;

  /// No description provided for @orderingNextOpening.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi oçiliş: {value}'**
  String orderingNextOpening(String value);

  /// No description provided for @orderingStatusUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Iş vaqtini tekşirib bölmadi. Mavjudlik buyurtma paytida tekşiriladi.'**
  String get orderingStatusUnavailable;

  /// No description provided for @orderingClosedAction.
  ///
  /// In uz, this message translates to:
  /// **'Boşqa filialni tanlang yoki keyinroq urinib köring.'**
  String get orderingClosedAction;

  /// No description provided for @promoCodeNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Promokod topilmadi'**
  String get promoCodeNotFound;

  /// No description provided for @promoCodeInactive.
  ///
  /// In uz, this message translates to:
  /// **'Promokod faol emas'**
  String get promoCodeInactive;

  /// No description provided for @promoCodeNotStarted.
  ///
  /// In uz, this message translates to:
  /// **'Promokod hali amal qilmaydi'**
  String get promoCodeNotStarted;

  /// No description provided for @promoCodeExpired.
  ///
  /// In uz, this message translates to:
  /// **'Promokod muddati tugagan'**
  String get promoCodeExpired;

  /// No description provided for @promoGlobalLimitReached.
  ///
  /// In uz, this message translates to:
  /// **'Aksiya limiti tugagan'**
  String get promoGlobalLimitReached;

  /// No description provided for @promoClientLimitReached.
  ///
  /// In uz, this message translates to:
  /// **'Bu promokoddan allaqaçon foydalangansiz'**
  String get promoClientLimitReached;

  /// No description provided for @promoClientRequired.
  ///
  /// In uz, this message translates to:
  /// **'Promokoddan foydalaniş uçun tizimga kiring'**
  String get promoClientRequired;

  /// No description provided for @promoConditionsNotMet.
  ///
  /// In uz, this message translates to:
  /// **'Promokod şartlari bajarilmadi'**
  String get promoConditionsNotMet;

  /// No description provided for @promoConfigurationError.
  ///
  /// In uz, this message translates to:
  /// **'Hozir promokodni qöllab bölmaydi'**
  String get promoConfigurationError;

  /// No description provided for @promoCodeCouldNotBeApplied.
  ///
  /// In uz, this message translates to:
  /// **'Promokodni qöllab bölmadi'**
  String get promoCodeCouldNotBeApplied;

  /// No description provided for @cartQuantityLimitReached.
  ///
  /// In uz, this message translates to:
  /// **'Bitta mahsulotdan köpi bilan {count} ta qöşiş mumkin'**
  String cartQuantityLimitReached(int count);

  /// No description provided for @cartItemsUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Endi mavjud emas, savatdan olib taşlandi: {items}'**
  String cartItemsUnavailable(String items);

  /// No description provided for @cartSomeItemsUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Ba’zi mahsulotlar endi mavjud emas va savatdan olib taşlandi'**
  String get cartSomeItemsUnavailable;

  /// No description provided for @repeatOrderSkipped.
  ///
  /// In uz, this message translates to:
  /// **'Savatga qöşib bölmadi: {items}'**
  String repeatOrderSkipped(String items);
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'ru':
      return LRu();
    case 'uz':
      return LUz();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
