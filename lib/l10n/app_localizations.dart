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
  /// **'Yetkazib berish'**
  String get delivery;

  /// No description provided for @pickup.
  ///
  /// In uz, this message translates to:
  /// **'Olib ketish'**
  String get pickup;

  /// No description provided for @specialOffer.
  ///
  /// In uz, this message translates to:
  /// **'Maxsus taklif'**
  String get specialOffer;

  /// No description provided for @specialOfferDesc.
  ///
  /// In uz, this message translates to:
  /// **'Hafta oxirigacha lavashga 20% chegirma'**
  String get specialOfferDesc;

  /// No description provided for @specialOfferCta.
  ///
  /// In uz, this message translates to:
  /// **'🔥 Buyurtma bering'**
  String get specialOfferCta;

  /// No description provided for @cartEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Savat bo\'sh'**
  String get cartEmpty;

  /// No description provided for @cartEmptyDesc.
  ///
  /// In uz, this message translates to:
  /// **'Menyudan taom qo\'shing va bir necha bosishda buyurtma bering.'**
  String get cartEmptyDesc;

  /// No description provided for @browseMenu.
  ///
  /// In uz, this message translates to:
  /// **'Menyuga o\'tish'**
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
  /// **'Buyurtma berish'**
  String get checkout;

  /// No description provided for @viewCart.
  ///
  /// In uz, this message translates to:
  /// **'Savatni ochish'**
  String get viewCart;

  /// No description provided for @cartItemsCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta mahsulot'**
  String cartItemsCount(int count);

  /// No description provided for @itemRemovedFromCart.
  ///
  /// In uz, this message translates to:
  /// **'{product} savatdan olib tashlandi'**
  String itemRemovedFromCart(String product);

  /// No description provided for @undo.
  ///
  /// In uz, this message translates to:
  /// **'Qaytarish'**
  String get undo;

  /// No description provided for @increaseQuantity.
  ///
  /// In uz, this message translates to:
  /// **'Miqdorni oshirish'**
  String get increaseQuantity;

  /// No description provided for @decreaseQuantity.
  ///
  /// In uz, this message translates to:
  /// **'Miqdorni kamaytirish'**
  String get decreaseQuantity;

  /// No description provided for @menuLoading.
  ///
  /// In uz, this message translates to:
  /// **'Menyu tayyorlanmoqda...'**
  String get menuLoading;

  /// No description provided for @searchAgain.
  ///
  /// In uz, this message translates to:
  /// **'Qidiruvni tozalash'**
  String get searchAgain;

  /// No description provided for @orderCreated.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma yaratildi'**
  String get orderCreated;

  /// No description provided for @orderSuccessTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmangiz qabul qilindi!'**
  String get orderSuccessTitle;

  /// No description provided for @orderSuccessMessage.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma oshxonaga yuborildi. Holatini profilingizda kuzatib boring.'**
  String get orderSuccessMessage;

  /// No description provided for @orderSuccessNumber.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma #{number}'**
  String orderSuccessNumber(String number);

  /// No description provided for @trackOrder.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani kuzatish'**
  String get trackOrder;

  /// No description provided for @orderSuccessPaymentOpening.
  ///
  /// In uz, this message translates to:
  /// **'Xavfsiz to\'lov sahifasi ochilmoqda…'**
  String get orderSuccessPaymentOpening;

  /// No description provided for @orderSuccessPaymentOpened.
  ///
  /// In uz, this message translates to:
  /// **'Ochilgan sahifada to\'lovni yakunlang.'**
  String get orderSuccessPaymentOpened;

  /// No description provided for @orderSuccessPayOnReceipt.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani olganda to\'lov qilasiz.'**
  String get orderSuccessPayOnReceipt;

  /// No description provided for @orderSuccessPaymentPaid.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov qabul qilindi. Hammasi tayyor.'**
  String get orderSuccessPaymentPaid;

  /// No description provided for @orderSuccessPaymentFailed.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov yakunlanmadi. Keyingi qadamni buyurtma tafsilotlarida ko\'ring.'**
  String get orderSuccessPaymentFailed;

  /// No description provided for @orderSuccessPaymentRefunded.
  ///
  /// In uz, this message translates to:
  /// **'Ushbu to\'lov qaytarildi.'**
  String get orderSuccessPaymentRefunded;

  /// No description provided for @orderCreateFailed.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma yaratib bo\'lmadi. Qayta urinib ko\'ring.'**
  String get orderCreateFailed;

  /// No description provided for @selectDeliveryAddressFirst.
  ///
  /// In uz, this message translates to:
  /// **'Avval yetkazib berish manzilini tanlang'**
  String get selectDeliveryAddressFirst;

  /// No description provided for @selectPickupBranchFirst.
  ///
  /// In uz, this message translates to:
  /// **'Avval olib ketish filialini tanlang'**
  String get selectPickupBranchFirst;

  /// No description provided for @paymentMethodsUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov usullari vaqtincha mavjud emas. Qayta urinib ko\'ring.'**
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
  /// **'Yorug\''**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In uz, this message translates to:
  /// **'Qorong\'i'**
  String get darkTheme;

  /// No description provided for @loyaltyCard.
  ///
  /// In uz, this message translates to:
  /// **'Sodiqlik kartasi'**
  String get loyaltyCard;

  /// No description provided for @accumulatedPoints.
  ///
  /// In uz, this message translates to:
  /// **'To\'plangan ballar'**
  String get accumulatedPoints;

  /// No description provided for @showCodeForPoints.
  ///
  /// In uz, this message translates to:
  /// **'Ball olish uchun to\'lovda kodni ko\'rsating'**
  String get showCodeForPoints;

  /// No description provided for @personalInfo.
  ///
  /// In uz, this message translates to:
  /// **'Shaxsiy ma\'lumotlar'**
  String get personalInfo;

  /// No description provided for @email.
  ///
  /// In uz, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @address.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get address;

  /// No description provided for @customerId.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz ID'**
  String get customerId;

  /// No description provided for @orderHistory.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar tarixi'**
  String get orderHistory;

  /// No description provided for @completed.
  ///
  /// In uz, this message translates to:
  /// **'Bajarildi'**
  String get completed;

  /// No description provided for @cashbackSystem.
  ///
  /// In uz, this message translates to:
  /// **'Keshbek tizimi'**
  String get cashbackSystem;

  /// No description provided for @perOrder.
  ///
  /// In uz, this message translates to:
  /// **'Har bir buyurtma uchun'**
  String get perOrder;

  /// No description provided for @perOrderValue.
  ///
  /// In uz, this message translates to:
  /// **'5% ball'**
  String get perOrderValue;

  /// No description provided for @onePointEquals.
  ///
  /// In uz, this message translates to:
  /// **'1 ball teng'**
  String get onePointEquals;

  /// No description provided for @onePointValue.
  ///
  /// In uz, this message translates to:
  /// **'1 so\'m'**
  String get onePointValue;

  /// No description provided for @canSpend.
  ///
  /// In uz, this message translates to:
  /// **'Sarflash mumkin'**
  String get canSpend;

  /// No description provided for @canSpendValue.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmaning 50% gacha'**
  String get canSpendValue;

  /// No description provided for @shareApp.
  ///
  /// In uz, this message translates to:
  /// **'Ilovani ulashish'**
  String get shareApp;

  /// No description provided for @shareAppText.
  ///
  /// In uz, this message translates to:
  /// **'EnjoyLavash ilovasini ko\'ring: https://play.google.com/store/apps/details?id=com.aurumdev.enjoy_lavash_mobile'**
  String get shareAppText;

  /// No description provided for @logout.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In uz, this message translates to:
  /// **'Akkauntdan chiqasizmi?'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan token ushbu qurilmadan o\'chiriladi.'**
  String get logoutMessage;

  /// No description provided for @logoutFailed.
  ///
  /// In uz, this message translates to:
  /// **'Chiqib bo\'lmadi. Qayta urinib ko\'ring.'**
  String get logoutFailed;

  /// No description provided for @notFoundTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bu sahifa ishlab chiqilmoqda'**
  String get notFoundTitle;

  /// No description provided for @goHome.
  ///
  /// In uz, this message translates to:
  /// **'Bosh sahifaga'**
  String get goHome;

  /// No description provided for @emptyList.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxat bo\'sh'**
  String get emptyList;

  /// No description provided for @confirm.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In uz, this message translates to:
  /// **'Ha'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'q'**
  String get no;

  /// No description provided for @save.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get save;

  /// No description provided for @skip.
  ///
  /// In uz, this message translates to:
  /// **'O\'tkazib yuborish'**
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

  /// No description provided for @statusInProgress.
  ///
  /// In uz, this message translates to:
  /// **'Jarayonda'**
  String get statusInProgress;

  /// No description provided for @statusNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangi'**
  String get statusNew;

  /// No description provided for @statusArchive.
  ///
  /// In uz, this message translates to:
  /// **'Arxiv'**
  String get statusArchive;

  /// No description provided for @statusNeedAccept.
  ///
  /// In uz, this message translates to:
  /// **'Tovarni qabul qilish vaqti!'**
  String get statusNeedAccept;

  /// No description provided for @tableNumber.
  ///
  /// In uz, this message translates to:
  /// **'№'**
  String get tableNumber;

  /// No description provided for @tableName.
  ///
  /// In uz, this message translates to:
  /// **'Nom.'**
  String get tableName;

  /// No description provided for @tableSent.
  ///
  /// In uz, this message translates to:
  /// **'Yub.'**
  String get tableSent;

  /// No description provided for @tableReceived.
  ///
  /// In uz, this message translates to:
  /// **'Qab.'**
  String get tableReceived;

  /// No description provided for @tableDifference.
  ///
  /// In uz, this message translates to:
  /// **'Farq.'**
  String get tableDifference;

  /// No description provided for @status.
  ///
  /// In uz, this message translates to:
  /// **'Holat:'**
  String get status;

  /// No description provided for @deliveryAddress.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib berish manzili'**
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
  /// **'Kirish'**
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
  /// **'Kuryer uchun ko\'rsatmalar...'**
  String get commentHint;

  /// No description provided for @confirmAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni tasdiqlash'**
  String get confirmAddress;

  /// No description provided for @tapToSelectAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni tanlash uchun bosing'**
  String get tapToSelectAddress;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuv ruxsati rad etildi'**
  String get locationPermissionDenied;

  /// No description provided for @enableLocation.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvni yoqish'**
  String get enableLocation;

  /// No description provided for @currentLocation.
  ///
  /// In uz, this message translates to:
  /// **'Joriy joylashuv'**
  String get currentLocation;

  /// No description provided for @selectBranch.
  ///
  /// In uz, this message translates to:
  /// **'Filialni tanlang'**
  String get selectBranch;

  /// No description provided for @branchWorkingHours.
  ///
  /// In uz, this message translates to:
  /// **'Ish vaqti'**
  String get branchWorkingHours;

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

  /// No description provided for @aboutUs.
  ///
  /// In uz, this message translates to:
  /// **'Biz haqimizda'**
  String get aboutUs;

  /// No description provided for @contactUs.
  ///
  /// In uz, this message translates to:
  /// **'Bog\'lanish'**
  String get contactUs;

  /// No description provided for @authorization.
  ///
  /// In uz, this message translates to:
  /// **'Avtorizatsiya'**
  String get authorization;

  /// No description provided for @tapToSignIn.
  ///
  /// In uz, this message translates to:
  /// **'Kirish va profilingizni ko\'rish uchun bosing'**
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
  /// **'Telefon raqamingizga tasdiqlash kodi yuborildi.'**
  String get otpSentMessage;

  /// No description provided for @signInToCheckout.
  ///
  /// In uz, this message translates to:
  /// **'Savatdan buyurtma berish uchun tizimga kiring.'**
  String get signInToCheckout;

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
  /// **'Sizning maxsus kuningiz 🎂'**
  String get birthDateTitle;

  /// No description provided for @birthDate.
  ///
  /// In uz, this message translates to:
  /// **'Tug\'ilgan sana'**
  String get birthDate;

  /// No description provided for @selectBirthDate.
  ///
  /// In uz, this message translates to:
  /// **'Tug\'ilgan sanani tanlang'**
  String get selectBirthDate;

  /// No description provided for @otpCodeExpiresIn.
  ///
  /// In uz, this message translates to:
  /// **'Kod {time} dan keyin tugaydi'**
  String otpCodeExpiresIn(String time);

  /// No description provided for @otpCodeExpired.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash kodining muddati tugadi.'**
  String get otpCodeExpired;

  /// No description provided for @resendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni qayta yuborish'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In uz, this message translates to:
  /// **'{time} dan keyin qayta yuborish'**
  String resendCodeIn(String time);

  /// No description provided for @tryAgainIn.
  ///
  /// In uz, this message translates to:
  /// **'{time} dan keyin qayta urining'**
  String tryAgainIn(String time);

  /// No description provided for @sendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kod yuborish'**
  String get sendCode;

  /// No description provided for @continueButton.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
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
  /// **'Chegirma'**
  String get discount;

  /// No description provided for @validUntil.
  ///
  /// In uz, this message translates to:
  /// **'{date} gacha amal qiladi'**
  String validUntil(String date);

  /// No description provided for @copyCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni nusxalash'**
  String get copyCode;

  /// No description provided for @close.
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get close;

  /// No description provided for @orderCreatedPaymentOnline.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma yaratildi. Onlayn to\'lovni yakunlang.'**
  String get orderCreatedPaymentOnline;

  /// No description provided for @orderCreatedPaymentPageOpenFailed.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma yaratildi, ammo to\'lov sahifasi ochilmadi.'**
  String get orderCreatedPaymentPageOpenFailed;

  /// No description provided for @enterPromoCode.
  ///
  /// In uz, this message translates to:
  /// **'Promokodni kiriting'**
  String get enterPromoCode;

  /// No description provided for @apply.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'llash'**
  String get apply;

  /// No description provided for @couldNotCalculateTotal.
  ///
  /// In uz, this message translates to:
  /// **'Jami summani hisoblab bo\'lmadi'**
  String get couldNotCalculateTotal;

  /// No description provided for @createOrderTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma berish'**
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
  /// **'Bekor qilish'**
  String get cancel;

  /// No description provided for @createOrderAction.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma berish'**
  String get createOrderAction;

  /// No description provided for @payment.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov'**
  String get payment;

  /// No description provided for @onlinePayment.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn to\'lov'**
  String get onlinePayment;

  /// No description provided for @payOnReceipt.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qilganda to\'lash'**
  String get payOnReceipt;

  /// No description provided for @calculatingTotal.
  ///
  /// In uz, this message translates to:
  /// **'Jami hisoblanmoqda'**
  String get calculatingTotal;

  /// No description provided for @recalculate.
  ///
  /// In uz, this message translates to:
  /// **'Qayta hisoblash'**
  String get recalculate;

  /// No description provided for @orderPreview.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma hisobi'**
  String get orderPreview;

  /// No description provided for @items.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar'**
  String get items;

  /// No description provided for @modifiers.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shimchalar'**
  String get modifiers;

  /// No description provided for @serviceFee.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat haqi'**
  String get serviceFee;

  /// No description provided for @pickupBranch.
  ///
  /// In uz, this message translates to:
  /// **'Olib ketish filiali'**
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
  /// **'Ulanishda muammo'**
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
  /// **'Nimadir noto\'g\'ri ketdi'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericBody.
  ///
  /// In uz, this message translates to:
  /// **'Birozdan keyin qayta urinib ko\'ring.'**
  String get errorGenericBody;

  /// No description provided for @retry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retry;

  /// No description provided for @searchProducts.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot qidirish'**
  String get searchProducts;

  /// No description provided for @clearSearch.
  ///
  /// In uz, this message translates to:
  /// **'Qidiruvni tozalash'**
  String get clearSearch;

  /// No description provided for @searchProductsResultCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta natija'**
  String searchProductsResultCount(int count);

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
  /// **'Bu joy tekshirilmoqda'**
  String get checkingThisLocation;

  /// No description provided for @gettingAddressDetails.
  ///
  /// In uz, this message translates to:
  /// **'Manzil ma\'lumotlari olinmoqda'**
  String get gettingAddressDetails;

  /// No description provided for @allowNotificationsInSettings.
  ///
  /// In uz, this message translates to:
  /// **'Telefon sozlamalarida bildirishnomalarga ruxsat bering'**
  String get allowNotificationsInSettings;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalarga ruxsat berilmadi'**
  String get notificationPermissionDenied;

  /// No description provided for @notificationUpdateFailed.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnoma sozlamalarini yangilab bo\'lmadi'**
  String get notificationUpdateFailed;

  /// No description provided for @notifications.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar'**
  String get notifications;

  /// No description provided for @appearance.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rinish'**
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

  /// No description provided for @languageSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ilovadan qulay tilda foydalaning'**
  String get languageSubtitle;

  /// No description provided for @seeAllOrders.
  ///
  /// In uz, this message translates to:
  /// **'Barcha buyurtmalar'**
  String get seeAllOrders;

  /// No description provided for @actions.
  ///
  /// In uz, this message translates to:
  /// **'Amallar'**
  String get actions;

  /// No description provided for @deleteAccount.
  ///
  /// In uz, this message translates to:
  /// **'Hisobni o\'chirish'**
  String get deleteAccount;

  /// No description provided for @accountDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Hisobingiz o\'chirildi'**
  String get accountDeleted;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In uz, this message translates to:
  /// **'Hisobni o\'chirib bo\'lmadi. Qayta urinib ko\'ring.'**
  String get deleteAccountFailed;

  /// No description provided for @deleteAccountQuestion.
  ///
  /// In uz, this message translates to:
  /// **'Hisob o\'chirilsinmi?'**
  String get deleteAccountQuestion;

  /// No description provided for @deleteAccountPermanentWarning.
  ///
  /// In uz, this message translates to:
  /// **'Bu amalni ortga qaytarib bo\'lmaydi'**
  String get deleteAccountPermanentWarning;

  /// No description provided for @deleteAccountItemsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Quyidagilar o\'chiriladi:'**
  String get deleteAccountItemsTitle;

  /// No description provided for @deleteAccountProfilePhone.
  ///
  /// In uz, this message translates to:
  /// **'Profil va telefon raqami'**
  String get deleteAccountProfilePhone;

  /// No description provided for @deleteAccountSavedAddresses.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan yetkazib berish manzillari'**
  String get deleteAccountSavedAddresses;

  /// No description provided for @deleteAccountBonusPoints.
  ///
  /// In uz, this message translates to:
  /// **'To\'plangan bonus ballari'**
  String get deleteAccountBonusPoints;

  /// No description provided for @deleteAccountAcknowledgement.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarim butunlay o\'chirilishini tushunaman'**
  String get deleteAccountAcknowledgement;

  /// No description provided for @deleting.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirilmoqda...'**
  String get deleting;

  /// No description provided for @deleteMyAccount.
  ///
  /// In uz, this message translates to:
  /// **'Hisobimni o\'chirish'**
  String get deleteMyAccount;

  /// No description provided for @allOrders.
  ///
  /// In uz, this message translates to:
  /// **'Barcha buyurtmalar'**
  String get allOrders;

  /// No description provided for @ordersSearchHint.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot, holat yoki buyurtma raqami'**
  String get ordersSearchHint;

  /// No description provided for @all.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi'**
  String get all;

  /// No description provided for @anyStatus.
  ///
  /// In uz, this message translates to:
  /// **'Har qanday holat'**
  String get anyStatus;

  /// No description provided for @noOrdersMatchFilters.
  ///
  /// In uz, this message translates to:
  /// **'Filtrlarga mos buyurtma yo\'q'**
  String get noOrdersMatchFilters;

  /// No description provided for @appVersion.
  ///
  /// In uz, this message translates to:
  /// **'Ilova versiyasi'**
  String get appVersion;

  /// No description provided for @notificationCheckingPermission.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnoma ruxsati tekshirilmoqda'**
  String get notificationCheckingPermission;

  /// No description provided for @notificationsUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Bu qurilmada bildirishnomalar mavjud emas'**
  String get notificationsUnavailable;

  /// No description provided for @notificationsEnabled.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma holati va aksiyalar yoqilgan'**
  String get notificationsEnabled;

  /// No description provided for @notificationsSubtitleDefault.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma holati va maxsus takliflarni oling'**
  String get notificationsSubtitleDefault;

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
  /// **'Yo\'lda'**
  String get orderStatusOnTheWay;

  /// No description provided for @paymentStatusPending.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmoqda'**
  String get paymentStatusPending;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In uz, this message translates to:
  /// **'To\'langan'**
  String get paymentStatusPaid;

  /// No description provided for @paymentStatusFailed.
  ///
  /// In uz, this message translates to:
  /// **'To\'lanmadi'**
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
  /// **'Buyurtmada mahsulot yo\'q'**
  String get noProductsInOrder;

  /// No description provided for @paymentLinkUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov havolasi hali mavjud emas.'**
  String get paymentLinkUnavailable;

  /// No description provided for @completePaymentOnline.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn to\'lovni yakunlang.'**
  String get completePaymentOnline;

  /// No description provided for @paymentPageOpenFailed.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov sahifasini ochib bo\'lmadi.'**
  String get paymentPageOpenFailed;

  /// No description provided for @retryPaymentFailed.
  ///
  /// In uz, this message translates to:
  /// **'To\'lovni qayta urinish imkoni bo\'lmadi.'**
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
  /// **'Rejalashtirilgan'**
  String get scheduledFor;

  /// No description provided for @lastUpdate.
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi yangilanish'**
  String get lastUpdate;

  /// No description provided for @paymentStatus.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov holati'**
  String get paymentStatus;

  /// No description provided for @retryPayment.
  ///
  /// In uz, this message translates to:
  /// **'To\'lovni qayta urinish'**
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
  /// **'Qo\'shimcha ma\'lumot'**
  String get additionalInfo;

  /// No description provided for @kitchenOrder.
  ///
  /// In uz, this message translates to:
  /// **'Oshxona buyurtmasi'**
  String get kitchenOrder;
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
