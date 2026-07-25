// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class LRu extends L {
  LRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Enjoy Lavash';

  @override
  String get tabMenu => 'Меню';

  @override
  String get tabCart => 'Корзина';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get delivery => 'Доставка';

  @override
  String get pickup => 'Самовывоз';

  @override
  String get specialOffer => 'Специальное предложение';

  @override
  String get specialOfferDesc => '20% скидка на лаваши до конца недели';

  @override
  String get specialOfferCta => '🔥 Успейте заказать';

  @override
  String get cartEmpty => 'Корзина пуста';

  @override
  String get cartEmptyDesc =>
      'Добавьте блюда из меню и оформите заказ в пару касаний.';

  @override
  String get browseMenu => 'Перейти к меню';

  @override
  String get cart => 'Корзина';

  @override
  String get total => 'Итого';

  @override
  String get checkout => 'Оформить заказ';

  @override
  String get viewCart => 'Открыть корзину';

  @override
  String cartItemsCount(int count) {
    return 'Товаров: $count';
  }

  @override
  String itemRemovedFromCart(String product) {
    return '$product удалён из корзины';
  }

  @override
  String get undo => 'Вернуть';

  @override
  String get increaseQuantity => 'Увеличить количество';

  @override
  String get decreaseQuantity => 'Уменьшить количество';

  @override
  String get menuLoading => 'Готовим меню...';

  @override
  String get searchAgain => 'Очистить поиск';

  @override
  String get orderCreated => 'Заказ создан';

  @override
  String get orderSuccessTitle => 'Заказ принят!';

  @override
  String get orderSuccessMessage =>
      'Заказ уже передан на кухню. Следите за его статусом в профиле.';

  @override
  String orderSuccessNumber(String number) {
    return 'Заказ №$number';
  }

  @override
  String get trackOrder => 'Отслеживать заказ';

  @override
  String get orderSuccessPaymentOpening =>
      'Открываем защищённую страницу оплаты…';

  @override
  String get orderSuccessPaymentOpened =>
      'Завершите оплату на открытой странице.';

  @override
  String get orderSuccessPayOnReceipt => 'Оплатите заказ при получении.';

  @override
  String get orderSuccessPaymentPaid => 'Оплата получена. Всё готово.';

  @override
  String get orderSuccessPaymentFailed =>
      'Оплата не завершена. Следующий шаг указан в деталях заказа.';

  @override
  String get orderSuccessPaymentRefunded => 'Оплата возвращена.';

  @override
  String get orderCreateFailed =>
      'Не удалось создать заказ. Попробуйте еще раз.';

  @override
  String get selectDeliveryAddressFirst => 'Сначала выберите адрес доставки';

  @override
  String get selectPickupBranchFirst =>
      'Сначала выберите филиал для самовывоза';

  @override
  String get paymentMethodsUnavailable =>
      'Способы оплаты временно недоступны. Попробуйте снова.';

  @override
  String get profile => 'Профиль';

  @override
  String get guest => 'Гость';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get loyaltyCard => 'Карта лояльности';

  @override
  String get accumulatedPoints => 'Накопленные баллы';

  @override
  String get showCodeForPoints =>
      'Покажите код при оплате для начисления баллов';

  @override
  String get personalInfo => 'Личные данные';

  @override
  String get email => 'Email';

  @override
  String get address => 'Адрес';

  @override
  String get customerId => 'ID клиента';

  @override
  String get orderHistory => 'История заказов';

  @override
  String get completed => 'Выполнен';

  @override
  String get cashbackSystem => 'Система кэшбэка';

  @override
  String get perOrder => 'За каждый заказ';

  @override
  String get perOrderValue => '5% баллами';

  @override
  String get onePointEquals => '1 балл равен';

  @override
  String get onePointValue => '1 so\'m';

  @override
  String get canSpend => 'Можно потратить';

  @override
  String get canSpendValue => 'До 50% заказа';

  @override
  String get shareApp => 'Поделиться приложением';

  @override
  String get shareAppText =>
      'Попробуйте EnjoyLavash: https://play.google.com/store/apps/details?id=com.aurumdev.enjoy_lavash_mobile';

  @override
  String get logout => 'Выйти';

  @override
  String get logoutTitle => 'Выйти из аккаунта?';

  @override
  String get logoutMessage =>
      'Сохраненный токен будет удален с этого устройства.';

  @override
  String get logoutFailed => 'Не удалось выйти. Попробуйте еще раз.';

  @override
  String get notFoundTitle => 'Эта страница в стадии разработки';

  @override
  String get goHome => 'На главную';

  @override
  String get emptyList => 'Список пуст';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get save => 'Сохранить';

  @override
  String get skip => 'Пропустить';

  @override
  String get statusCompleted => 'Завершенный';

  @override
  String get statusAccepted => 'Принят';

  @override
  String get statusCancelled => 'Отклонен';

  @override
  String get statusFailed => 'Отменен';

  @override
  String get statusInProgress => 'В процессе';

  @override
  String get statusNew => 'Новый';

  @override
  String get statusArchive => 'Архив';

  @override
  String get statusNeedAccept => 'Пора принять товар!';

  @override
  String get tableNumber => '№';

  @override
  String get tableName => 'Наим.';

  @override
  String get tableSent => 'Отпр.';

  @override
  String get tableReceived => 'Получ.';

  @override
  String get tableDifference => 'Разн.';

  @override
  String get status => 'Статус:';

  @override
  String get deliveryAddress => 'Адрес доставки';

  @override
  String get searchAddress => 'Поиск адреса...';

  @override
  String get houseNumber => 'Номер дома';

  @override
  String get houseNumberHint => 'напр. 25А';

  @override
  String get entranceLabel => 'Подъезд';

  @override
  String get floorLabel => 'Этаж';

  @override
  String get apartmentLabel => 'Кв.';

  @override
  String get commentLabel => 'Комментарий';

  @override
  String get commentHint => 'Инструкции для курьера...';

  @override
  String get confirmAddress => 'Подтвердить адрес';

  @override
  String get tapToSelectAddress => 'Нажмите для выбора адреса';

  @override
  String get locationPermissionDenied => 'Доступ к геолокации запрещён';

  @override
  String get enableLocation => 'Включить геолокацию';

  @override
  String get currentLocation => 'Текущее местоположение';

  @override
  String get selectBranch => 'Выберите филиал';

  @override
  String get branchWorkingHours => 'Время работы';

  @override
  String get menu => 'Меню';

  @override
  String get settings => 'Настройки';

  @override
  String get aboutUs => 'О нас';

  @override
  String get contactUs => 'Связаться с нами';

  @override
  String get authorization => 'Авторизация';

  @override
  String get tapToSignIn => 'Нажмите, чтобы войти и посмотреть профиль';

  @override
  String get enterPhoneNumber => 'Введите номер телефона';

  @override
  String get enterSmsCode => 'Введите SMS-код';

  @override
  String get otpSentMessage => 'Мы отправили код подтверждения на ваш номер.';

  @override
  String get signInToCheckout => 'Войдите, чтобы оформить заказ из корзины.';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get smsCode => 'SMS-код';

  @override
  String get nameOptional => 'Имя (необязательно)';

  @override
  String get birthDateTitle => 'Ваш особенный день 🎂';

  @override
  String get birthDate => 'Дата рождения';

  @override
  String get selectBirthDate => 'Выберите дату рождения';

  @override
  String otpCodeExpiresIn(String time) {
    return 'Код действует ещё $time';
  }

  @override
  String get otpCodeExpired => 'Срок действия кода истёк.';

  @override
  String get resendCode => 'Отправить код снова';

  @override
  String resendCodeIn(String time) {
    return 'Повторная отправка через $time';
  }

  @override
  String tryAgainIn(String time) {
    return 'Повторите через $time';
  }

  @override
  String get sendCode => 'Отправить код';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get promoCodeCopied => 'Промокод скопирован!';

  @override
  String get promotionDetails => 'Детали акции';

  @override
  String get promoCode => 'Промокод';

  @override
  String get discount => 'Скидка';

  @override
  String validUntil(String date) {
    return 'Действует до $date';
  }

  @override
  String get copyCode => 'Скопировать код';

  @override
  String get close => 'Закрыть';

  @override
  String get orderCreatedPaymentOnline =>
      'Заказ создан. Завершите онлайн-оплату.';

  @override
  String get orderCreatedPaymentPageOpenFailed =>
      'Заказ создан, но страницу оплаты открыть не удалось.';

  @override
  String get enterPromoCode => 'Введите промокод';

  @override
  String get apply => 'Применить';

  @override
  String get couldNotCalculateTotal => 'Не удалось рассчитать итог';

  @override
  String get createOrderTitle => 'Оформить заказ';

  @override
  String get orderType => 'Тип заказа';

  @override
  String get orderItems => 'Состав заказа';

  @override
  String get cancel => 'Отмена';

  @override
  String get createOrderAction => 'Создать заказ';

  @override
  String get payment => 'Оплата';

  @override
  String get onlinePayment => 'Онлайн-оплата';

  @override
  String get payOnReceipt => 'Оплата при получении';

  @override
  String get calculatingTotal => 'Считаем итог';

  @override
  String get recalculate => 'Пересчитать';

  @override
  String get orderPreview => 'Расчет заказа';

  @override
  String get items => 'Товары';

  @override
  String get modifiers => 'Добавки';

  @override
  String get serviceFee => 'Сервисный сбор';

  @override
  String get pickupBranch => 'Филиал самовывоза';

  @override
  String get clientAddress => 'Адрес клиента';

  @override
  String get branchId => 'ID филиала';

  @override
  String get addressId => 'ID адреса';

  @override
  String get paymentCash => 'Наличные';

  @override
  String get paymentCardTerminal => 'Терминал';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get errorSlowNetwork => 'Медленная сеть';

  @override
  String get errorConnectionProblem => 'Проблема с подключением';

  @override
  String get errorBackend => 'Ошибка сервера';

  @override
  String get errorAuthorizationExpired => 'Авторизация истекла';

  @override
  String get errorGenericTitle => 'Что-то пошло не так';

  @override
  String get errorGenericBody => 'Попробуйте еще раз через несколько секунд.';

  @override
  String get retry => 'Повторить';

  @override
  String get searchProducts => 'Поиск товаров';

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String searchProductsResultCount(int count) {
    return 'Найдено: $count';
  }

  @override
  String get noProductsFound => 'Товары не найдены';

  @override
  String get findingAddress => 'Определяем адрес...';

  @override
  String get checkingThisLocation => 'Проверяем эту точку';

  @override
  String get gettingAddressDetails => 'Получаем данные адреса';

  @override
  String get allowNotificationsInSettings =>
      'Разрешите уведомления в настройках телефона';

  @override
  String get notificationPermissionDenied =>
      'Разрешение на уведомления не выдано';

  @override
  String get notificationUpdateFailed =>
      'Не удалось обновить настройки уведомлений';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationInbox => 'Входящие';

  @override
  String get notificationInboxSubtitle => 'Новости и предложения в одном месте';

  @override
  String get markAllRead => 'Прочитать все';

  @override
  String get markUnread => 'Отметить непрочитанным';

  @override
  String get noNotifications => 'Уведомлений пока нет';

  @override
  String get noNotificationsSubtitle =>
      'Здесь появятся новости о заказах и персональные предложения.';

  @override
  String get myPromotions => 'Мои промокоды';

  @override
  String get myPromotionsSubtitle =>
      'Используйте специальные промокоды, назначенные именно вам.';

  @override
  String get personalOffers => 'Предложения для вас';

  @override
  String get activePromotions => 'Активные';

  @override
  String get allPromotions => 'Все';

  @override
  String activePromoCount(int count) {
    return 'Активных: $count';
  }

  @override
  String get noAssignedPromotions => 'Нет активных промокодов';

  @override
  String get noAssignedPromotionsSubtitle =>
      'Новое персональное предложение появится здесь автоматически.';

  @override
  String get reward => 'Выгода';

  @override
  String get conditions => 'Условия';

  @override
  String get validity => 'Срок действия';

  @override
  String get usage => 'Использование';

  @override
  String remainingUses(int count) {
    return 'Осталось применений: $count';
  }

  @override
  String validFrom(String date) {
    return 'Действует с $date';
  }

  @override
  String get usePromo => 'Использовать в заказе';

  @override
  String promoReadyForCheckout(String code) {
    return 'Промокод $code выбран для заказа';
  }

  @override
  String get promoStatusActive => 'Активен';

  @override
  String get promoStatusNotStarted => 'Скоро';

  @override
  String get promoStatusUsed => 'Использован';

  @override
  String get promoStatusExpired => 'Истёк';

  @override
  String get promoStatusRevoked => 'Отозван';

  @override
  String get promoStatusInactive => 'Неактивен';

  @override
  String get promoStatusLimitReached => 'Лимит исчерпан';

  @override
  String get marketingOffers => 'Акции и предложения';

  @override
  String get marketingOffersSubtitle =>
      'Получайте подходящие промокоды и новости о скидках';

  @override
  String get marketingUpdateFailed =>
      'Не удалось обновить настройку рекламных уведомлений';

  @override
  String get appearance => 'Оформление';

  @override
  String get chooseAppColorMode => 'Выберите цветовой режим приложения';

  @override
  String get language => 'Язык';

  @override
  String get languageSubtitle => 'Используйте приложение на удобном языке';

  @override
  String get seeAllOrders => 'Все заказы';

  @override
  String get actions => 'Действия';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get accountDeleted => 'Ваш аккаунт удалён';

  @override
  String get deleteAccountFailed =>
      'Не удалось удалить аккаунт. Попробуйте ещё раз.';

  @override
  String get deleteAccountQuestion => 'Удалить аккаунт?';

  @override
  String get deleteAccountPermanentWarning =>
      'Это действие необратимо — восстановить данные не получится';

  @override
  String get deleteAccountItemsTitle => 'Будут удалены:';

  @override
  String get deleteAccountProfilePhone => 'Профиль и номер телефона';

  @override
  String get deleteAccountSavedAddresses => 'Сохранённые адреса доставки';

  @override
  String get deleteAccountBonusPoints => 'Накопленные бонусные баллы';

  @override
  String get deleteAccountAcknowledgement =>
      'Я понимаю, что мои данные будут удалены безвозвратно';

  @override
  String get deleting => 'Удаляем...';

  @override
  String get deleteMyAccount => 'Удалить мой аккаунт';

  @override
  String get allOrders => 'Все заказы';

  @override
  String get ordersSearchHint => 'Поиск по товару, статусу или номеру';

  @override
  String get all => 'Все';

  @override
  String get anyStatus => 'Любой статус';

  @override
  String get noOrdersMatchFilters => 'Нет заказов по выбранным фильтрам';

  @override
  String get appVersion => 'Версия приложения';

  @override
  String get notificationCheckingPermission =>
      'Проверяем доступ к уведомлениям';

  @override
  String get notificationsUnavailable =>
      'Уведомления недоступны на этом устройстве';

  @override
  String get notificationsEnabled => 'Статусы заказов и акции включены';

  @override
  String get notificationsSubtitleDefault =>
      'Получайте статусы заказов и специальные предложения';

  @override
  String get orderStatusCooking => 'Готовится';

  @override
  String get orderStatusReady => 'Готов';

  @override
  String get orderStatusCourierAssigned => 'Курьер назначен';

  @override
  String get orderStatusOnTheWay => 'В пути';

  @override
  String get paymentStatusPending => 'Ожидает оплаты';

  @override
  String get paymentStatusPaid => 'Оплачено';

  @override
  String get paymentStatusFailed => 'Не оплачено';

  @override
  String get paymentStatusRefunded => 'Возвращено';

  @override
  String get product => 'Товар';

  @override
  String get noProductsInOrder => 'В заказе нет товаров';

  @override
  String get paymentLinkUnavailable => 'Ссылка на оплату пока недоступна.';

  @override
  String get completePaymentOnline => 'Завершите онлайн-оплату.';

  @override
  String get paymentPageOpenFailed => 'Не удалось открыть страницу оплаты.';

  @override
  String get retryPaymentFailed => 'Не удалось повторить оплату.';

  @override
  String get orderDetails => 'Детали заказа';

  @override
  String get currentStatus => 'Текущий статус';

  @override
  String get created => 'Создан';

  @override
  String get scheduledFor => 'Запланирован';

  @override
  String get lastUpdate => 'Последнее обновление';

  @override
  String get paymentStatus => 'Статус оплаты';

  @override
  String get retryPayment => 'Повторить оплату';

  @override
  String get products => 'Товары';

  @override
  String get statusHistory => 'История статусов';

  @override
  String get additionalInfo => 'Дополнительно';

  @override
  String get kitchenOrder => 'Заказ кухни';

  @override
  String get loyaltyWallet => 'Мои баллы';

  @override
  String get spendablePoints => 'Доступно для оплаты';

  @override
  String get reservedPoints => 'Зарезервировано в заказах';

  @override
  String get loyaltyDebt => 'Задолженность по баллам';

  @override
  String get loyaltyDebtHint => 'Новые баллы сначала погасят эту сумму.';

  @override
  String get pointsExpiringSoon => 'Сгорят в течение 7 дней';

  @override
  String get nextPointsExpiry => 'Ближайшее сгорание';

  @override
  String get loyaltyHistory => 'История баллов';

  @override
  String get loyaltyHistoryEmpty => 'Здесь появятся операции с баллами.';

  @override
  String get loyaltyProgramUnavailable =>
      'Программа баллов временно недоступна.';

  @override
  String get loyaltyRedemptionUnavailable =>
      'Списание баллов сейчас недоступно.';

  @override
  String get loyaltyHowItWorks => 'Как работают баллы';

  @override
  String get loyaltyPointValueInfo => '1 балл равен 1 суму.';

  @override
  String get loyaltyEarningInfo =>
      'Начисление зависит от акции, действующей при доставке заказа.';

  @override
  String get loyaltyValidityInfo =>
      'Начисленные баллы действуют в течение указанного срока.';

  @override
  String get loyaltyFeesDeliveryAllowed => 'Баллами можно оплатить доставку.';

  @override
  String get loyaltyFeesDeliveryNotAllowed =>
      'Баллами нельзя оплатить доставку.';

  @override
  String get loyaltyFeesServiceAllowed =>
      'Баллами можно оплатить сервисный сбор.';

  @override
  String get loyaltyFeesServiceNotAllowed =>
      'Баллами нельзя оплатить сервисный сбор.';

  @override
  String get validForDays => 'Срок действия (дни)';

  @override
  String get usePoints => 'Оплатить баллами';

  @override
  String get pointsAvailable => 'Доступные баллы';

  @override
  String get pointsInputHint => 'Введите целое число';

  @override
  String get useMaximum => 'Использовать максимум';

  @override
  String get clearPoints => 'Очистить';

  @override
  String get continueWithoutPoints => 'Продолжить без баллов';

  @override
  String get pointsDebtCheckout => 'Баллы недоступны, пока есть задолженность.';

  @override
  String get fullyPaidWithPoints => 'Полностью оплачено баллами';

  @override
  String get orderBeforePoints => 'Сумма до списания баллов';

  @override
  String get pointsUsed => 'Списано баллов';

  @override
  String get amountToPay => 'К оплате';

  @override
  String get estimatedPoints => 'Ожидаемые баллы';

  @override
  String get estimatedPointsHint => 'Итог определится после доставки.';

  @override
  String get loyaltyPending => 'Рассчитаем после доставки';

  @override
  String get loyaltyEarned => 'Баллы начислены';

  @override
  String get loyaltyNoReward => 'Баллы не начислены';

  @override
  String get loyaltyReversed => 'Начисление отменено';

  @override
  String get loyaltyRestored => 'Баллы возвращены';

  @override
  String get transactionEarn => 'Баллы начислены';

  @override
  String get transactionSpend => 'Баллы списаны';

  @override
  String get transactionRelease => 'Баллы возвращены';

  @override
  String get transactionExpiry => 'Баллы сгорели';

  @override
  String get transactionReversal => 'Начисление отменено';

  @override
  String get transactionDebtRepayment => 'Долг погашен';

  @override
  String get transactionOpeningBalance => 'Начальный баланс';

  @override
  String get transactionBalanceUpdate => 'Изменение баланса';
}
