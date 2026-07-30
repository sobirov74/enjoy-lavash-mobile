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
  String get delivery => 'Yetkazib berish';

  @override
  String get pickup => 'Olib ketish';

  @override
  String get specialOffer => 'Maxsus taklif';

  @override
  String get specialOfferDesc => 'Hafta oxirigacha lavashga 20% chegirma';

  @override
  String get specialOfferCta => '🔥 Buyurtma bering';

  @override
  String get cartEmpty => 'Savat bo\'sh';

  @override
  String get cartEmptyDesc =>
      'Menyudan taom qo\'shing va bir necha bosishda buyurtma bering.';

  @override
  String get browseMenu => 'Menyuga o\'tish';

  @override
  String get cart => 'Savat';

  @override
  String get total => 'Jami';

  @override
  String get checkout => 'Buyurtma berish';

  @override
  String get viewCart => 'Savatni ochish';

  @override
  String cartItemsCount(int count) {
    return '$count ta mahsulot';
  }

  @override
  String itemRemovedFromCart(String product) {
    return '$product savatdan olib tashlandi';
  }

  @override
  String get undo => 'Qaytarish';

  @override
  String get increaseQuantity => 'Miqdorni oshirish';

  @override
  String get decreaseQuantity => 'Miqdorni kamaytirish';

  @override
  String get menuLoading => 'Menyu tayyorlanmoqda...';

  @override
  String get searchAgain => 'Qidiruvni tozalash';

  @override
  String get orderCreated => 'Buyurtma yaratildi';

  @override
  String get orderSuccessTitle => 'Buyurtmangiz qabul qilindi!';

  @override
  String get orderSuccessMessage =>
      'Buyurtma oshxonaga yuborildi. Holatini profilingizda kuzatib boring.';

  @override
  String orderSuccessNumber(String number) {
    return 'Buyurtma #$number';
  }

  @override
  String get trackOrder => 'Buyurtmani kuzatish';

  @override
  String get orderSuccessPaymentOpening =>
      'Xavfsiz to\'lov sahifasi ochilmoqda…';

  @override
  String get orderSuccessPaymentOpened =>
      'Ochilgan sahifada to\'lovni yakunlang.';

  @override
  String get orderSuccessPayOnReceipt => 'Buyurtmani olganda to\'lov qilasiz.';

  @override
  String get orderSuccessPaymentPaid =>
      'To\'lov qabul qilindi. Hammasi tayyor.';

  @override
  String get orderSuccessPaymentFailed =>
      'To\'lov yakunlanmadi. Keyingi qadamni buyurtma tafsilotlarida ko\'ring.';

  @override
  String get orderSuccessPaymentRefunded => 'Ushbu to\'lov qaytarildi.';

  @override
  String get orderCreateFailed =>
      'Buyurtma yaratib bo\'lmadi. Qayta urinib ko\'ring.';

  @override
  String get selectDeliveryAddressFirst =>
      'Avval yetkazib berish manzilini tanlang';

  @override
  String get selectPickupBranchFirst => 'Avval olib ketish filialini tanlang';

  @override
  String get paymentMethodsUnavailable =>
      'To\'lov usullari vaqtincha mavjud emas. Qayta urinib ko\'ring.';

  @override
  String get profile => 'Profil';

  @override
  String get guest => 'Mehmon';

  @override
  String get lightTheme => 'Yorug\'';

  @override
  String get darkTheme => 'Qorong\'i';

  @override
  String get loyaltyCard => 'Sodiqlik kartasi';

  @override
  String get accumulatedPoints => 'To\'plangan ballar';

  @override
  String get showCodeForPoints =>
      'Ball olish uchun to\'lovda kodni ko\'rsating';

  @override
  String get personalInfo => 'Shaxsiy ma\'lumotlar';

  @override
  String get email => 'Email';

  @override
  String get address => 'Manzil';

  @override
  String get customerId => 'Mijoz ID';

  @override
  String get orderHistory => 'Buyurtmalar tarixi';

  @override
  String get completed => 'Bajarildi';

  @override
  String get cashbackSystem => 'Keshbek tizimi';

  @override
  String get perOrder => 'Har bir buyurtma uchun';

  @override
  String get perOrderValue => '5% ball';

  @override
  String get onePointEquals => '1 ball teng';

  @override
  String get onePointValue => '1 so\'m';

  @override
  String get canSpend => 'Sarflash mumkin';

  @override
  String get canSpendValue => 'Buyurtmaning 50% gacha';

  @override
  String get shareApp => 'Ilovani ulashish';

  @override
  String get shareAppText =>
      'EnjoyLavash ilovasini ko\'ring: https://play.google.com/store/apps/details?id=com.aurumdev.enjoy_lavash_mobile';

  @override
  String get logout => 'Chiqish';

  @override
  String get logoutTitle => 'Akkauntdan chiqasizmi?';

  @override
  String get logoutMessage => 'Saqlangan token ushbu qurilmadan o\'chiriladi.';

  @override
  String get logoutFailed => 'Chiqib bo\'lmadi. Qayta urinib ko\'ring.';

  @override
  String get notFoundTitle => 'Bu sahifa ishlab chiqilmoqda';

  @override
  String get goHome => 'Bosh sahifaga';

  @override
  String get emptyList => 'Ro\'yxat bo\'sh';

  @override
  String get confirm => 'Tasdiqlash';

  @override
  String get yes => 'Ha';

  @override
  String get no => 'Yo\'q';

  @override
  String get save => 'Saqlash';

  @override
  String get skip => 'O\'tkazib yuborish';

  @override
  String get statusCompleted => 'Yakunlangan';

  @override
  String get statusAccepted => 'Qabul qilingan';

  @override
  String get statusCancelled => 'Rad etilgan';

  @override
  String get statusFailed => 'Bekor qilingan';

  @override
  String get statusInProgress => 'Jarayonda';

  @override
  String get statusNew => 'Yangi';

  @override
  String get statusArchive => 'Arxiv';

  @override
  String get statusNeedAccept => 'Tovarni qabul qilish vaqti!';

  @override
  String get tableNumber => '№';

  @override
  String get tableName => 'Nom.';

  @override
  String get tableSent => 'Yub.';

  @override
  String get tableReceived => 'Qab.';

  @override
  String get tableDifference => 'Farq.';

  @override
  String get status => 'Holat:';

  @override
  String get deliveryAddress => 'Yetkazib berish manzili';

  @override
  String get searchAddress => 'Manzilni qidiring...';

  @override
  String get houseNumber => 'Uy raqami';

  @override
  String get houseNumberHint => 'masalan 25A';

  @override
  String get entranceLabel => 'Kirish';

  @override
  String get floorLabel => 'Qavat';

  @override
  String get apartmentLabel => 'Xona';

  @override
  String get commentLabel => 'Izoh';

  @override
  String get commentHint => 'Kuryer uchun ko\'rsatmalar...';

  @override
  String get confirmAddress => 'Manzilni tasdiqlash';

  @override
  String get tapToSelectAddress => 'Manzilni tanlash uchun bosing';

  @override
  String get locationPermissionDenied => 'Joylashuv ruxsati rad etildi';

  @override
  String get enableLocation => 'Joylashuvni yoqish';

  @override
  String get currentLocation => 'Joriy joylashuv';

  @override
  String get selectBranch => 'Filialni tanlang';

  @override
  String get branchWorkingHours => 'Ish vaqti';

  @override
  String get menu => 'Menyu';

  @override
  String get settings => 'Sozlamalar';

  @override
  String get aboutUs => 'Biz haqimizda';

  @override
  String get contactUs => 'Bog\'lanish';

  @override
  String get authorization => 'Avtorizatsiya';

  @override
  String get tapToSignIn => 'Kirish va profilingizni ko\'rish uchun bosing';

  @override
  String get enterPhoneNumber => 'Telefon raqamingizni kiriting';

  @override
  String get enterSmsCode => 'SMS kodni kiriting';

  @override
  String get otpSentMessage =>
      'Telefon raqamingizga tasdiqlash kodi yuborildi.';

  @override
  String get signInToCheckout =>
      'Savatdan buyurtma berish uchun tizimga kiring.';

  @override
  String get phoneNumber => 'Telefon raqami';

  @override
  String get smsCode => 'SMS kod';

  @override
  String get nameOptional => 'Ism (ixtiyoriy)';

  @override
  String get birthDateTitle => 'Sizning maxsus kuningiz 🎂';

  @override
  String get birthDate => 'Tug\'ilgan sana';

  @override
  String get selectBirthDate => 'Tug\'ilgan sanani tanlang';

  @override
  String get birthDateSubtitle =>
      'Bir necha aylantirishda tanlang. Tug\'ilgan kuningiz uchun maxsus sovg\'alar tayyorlaymiz.';

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
  String get otpCodeExpired => 'Tasdiqlash kodining muddati tugadi.';

  @override
  String get resendCode => 'Kodni qayta yuborish';

  @override
  String resendCodeIn(String time) {
    return '$time dan keyin qayta yuborish';
  }

  @override
  String tryAgainIn(String time) {
    return '$time dan keyin qayta urining';
  }

  @override
  String get sendCode => 'Kod yuborish';

  @override
  String get continueButton => 'Davom etish';

  @override
  String get promoCodeCopied => 'Promokod nusxalandi!';

  @override
  String get promotionDetails => 'Aksiya tafsilotlari';

  @override
  String get promoCode => 'Promokod';

  @override
  String get discount => 'Chegirma';

  @override
  String validUntil(String date) {
    return '$date gacha amal qiladi';
  }

  @override
  String get copyCode => 'Kodni nusxalash';

  @override
  String get close => 'Yopish';

  @override
  String get orderCreatedPaymentOnline =>
      'Buyurtma yaratildi. Onlayn to\'lovni yakunlang.';

  @override
  String get orderCreatedPaymentPageOpenFailed =>
      'Buyurtma yaratildi, ammo to\'lov sahifasi ochilmadi.';

  @override
  String get enterPromoCode => 'Promokodni kiriting';

  @override
  String get apply => 'Qo\'llash';

  @override
  String get couldNotCalculateTotal => 'Jami summani hisoblab bo\'lmadi';

  @override
  String get createOrderTitle => 'Buyurtma berish';

  @override
  String get orderType => 'Buyurtma turi';

  @override
  String get orderItems => 'Buyurtma mahsulotlari';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get createOrderAction => 'Buyurtma berish';

  @override
  String get payment => 'To\'lov';

  @override
  String get onlinePayment => 'Onlayn to\'lov';

  @override
  String get payOnReceipt => 'Qabul qilganda to\'lash';

  @override
  String get calculatingTotal => 'Jami hisoblanmoqda';

  @override
  String get recalculate => 'Qayta hisoblash';

  @override
  String get orderPreview => 'Buyurtma hisobi';

  @override
  String get orderDetails => 'Buyurtma tafsilotlari';

  @override
  String get viewOrderDetails => 'Buyurtma tafsilotlarini ko\'rish';

  @override
  String get deliveryBranch => 'Yetkazib beruvchi filial';

  @override
  String get deliveryDestination => 'Yetkazib berish manzili';

  @override
  String get deliveryDistance => 'Yetkazib berish masofasi';

  @override
  String distanceMeters(String distance) {
    return '$distance m';
  }

  @override
  String distanceKilometers(String distance) {
    return '$distance km';
  }

  @override
  String get roadRoute => 'Yo\'l bo\'yicha marshrut';

  @override
  String get estimatedRoute => 'Taxminiy marshrut';

  @override
  String get previewEstimateNotice =>
      'Filial, marshrut, ballar va yakuniy summa buyurtma yaratilganda tasdiqlanadi.';

  @override
  String get items => 'Mahsulotlar';

  @override
  String get modifiers => 'Qo\'shimchalar';

  @override
  String get serviceFee => 'Xizmat haqi';

  @override
  String get pickupBranch => 'Olib ketish filiali';

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
  String get errorConnectionProblem => 'Ulanishda muammo';

  @override
  String get errorBackend => 'Server xatosi';

  @override
  String get errorAuthorizationExpired => 'Avtorizatsiya muddati tugadi';

  @override
  String get errorGenericTitle => 'Nimadir noto\'g\'ri ketdi';

  @override
  String get errorGenericBody => 'Birozdan keyin qayta urinib ko\'ring.';

  @override
  String get retry => 'Qayta urinish';

  @override
  String get searchProducts => 'Mahsulot qidirish';

  @override
  String get clearSearch => 'Qidiruvni tozalash';

  @override
  String searchProductsResultCount(int count) {
    return '$count ta natija';
  }

  @override
  String get noProductsFound => 'Mahsulot topilmadi';

  @override
  String get findingAddress => 'Manzil aniqlanmoqda...';

  @override
  String get checkingThisLocation => 'Bu joy tekshirilmoqda';

  @override
  String get gettingAddressDetails => 'Manzil ma\'lumotlari olinmoqda';

  @override
  String get allowNotificationsInSettings =>
      'Telefon sozlamalarida bildirishnomalarga ruxsat bering';

  @override
  String get notificationPermissionDenied =>
      'Bildirishnomalarga ruxsat berilmadi';

  @override
  String get notificationUpdateFailed =>
      'Bildirishnoma sozlamalarini yangilab bo\'lmadi';

  @override
  String get notifications => 'Bildirishnomalar';

  @override
  String get notificationInbox => 'Xabarlar';

  @override
  String get notificationInboxSubtitle => 'Yangiliklar va takliflar bir joyda';

  @override
  String get markAllRead => 'Barchasini o\'qilgan qilish';

  @override
  String get markUnread => 'O\'qilmagan qilish';

  @override
  String get noNotifications => 'Hozircha xabarlar yo\'q';

  @override
  String get noNotificationsSubtitle =>
      'Buyurtma yangiliklari va shaxsiy takliflar shu yerda ko\'rinadi.';

  @override
  String get myPromotions => 'Mening promokodlarim';

  @override
  String get myPromotionsSubtitle =>
      'Siz uchun ajratilgan maxsus promokodlardan foydalaning.';

  @override
  String get personalOffers => 'Siz uchun takliflar';

  @override
  String get activePromotions => 'Faol';

  @override
  String get allPromotions => 'Barchasi';

  @override
  String activePromoCount(int count) {
    return '$count ta faol';
  }

  @override
  String get noAssignedPromotions => 'Faol promokod yo\'q';

  @override
  String get noAssignedPromotionsSubtitle =>
      'Yangi shaxsiy taklif berilganda bu yerda paydo bo\'ladi.';

  @override
  String get reward => 'Foyda';

  @override
  String get conditions => 'Shartlar';

  @override
  String get validity => 'Amal qilish muddati';

  @override
  String get usage => 'Foydalanish';

  @override
  String remainingUses(int count) {
    return '$count marta foydalanish mumkin';
  }

  @override
  String validFrom(String date) {
    return '$date dan amal qiladi';
  }

  @override
  String get usePromo => 'Buyurtmada ishlatish';

  @override
  String promoReadyForCheckout(String code) {
    return '$code promokodi buyurtma uchun tanlandi';
  }

  @override
  String get promoStatusActive => 'Faol';

  @override
  String get promoStatusNotStarted => 'Tez orada';

  @override
  String get promoStatusUsed => 'Ishlatilgan';

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
      'Sizga mos promokod va chegirmalar haqida xabar oling';

  @override
  String get marketingUpdateFailed =>
      'Aksiya xabarlari sozlamasini yangilab bo\'lmadi';

  @override
  String get appearance => 'Ko\'rinish';

  @override
  String get chooseAppColorMode => 'Ilova rang rejimini tanlang';

  @override
  String get language => 'Til';

  @override
  String get languageSubtitle => 'Ilovadan qulay tilda foydalaning';

  @override
  String get seeAllOrders => 'Barcha buyurtmalar';

  @override
  String get actions => 'Amallar';

  @override
  String get deleteAccount => 'Hisobni o\'chirish';

  @override
  String get accountDeleted => 'Hisobingiz o\'chirildi';

  @override
  String get deleteAccountFailed =>
      'Hisobni o\'chirib bo\'lmadi. Qayta urinib ko\'ring.';

  @override
  String get deleteAccountQuestion => 'Hisob o\'chirilsinmi?';

  @override
  String get deleteAccountPermanentWarning =>
      'Bu amalni ortga qaytarib bo\'lmaydi';

  @override
  String get deleteAccountItemsTitle => 'Quyidagilar o\'chiriladi:';

  @override
  String get deleteAccountProfilePhone => 'Profil va telefon raqami';

  @override
  String get deleteAccountSavedAddresses =>
      'Saqlangan yetkazib berish manzillari';

  @override
  String get deleteAccountBonusPoints => 'To\'plangan bonus ballari';

  @override
  String get deleteAccountAcknowledgement =>
      'Ma\'lumotlarim butunlay o\'chirilishini tushunaman';

  @override
  String get deleting => 'O\'chirilmoqda...';

  @override
  String get deleteMyAccount => 'Hisobimni o\'chirish';

  @override
  String get allOrders => 'Barcha buyurtmalar';

  @override
  String get ordersSearchHint => 'Mahsulot, holat yoki buyurtma raqami';

  @override
  String get all => 'Barchasi';

  @override
  String get anyStatus => 'Har qanday holat';

  @override
  String get noOrdersMatchFilters => 'Filtrlarga mos buyurtma yo\'q';

  @override
  String get appVersion => 'Ilova versiyasi';

  @override
  String get notificationCheckingPermission =>
      'Bildirishnoma ruxsati tekshirilmoqda';

  @override
  String get notificationsUnavailable =>
      'Bu qurilmada bildirishnomalar mavjud emas';

  @override
  String get notificationsEnabled => 'Buyurtma holati va aksiyalar yoqilgan';

  @override
  String get notificationsSubtitleDefault =>
      'Buyurtma holati va maxsus takliflarni oling';

  @override
  String get orderStatusCooking => 'Tayyorlanmoqda';

  @override
  String get orderStatusReady => 'Tayyor';

  @override
  String get orderStatusCourierAssigned => 'Kuryer biriktirildi';

  @override
  String get orderStatusOnTheWay => 'Yo\'lda';

  @override
  String get paymentStatusPending => 'Kutilmoqda';

  @override
  String get paymentStatusPaid => 'To\'langan';

  @override
  String get paymentStatusFailed => 'To\'lanmadi';

  @override
  String get paymentStatusRefunded => 'Qaytarilgan';

  @override
  String get product => 'Mahsulot';

  @override
  String get noProductsInOrder => 'Buyurtmada mahsulot yo\'q';

  @override
  String get paymentLinkUnavailable => 'To\'lov havolasi hali mavjud emas.';

  @override
  String get completePaymentOnline => 'Onlayn to\'lovni yakunlang.';

  @override
  String get paymentPageOpenFailed => 'To\'lov sahifasini ochib bo\'lmadi.';

  @override
  String get retryPaymentFailed => 'To\'lovni qayta urinish imkoni bo\'lmadi.';

  @override
  String get currentStatus => 'Joriy holat';

  @override
  String get created => 'Yaratilgan';

  @override
  String get scheduledFor => 'Rejalashtirilgan';

  @override
  String get lastUpdate => 'Oxirgi yangilanish';

  @override
  String get paymentStatus => 'To\'lov holati';

  @override
  String get retryPayment => 'To\'lovni qayta urinish';

  @override
  String get products => 'Mahsulotlar';

  @override
  String get statusHistory => 'Holatlar tarixi';

  @override
  String get additionalInfo => 'Qo\'shimcha ma\'lumot';

  @override
  String get kitchenOrder => 'Oshxona buyurtmasi';

  @override
  String get loyaltyWallet => 'Mening ballarim';

  @override
  String get spendablePoints => 'Sarflash uchun mavjud';

  @override
  String get reservedPoints => 'Buyurtmalar uchun band qilingan';

  @override
  String get loyaltyDebt => 'Ballar bo\'yicha qarz';

  @override
  String get loyaltyDebtHint => 'Yangi ballar avval ushbu qarzni qoplaydi.';

  @override
  String get pointsExpiringSoon => '7 kun ichida tugaydi';

  @override
  String get nextPointsExpiry => 'Eng yaqin tugash sanasi';

  @override
  String get loyaltyHistory => 'Ballar tarixi';

  @override
  String get loyaltyHistoryEmpty =>
      'Ballar bilan amallar shu yerda ko\'rinadi.';

  @override
  String get loyaltyProgramUnavailable =>
      'Ballar dasturi vaqtincha mavjud emas.';

  @override
  String get loyaltyRedemptionUnavailable =>
      'Hozir ballarni sarflash imkoni yo\'q.';

  @override
  String get loyaltyHowItWorks => 'Ballar qanday ishlaydi';

  @override
  String get loyaltyPointValueInfo => '1 ball 1 so\'mga teng.';

  @override
  String get loyaltyEarningInfo =>
      'Ball miqdori buyurtma yetkazilgandagi faol aksiyaga bog\'liq.';

  @override
  String get loyaltyValidityInfo =>
      'Olingan ballar ko\'rsatilgan muddat davomida amal qiladi.';

  @override
  String get loyaltyFeesDeliveryAllowed =>
      'Yetkazib berishni ballar bilan to\'lash mumkin.';

  @override
  String get loyaltyFeesDeliveryNotAllowed =>
      'Yetkazib berishni ballar bilan to\'lab bo\'lmaydi.';

  @override
  String get loyaltyFeesServiceAllowed =>
      'Xizmat haqini ballar bilan to\'lash mumkin.';

  @override
  String get loyaltyFeesServiceNotAllowed =>
      'Xizmat haqini ballar bilan to\'lab bo\'lmaydi.';

  @override
  String get validForDays => 'Amal qilish muddati (kun)';

  @override
  String get usePoints => 'Ballar bilan to\'lash';

  @override
  String get pointsAvailable => 'Mavjud ballar';

  @override
  String get pointsInputHint => 'Butun ball kiriting';

  @override
  String get useMaximum => 'Maksimumini ishlatish';

  @override
  String get clearPoints => 'Tozalash';

  @override
  String get continueWithoutPoints => 'Ballarsiz davom etish';

  @override
  String get pointsDebtCheckout =>
      'Qarz mavjud paytda ballarni ishlatib bo\'lmaydi.';

  @override
  String get fullyPaidWithPoints => 'To\'liq ballar bilan to\'landi';

  @override
  String get orderBeforePoints => 'Ballargacha buyurtma summasi';

  @override
  String get pointsUsed => 'Ishlatilgan ballar';

  @override
  String get amountToPay => 'To\'lov summasi';

  @override
  String get estimatedPoints => 'Taxminiy ballar';

  @override
  String get estimatedPointsHint =>
      'Yakuniy miqdor buyurtma yetkazilganda aniqlanadi.';

  @override
  String get loyaltyPending => 'Yetkazilgandan so\'ng hisoblanadi';

  @override
  String get loyaltyEarned => 'Ballar qo\'shildi';

  @override
  String get loyaltyNoReward => 'Ball berilmadi';

  @override
  String get loyaltyReversed => 'Ball berish bekor qilindi';

  @override
  String get loyaltyRestored => 'Ballar qaytarildi';

  @override
  String get transactionEarn => 'Ballar olindi';

  @override
  String get transactionSpend => 'Ballar ishlatildi';

  @override
  String get transactionRelease => 'Ballar qaytarildi';

  @override
  String get transactionExpiry => 'Ballar muddati tugadi';

  @override
  String get transactionReversal => 'Ball berish bekor qilindi';

  @override
  String get transactionDebtRepayment => 'Qarz qoplandi';

  @override
  String get transactionOpeningBalance => 'Boshlang\'ich balans';

  @override
  String get transactionBalanceUpdate => 'Balans yangilandi';
}
