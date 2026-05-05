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
  /// **'EnjoyLavash ilovasini ko\'ring: https://enjoylavash.uz'**
  String get shareAppText;

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
