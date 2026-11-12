// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class LUz extends L {
  LUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Enjoy Lavash';

  @override
  String get tabMenu => 'Menyu';

  @override
  String get tabCart => 'Savat';

  @override
  String get tabProfile => 'Profil';

  @override
  String get delivery => 'Yetkazib beriş';

  @override
  String get pickup => 'Olib ketiş';

  @override
  String get cartEmpty => 'Savat böş';

  @override
  String get cartEmptyDesc =>
      'Menyudan taom qöşing va bir neça bosişda buyurtma bering.';

  @override
  String get browseMenu => 'Menyuga ötiş';

  @override
  String get cart => 'Savat';

  @override
  String get total => 'Jami';

  @override
  String get checkout => 'Buyurtma beriş';

  @override
  String get viewCart => 'Savatni oçiş';

  @override
  String cartItemsCount(int count) {
    return '$count ta mahsulot';
  }

  @override
  String itemAddedToCart(String product) {
    return '$product savatga qöşildi';
  }

  @override
  String itemRemovedFromCart(String product) {
    return '$product savatdan olib taşlandi';
  }

  @override
  String get undo => 'Qaytariş';

  @override
  String get increaseQuantity => 'Miqdorni oşiriş';

  @override
  String get decreaseQuantity => 'Miqdorni kamaytiriş';

  @override
  String get menuLoading => 'Menyu tayyorlanmoqda...';

  @override
  String get orderSuccessTitle => 'Buyurtmangiz qabul qilindi!';

  @override
  String get orderSuccessMessage =>
      'Buyurtma oşxonaga yuborildi. Holatini profilingizda kuzatib boring.';

  @override
  String orderSuccessNumber(String number) {
    return 'Buyurtma #$number';
  }

  @override
  String get trackOrder => 'Buyurtmani kuzatiş';

  @override
  String get orderSuccessPaymentOpening => 'Xavfsiz tölov sahifasi oçilmoqda…';

  @override
  String get orderSuccessPaymentOpened => 'Oçilgan sahifada tölovni yakunlang.';

  @override
  String get orderSuccessPayOnReceipt => 'Buyurtmani olganda tölov qilasiz.';

  @override
  String get orderSuccessPaymentPaid => 'Tölov qabul qilindi. Hammasi tayyor.';

  @override
  String get orderSuccessPaymentFailed =>
      'Tölov yakunlanmadi. Keyingi qadamni buyurtma tafsilotlarida köring.';

  @override
  String get orderSuccessPaymentRefunded => 'Uşbu tölov qaytarildi.';

  @override
  String get orderCreateFailed =>
      'Buyurtma yaratib bölmadi. Qayta urinib köring.';

  @override
  String get selectDeliveryAddressFirst =>
      'Avval yetkazib beriş manzilini tanlang';

  @override
  String get selectPickupBranchFirst => 'Avval olib ketiş filialini tanlang';

  @override
  String get paymentMethodsUnavailable =>
      'Tölov usullari vaqtinça mavjud emas. Qayta urinib köring.';

  @override
  String get profile => 'Profil';

  @override
  String get guest => 'Mehmon';

  @override
  String get lightTheme => 'Yoruğ';

  @override
  String get darkTheme => 'Qoronği';

  @override
  String get address => 'Manzil';

  @override
  String get orderHistory => 'Buyurtmalar tarixi';

  @override
  String get shareApp => 'Ilovani ulaşiş';

  @override
  String get shareAppText =>
      'EnjoyLavash ilovasini köring: https://play.google.com/store/apps/details?id=com.aurumdev.enjoy_lavash_mobile';

  @override
  String get logout => 'Çiqiş';

  @override
  String get logoutTitle => 'Akkauntdan çiqasizmi?';

  @override
  String get logoutMessage => 'Saqlangan token uşbu qurilmadan öçiriladi.';

  @override
  String get logoutFailed => 'Çiqib bölmadi. Qayta urinib köring.';

  @override
  String get emptyList => 'Röyxat böş';

  @override
  String get no => 'Yöq';

  @override
  String get skip => 'Ötkazib yuboriş';

  @override
  String get statusCompleted => 'Yakunlangan';

  @override
  String get statusAccepted => 'Qabul qilingan';

  @override
  String get statusCancelled => 'Rad etilgan';

  @override
  String get statusFailed => 'Bekor qilingan';

  @override
  String get statusNew => 'Yangi';

  @override
  String get status => 'Holat:';

  @override
  String get deliveryAddress => 'Yetkazib beriş manzili';

  @override
  String get searchAddress => 'Manzilni qidiring...';

  @override
  String get houseNumber => 'Uy raqami';

  @override
  String get houseNumberHint => 'masalan 25A';

  @override
  String get entranceLabel => 'Kiriş';

  @override
  String get floorLabel => 'Qavat';

  @override
  String get apartmentLabel => 'Xona';

  @override
  String get commentLabel => 'Izoh';

  @override
  String get commentHint => 'Kuryer uçun körsatmalar...';

  @override
  String get confirmAddress => 'Manzilni tasdiqlaş';

  @override
  String get tapToSelectAddress => 'Manzilni tanlaş uçun bosing';

  @override
  String get selectBranch => 'Filialni tanlang';

  @override
  String get menu => 'Menyu';

  @override
  String get settings => 'Sozlamalar';

  @override
  String get authorization => 'Avtorizatsiya';

  @override
  String get tapToSignIn => 'Kiriş va profilingizni köriş uçun bosing';

  @override
  String get enterPhoneNumber => 'Telefon raqamingizni kiriting';

  @override
  String get enterSmsCode => 'SMS kodni kiriting';

  @override
  String get otpSentMessage => 'Telefon raqamingizga tasdiqlaş kodi yuborildi.';

  @override
  String get authWelcomeSubtitle =>
      'Sevimli taomlaringizni buyurtma qiling va amaldagi aksiyalardan ball oling.';

  @override
  String get phoneNumber => 'Telefon raqami';

  @override
  String get smsCode => 'SMS kod';

  @override
  String get nameOptional => 'Ism (ixtiyoriy)';

  @override
  String get birthDateTitle => 'Sizning tuğilgan kuningiz 🎂';

  @override
  String get birthDate => 'Tuğilgan sana';

  @override
  String get selectBirthDate => 'Tuğilgan sanani tanlang';

  @override
  String get birthDateSubtitle =>
      'Bir neça aylantirişda tanlang. Tuğilgan kuningiz uçun maxsus sovğalar tayyorlaymiz.';

  @override
  String get birthDateDay => 'Kun';

  @override
  String get birthDateMonth => 'Oy';

  @override
  String get birthDateYear => 'Yil';

  @override
  String otpCodeExpiresIn(String time) {
    return 'Kod $time dan keyin tugaydi';
  }

  @override
  String get otpCodeExpired => 'Tasdiqlaş kodining muddati tugadi.';

  @override
  String get resendCode => 'Kodni qayta yuboriş';

  @override
  String resendCodeIn(String time) {
    return '$time dan keyin qayta yuboriş';
  }

  @override
  String tryAgainIn(String time) {
    return '$time dan keyin qayta urining';
  }

  @override
  String get sendCode => 'Kod yuboriş';

  @override
  String get continueButton => 'Davom etiş';

  @override
  String get promoCodeCopied => 'Promokod nusxalandi!';

  @override
  String get promotionDetails => 'Aksiya tafsilotlari';

  @override
  String get promoCode => 'Promokod';

  @override
  String get discount => 'Çegirma';

  @override
  String validUntil(String date) {
    return '$date gaça amal qiladi';
  }

  @override
  String get close => 'Yopiş';

  @override
  String get orderCreatedPaymentPageOpenFailed =>
      'Buyurtma yaratildi, ammo tölov sahifasi oçilmadi.';

  @override
  String get enterPromoCode => 'Promokodni kiriting';

  @override
  String get apply => 'Qöllaş';

  @override
  String get couldNotCalculateTotal => 'Jami summani hisoblab bölmadi';

  @override
  String get createOrderTitle => 'Buyurtma beriş';

  @override
  String get orderType => 'Buyurtma turi';

  @override
  String get orderItems => 'Buyurtma mahsulotlari';

  @override
  String get cancel => 'Bekor qiliş';

  @override
  String get createOrderAction => 'Buyurtma beriş';

  @override
  String createOrderFor(String price) {
    return 'Buyurtma beriş · $price';
  }

  @override
  String get change => 'Özgartiriş';

  @override
  String get payment => 'Tölov';

  @override
  String get onlinePayment => 'Onlayn tölov';

  @override
  String get payOnReceipt => 'Qabul qilganda tölaş';

  @override
  String get calculatingTotal => 'Jami hisoblanmoqda';

  @override
  String get recalculate => 'Qayta hisoblaş';

  @override
  String get orderPreview => 'Buyurtma hisobi';

  @override
  String get viewOrderDetails => 'Buyurtma tafsilotlarini köriş';

  @override
  String get deliveryBranch => 'Yetkazib beruvçi filial';

  @override
  String get deliveryDestination => 'Yetkazib beriş manzili';

  @override
  String get deliveryDistance => 'Yetkazib beriş masofasi';

  @override
  String distanceMeters(String distance) {
    return '$distance m';
  }

  @override
  String distanceKilometers(String distance) {
    return '$distance km';
  }

  @override
  String get roadRoute => 'Yöl böyiça marşrut';

  @override
  String get estimatedRoute => 'Taxminiy marşrut';

  @override
  String get previewEstimateNotice =>
      'Filial, marşrut, ballar va yakuniy summa buyurtma yaratilganda tasdiqlanadi.';

  @override
  String get items => 'Mahsulotlar';

  @override
  String get modifiers => 'Qöşimçalar';

  @override
  String get serviceFee => 'Xizmat haqi';

  @override
  String get pickupBranch => 'Olib ketiş filiali';

  @override
  String get clientAddress => 'Mijoz manzili';

  @override
  String get branchId => 'Filial ID';

  @override
  String get addressId => 'Manzil ID';

  @override
  String get paymentCash => 'Naqd';

  @override
  String get paymentCardTerminal => 'Terminal';

  @override
  String get unknown => 'Noma\'lum';

  @override
  String get errorSlowNetwork => 'Internet sekin';

  @override
  String get errorConnectionProblem => 'Ulanişda muammo';

  @override
  String get errorBackend => 'Server xatosi';

  @override
  String get errorAuthorizationExpired => 'Avtorizatsiya muddati tugadi';

  @override
  String get errorGenericTitle => 'Nimadir notöğri ketdi';

  @override
  String get errorGenericBody => 'Birozdan keyin qayta urinib köring.';

  @override
  String get noProductsFound => 'Mahsulot topilmadi';

  @override
  String get findingAddress => 'Manzil aniqlanmoqda...';

  @override
  String get checkingThisLocation => 'Bu joy tekşirilmoqda';

  @override
  String get gettingAddressDetails => 'Manzil ma\'lumotlari olinmoqda';

  @override
  String get allowNotificationsInSettings =>
      'Telefon sozlamalarida bildirişnomalarga ruxsat bering';

  @override
  String get notificationPermissionDenied =>
      'Bildirişnomalarga ruxsat berilmadi';

  @override
  String get notificationUpdateFailed =>
      'Bildirişnoma sozlamalarini yangilab bölmadi';

  @override
  String get pushReminderTitle => 'Bildirişnomalarni yoqing';

  @override
  String get pushReminderBody =>
      'Buyurtmangiz qabul qilinganda, tayyor bölganda va yölga çiqqanda xabar beramiz, şaxsiy promokodlar va ballar haqida eslatib turamiz.';

  @override
  String get pushReminderSettingsHint =>
      'Bildirişnomalar telefon sozlamalarida öçirilgan. Sozlamalarni oçing, «Bildirişnomalar» bölimiga öting va ruxsat bering.';

  @override
  String get pushReminderAllow => 'Ruxsat beriş';

  @override
  String get pushReminderOpenSettings => 'Sozlamalarni oçiş';

  @override
  String get pushReminderLater => 'Hozir emas';

  @override
  String get notifications => 'Bildirişnomalar';

  @override
  String get notificationInbox => 'Xabarlar';

  @override
  String get notificationInboxSubtitle => 'Yangiliklar va takliflar bir joyda';

  @override
  String get filterOrders => 'Buyurtmalar';

  @override
  String get filterPromotions => 'Aksiyalar';

  @override
  String get noNotificationsForFilter => 'Bu filtrga mos bildirişnoma yöq.';

  @override
  String get markAllRead => 'Barçasini öqilgan qiliş';

  @override
  String get markUnread => 'Öqilmagan qiliş';

  @override
  String get noNotifications => 'Hozirça xabarlar yöq';

  @override
  String get noNotificationsSubtitle =>
      'Buyurtma yangiliklari va şaxsiy takliflar şu yerda körinadi.';

  @override
  String get myPromotions => 'Mening promokodlarim';

  @override
  String get myPromotionsSubtitle =>
      'Siz uçun ajratilgan maxsus promokodlardan foydalaning.';

  @override
  String get personalOffers => 'Siz uçun takliflar';

  @override
  String get activePromotions => 'Faol';

  @override
  String get allPromotions => 'Barçasi';

  @override
  String get noAssignedPromotions => 'Faol promokod yöq';

  @override
  String get noAssignedPromotionsSubtitle =>
      'Yangi şaxsiy taklif berilganda bu yerda paydo böladi.';

  @override
  String get reward => 'Foyda';

  @override
  String get conditions => 'Şartlar';

  @override
  String get validity => 'Amal qiliş muddati';

  @override
  String get usage => 'Foydalaniş';

  @override
  String remainingUses(int count) {
    return '$count marta foydalaniş mumkin';
  }

  @override
  String validFrom(String date) {
    return '$date dan amal qiladi';
  }

  @override
  String get usePromo => 'Buyurtmada işlatiş';

  @override
  String promoReadyForCheckout(String code) {
    return '$code promokodi buyurtma uçun tanlandi';
  }

  @override
  String get promoStatusActive => 'Faol';

  @override
  String get promoStatusNotStarted => 'Tez orada';

  @override
  String get promoStatusUsed => 'Işlatilgan';

  @override
  String get promoStatusExpired => 'Muddati tugagan';

  @override
  String get promoStatusRevoked => 'Bekor qilingan';

  @override
  String get promoStatusInactive => 'Faol emas';

  @override
  String get promoStatusLimitReached => 'Limit tugagan';

  @override
  String get marketingOffers => 'Aksiya va takliflar';

  @override
  String get marketingOffersSubtitle =>
      'Sizga mos promokod va çegirmalar haqida xabar oling';

  @override
  String get appearance => 'Köriniş';

  @override
  String get chooseAppColorMode => 'Ilova rang rejimini tanlang';

  @override
  String get language => 'Til';

  @override
  String get actions => 'Amallar';

  @override
  String get deleteAccount => 'Hisobni öçiriş';

  @override
  String get accountDeleted => 'Hisobingiz öçirildi';

  @override
  String get deleteAccountFailed =>
      'Hisobni öçirib bölmadi. Qayta urinib köring.';

  @override
  String get deleteAccountQuestion => 'Hisob öçirilsinmi?';

  @override
  String get deleteAccountPermanentWarning =>
      'Bu amalni ortga qaytarib bölmaydi';

  @override
  String get deleteAccountItemsTitle => 'Quyidagilar öçiriladi:';

  @override
  String get deleteAccountProfilePhone => 'Profil va telefon raqami';

  @override
  String get deleteAccountSavedAddresses =>
      'Saqlangan yetkazib beriş manzillari';

  @override
  String get deleteAccountBonusPoints => 'Töplangan bonus ballari';

  @override
  String get deleteAccountAcknowledgement =>
      'Ma\'lumotlarim butunlay öçirilişini tuşunaman';

  @override
  String get deleting => 'Öçirilmoqda...';

  @override
  String get deleteMyAccount => 'Hisobimni öçiriş';

  @override
  String get allOrders => 'Barça buyurtmalar';

  @override
  String get ordersSearchHint => 'Mahsulot, holat yoki buyurtma raqami';

  @override
  String get all => 'Barçasi';

  @override
  String get anyStatus => 'Har qanday holat';

  @override
  String get noOrdersMatchFilters => 'Filtrlarga mos buyurtma yöq';

  @override
  String get appVersion => 'Ilova versiyasi';

  @override
  String get profilePointsLabel => 'BALLARIM';

  @override
  String get viewPoints => 'Köriş';

  @override
  String get profileOrdersSection => 'BUYURTMALAR';

  @override
  String profileOrderCount(int count) {
    return '$count ta';
  }

  @override
  String get myAddresses => 'Mening manzillarim';

  @override
  String profileAddressCount(int count) {
    return '$count ta';
  }

  @override
  String get editProfile => 'Profilni tahrirlaş';

  @override
  String get profileName => 'Ism';

  @override
  String get profileUpdated => 'Profil yangilandi';

  @override
  String get profileUpdateFailed => 'Profilni yangilab bölmadi';

  @override
  String get savedAddresses => 'Saqlangan manzillar';

  @override
  String get noSavedAddresses => 'Saqlangan manzil yöq';

  @override
  String get noSavedAddressesSubtitle =>
      'Buyurtmani tezroq rasmiylaştiriş uçun manzil qöşing.';

  @override
  String get addAddress => 'Manzil qöşiş';

  @override
  String get addressLabel => 'Manzil nomi';

  @override
  String get addressLabelHint => 'Masalan, Uy';

  @override
  String get setAsDefault => 'Asosiy qiliş';

  @override
  String get defaultAddress => 'Asosiy';

  @override
  String get addressSaved => 'Manzil saqlandi';

  @override
  String get addressSaveFailed => 'Manzilni saqlab bölmadi';

  @override
  String get addressDeleted => 'Manzil öçirildi';

  @override
  String get addressDeleteFailed => 'Manzilni öçirib bölmadi';

  @override
  String get deleteAddress => 'Manzilni öçiriş';

  @override
  String get profileNotificationsSubtitle => 'Buyurtma holati va takliflar';

  @override
  String get orderStatusCooking => 'Tayyorlanmoqda';

  @override
  String get orderStatusReady => 'Tayyor';

  @override
  String get orderStatusCourierAssigned => 'Kuryer biriktirildi';

  @override
  String get orderStatusOnTheWay => 'Yölda';

  @override
  String get paymentStatusPending => 'Kutilmoqda';

  @override
  String get paymentStatusPaid => 'Tölangan';

  @override
  String get paymentStatusFailed => 'Tölanmadi';

  @override
  String get paymentStatusRefunded => 'Qaytarilgan';

  @override
  String get product => 'Mahsulot';

  @override
  String get noProductsInOrder => 'Buyurtmada mahsulot yöq';

  @override
  String get paymentLinkUnavailable => 'Tölov havolasi hali mavjud emas.';

  @override
  String get completePaymentOnline => 'Onlayn tölovni yakunlang.';

  @override
  String get paymentPageOpenFailed => 'Tölov sahifasini oçib bölmadi.';

  @override
  String get retryPaymentFailed => 'Tölovni qayta uriniş imkoni bölmadi.';

  @override
  String get orderDetails => 'Buyurtma tafsilotlari';

  @override
  String get currentStatus => 'Joriy holat';

  @override
  String get created => 'Yaratilgan';

  @override
  String get scheduledFor => 'Rejalaştirilgan';

  @override
  String get lastUpdate => 'Oxirgi yangilaniş';

  @override
  String get paymentStatus => 'Tölov holati';

  @override
  String get retryPayment => 'Tölovni qayta uriniş';

  @override
  String get products => 'Mahsulotlar';

  @override
  String get statusHistory => 'Holatlar tarixi';

  @override
  String get additionalInfo => 'Qöşimça ma\'lumot';

  @override
  String get requiredChoice => 'Majburiy';

  @override
  String get optionalChoice => 'Ixtiyoriy';

  @override
  String chooseAtLeastOptions(int count) {
    return 'Kamida $count ta tanlang';
  }

  @override
  String addToCartFor(String price) {
    return 'Qöşiş · $price';
  }

  @override
  String get kitchenOrder => 'Oşxona buyurtmasi';

  @override
  String get loyaltyWallet => 'Mening ballarim';

  @override
  String get spendablePoints => 'Sarflaş uçun mavjud';

  @override
  String get reservedPoints => 'Buyurtmalar uçun band qilingan';

  @override
  String get loyaltyDebt => 'Ballar böyiça qarz';

  @override
  String get loyaltyDebtHint => 'Yangi ballar avval uşbu qarzni qoplaydi.';

  @override
  String get pointsExpiringSoon => '7 kun içida tugaydi';

  @override
  String get nextPointsExpiry => 'Eng yaqin tugaş sanasi';

  @override
  String get loyaltyHistory => 'Ballar tarixi';

  @override
  String get loyaltyHistoryEmpty => 'Ballar bilan amallar şu yerda körinadi.';

  @override
  String get loyaltyProgramUnavailable =>
      'Ballar dasturi vaqtinça mavjud emas.';

  @override
  String get loyaltyRedemptionUnavailable =>
      'Hozir ballarni sarflaş imkoni yöq.';

  @override
  String get loyaltyHowItWorks => 'Ballar qanday işlaydi';

  @override
  String get loyaltyPointValueInfo => '1 ball 1 sömga teng.';

  @override
  String get loyaltyEarningInfo =>
      'Ball miqdori buyurtma yetkazilgandagi faol aksiyaga boğliq.';

  @override
  String get loyaltyValidityInfo =>
      'Olingan ballar körsatilgan muddat davomida amal qiladi.';

  @override
  String get loyaltyFeesDeliveryAllowed =>
      'Yetkazib berişni ballar bilan tölaş mumkin.';

  @override
  String get loyaltyFeesDeliveryNotAllowed =>
      'Yetkazib berişni ballar bilan tölab bölmaydi.';

  @override
  String get loyaltyFeesServiceAllowed =>
      'Xizmat haqini ballar bilan tölaş mumkin.';

  @override
  String get loyaltyFeesServiceNotAllowed =>
      'Xizmat haqini ballar bilan tölab bölmaydi.';

  @override
  String get validForDays => 'Amal qiliş muddati (kun)';

  @override
  String get usePoints => 'Ballar bilan tölaş';

  @override
  String get pointsAvailable => 'Mavjud ballar';

  @override
  String get pointsInputHint => 'Butun ball kiriting';

  @override
  String get useMaximum => 'Maksimumini işlatiş';

  @override
  String get continueWithoutPoints => 'Ballarsiz davom etiş';

  @override
  String get pointsDebtCheckout =>
      'Qarz mavjud paytda ballarni işlatib bölmaydi.';

  @override
  String get fullyPaidWithPoints => 'Töliq ballar bilan tölandi';

  @override
  String get orderBeforePoints => 'Ballargaça buyurtma summasi';

  @override
  String get pointsUsed => 'Işlatilgan ballar';

  @override
  String get amountToPay => 'Tölov summasi';

  @override
  String get estimatedPoints => 'Taxminiy ballar';

  @override
  String get estimatedPointsHint =>
      'Yakuniy miqdor buyurtma yetkazilganda aniqlanadi.';

  @override
  String get loyaltyPending => 'Yetkazilgandan söng hisoblanadi';

  @override
  String get loyaltyEarned => 'Ballar qöşildi';

  @override
  String get loyaltyNoReward => 'Ball berilmadi';

  @override
  String get loyaltyReversed => 'Ball beriş bekor qilindi';

  @override
  String get loyaltyRestored => 'Ballar qaytarildi';

  @override
  String get transactionEarn => 'Ballar olindi';

  @override
  String get transactionSpend => 'Ballar işlatildi';

  @override
  String get transactionRelease => 'Ballar qaytarildi';

  @override
  String get transactionExpiry => 'Ballar muddati tugadi';

  @override
  String get transactionReversal => 'Ball beriş bekor qilindi';

  @override
  String get transactionDebtRepayment => 'Qarz qoplandi';

  @override
  String get transactionOpeningBalance => 'Boşlanğiç balans';

  @override
  String get transactionBalanceUpdate => 'Balans yangilandi';

  @override
  String get retry => 'Qayta uriniş';

  @override
  String get tabHome => 'Boş sahifa';

  @override
  String homeGreeting(String name) {
    return 'Assalomu alaykum, $name.';
  }

  @override
  String get loyaltyMoneyHint => '1 ball 1 sömga teng · 50% gaça';

  @override
  String get repeatOrderTitle => 'Yana takrorlaymizmi?';

  @override
  String repeatOrderAction(String amount) {
    return 'Takrorlaş · $amount';
  }

  @override
  String get save => 'Saqlaş';

  @override
  String get markAllReadShort => 'Barçasini öqiş';

  @override
  String get cartOpen => 'Savatni oçiş';

  @override
  String get changePhoneNumber => 'Raqamni özgartiriş';

  @override
  String caloriesLabel(int value) {
    return '$value kkal';
  }

  @override
  String weightGramsLabel(int value) {
    return '$value g';
  }

  @override
  String cookingMinutesLabel(int value) {
    return '$value daq';
  }

  @override
  String loyaltyBalancePoints(String value) {
    return '$value ball';
  }

  @override
  String get useInOrder => 'Buyurtmada işlatiş';

  @override
  String get promotionGift => 'Sovğa';

  @override
  String get backToHome => 'Boş sahifaga';

  @override
  String get orderingAvailability => 'Buyurtma mavjudligi';

  @override
  String get orderingChecking => 'Filial iş vaqti tekşirilmoqda…';

  @override
  String get orderingOpen => 'Hozir oçiq';

  @override
  String get orderingClosed => 'Hozir mavjud emas';

  @override
  String get pickupAvailability => 'Olib ketiş';

  @override
  String get deliveryAvailability => 'Yetkazib beriş';

  @override
  String orderingNextOpening(String value) {
    return 'Keyingi oçiliş: $value';
  }

  @override
  String get orderingStatusUnavailable =>
      'Iş vaqtini tekşirib bölmadi. Mavjudlik buyurtma paytida tekşiriladi.';

  @override
  String get orderingClosedAction =>
      'Boşqa filialni tanlang yoki keyinroq urinib köring.';

  @override
  String get promoCodeNotFound => 'Promokod topilmadi';

  @override
  String get promoCodeInactive => 'Promokod faol emas';

  @override
  String get promoCodeNotStarted => 'Promokod hali amal qilmaydi';

  @override
  String get promoCodeExpired => 'Promokod muddati tugagan';

  @override
  String get promoGlobalLimitReached => 'Aksiya limiti tugagan';

  @override
  String get promoClientLimitReached =>
      'Bu promokoddan allaqaçon foydalangansiz';

  @override
  String get promoClientRequired =>
      'Promokoddan foydalaniş uçun tizimga kiring';

  @override
  String get promoConditionsNotMet => 'Promokod şartlari bajarilmadi';

  @override
  String get promoConfigurationError => 'Hozir promokodni qöllab bölmaydi';

  @override
  String get promoCodeCouldNotBeApplied => 'Promokodni qöllab bölmadi';

  @override
  String cartQuantityLimitReached(int count) {
    return 'Bitta mahsulotdan köpi bilan $count ta qöşiş mumkin';
  }

  @override
  String cartItemsUnavailable(String items) {
    return 'Endi mavjud emas, savatdan olib taşlandi: $items';
  }

  @override
  String get cartSomeItemsUnavailable =>
      'Ba’zi mahsulotlar endi mavjud emas va savatdan olib taşlandi';

  @override
  String repeatOrderSkipped(String items) {
    return 'Savatga qöşib bölmadi: $items';
  }
}
