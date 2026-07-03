const String _fallbackLanguage = 'uz';

const Map<String, Map<String, String>> _errorMessages = {
  'en': {
    'AUTH_HEADER_REQUIRED': 'Authentication is required',
    'BEARER_TOKEN_REQUIRED': 'Authentication is required',
    'INVALID_ACCESS_TOKEN': 'Authentication is required',
    'ACCESS_TOKEN_EXPIRED': 'Session expired. Please sign in again.',
    'INVALID_REFRESH_TOKEN': 'Session expired. Please sign in again.',
    'INVALID_OTP': 'Invalid or expired OTP code',
    'OTP_RATE_LIMITED': 'Too many OTP requests. Please try again later.',
    'OTP_SEND_FAILED': 'Could not send OTP code. Please try again.',
    'CLIENT_BLOCKED': 'Client is blocked',
    'INVALID_CLIENT_TOKEN': 'Authentication is required',
    'PHONE_REQUIRED': 'Phone number is required',
    'PHONE_MUST_BE_STRING': 'Phone number is invalid',
    'PHONE_INVALID_UZ': 'Phone number must be a valid Uzbekistan phone number',
    'FULL_NAME_REQUIRED': 'Full name is required',
    'CLIENT_PHONE_EXISTS': 'A client with this phone number already exists',
    'CLIENT_NOT_FOUND': 'Client was not found',
    'ADDRESS_NOT_FOUND': 'Address was not found',
    'ORDER_NOT_FOUND': 'Order was not found',
    'PRODUCT_NOT_FOUND': 'Product was not found',
    'BRANCH_NOT_FOUND': 'Branch was not found',
    'PAYMENT_METHOD_NOT_FOUND': 'Payment method was not found',
    'PERMISSION_DENIED': 'You do not have permission',
    'VALIDATION_FAILED': 'Validation failed',
    'BAD_REQUEST': 'Invalid request',
    'UNAUTHORIZED': 'Authentication is required',
    'FORBIDDEN': 'You do not have permission',
    'NOT_FOUND': 'Not found',
    'INTERNAL_SERVER_ERROR': 'Internal server error',
  },
  'ru': {
    'AUTH_HEADER_REQUIRED': 'Требуется авторизация',
    'BEARER_TOKEN_REQUIRED': 'Требуется авторизация',
    'INVALID_ACCESS_TOKEN': 'Требуется авторизация',
    'ACCESS_TOKEN_EXPIRED': 'Сессия истекла. Войдите снова.',
    'INVALID_REFRESH_TOKEN': 'Сессия истекла. Войдите снова.',
    'INVALID_OTP': 'Неверный или просроченный OTP код',
    'OTP_RATE_LIMITED': 'Слишком много запросов OTP. Попробуйте позже.',
    'OTP_SEND_FAILED': 'Не удалось отправить OTP код. Попробуйте еще раз.',
    'CLIENT_BLOCKED': 'Клиент заблокирован',
    'INVALID_CLIENT_TOKEN': 'Требуется авторизация',
    'PHONE_REQUIRED': 'Номер телефона обязателен',
    'PHONE_MUST_BE_STRING': 'Некорректный номер телефона',
    'PHONE_INVALID_UZ':
        'Номер телефона должен быть действительным номером Узбекистана',
    'FULL_NAME_REQUIRED': 'Полное имя обязательно',
    'CLIENT_PHONE_EXISTS': 'Клиент с этим номером телефона уже существует',
    'CLIENT_NOT_FOUND': 'Клиент не найден',
    'ADDRESS_NOT_FOUND': 'Адрес не найден',
    'ORDER_NOT_FOUND': 'Заказ не найден',
    'PRODUCT_NOT_FOUND': 'Продукт не найден',
    'BRANCH_NOT_FOUND': 'Филиал не найден',
    'PAYMENT_METHOD_NOT_FOUND': 'Способ оплаты не найден',
    'PERMISSION_DENIED': 'У вас нет доступа',
    'VALIDATION_FAILED': 'Ошибка валидации',
    'BAD_REQUEST': 'Некорректный запрос',
    'UNAUTHORIZED': 'Требуется авторизация',
    'FORBIDDEN': 'У вас нет доступа',
    'NOT_FOUND': 'Не найдено',
    'INTERNAL_SERVER_ERROR': 'Внутренняя ошибка сервера',
  },
  'uz': {
    'AUTH_HEADER_REQUIRED': 'Avtorizatsiya talab qilinadi',
    'BEARER_TOKEN_REQUIRED': 'Avtorizatsiya talab qilinadi',
    'INVALID_ACCESS_TOKEN': 'Avtorizatsiya talab qilinadi',
    'ACCESS_TOKEN_EXPIRED': 'Sessiya muddati tugadi. Qayta kiring.',
    'INVALID_REFRESH_TOKEN': 'Sessiya muddati tugadi. Qayta kiring.',
    'INVALID_OTP': "OTP kodi noto'g'ri yoki muddati tugagan",
    'OTP_RATE_LIMITED': "OTP so'rovlari juda ko'p. Keyinroq urinib ko'ring.",
    'OTP_SEND_FAILED': "OTP kodini yuborib bo'lmadi. Qayta urinib ko'ring.",
    'CLIENT_BLOCKED': 'Mijoz bloklangan',
    'INVALID_CLIENT_TOKEN': 'Avtorizatsiya talab qilinadi',
    'PHONE_REQUIRED': 'Telefon raqami talab qilinadi',
    'PHONE_MUST_BE_STRING': "Telefon raqami noto'g'ri",
    'PHONE_INVALID_UZ': "Telefon raqami O'zbekiston raqami bo'lishi kerak",
    'FULL_NAME_REQUIRED': "To'liq ism talab qilinadi",
    'CLIENT_PHONE_EXISTS': 'Bu telefon raqami bilan mijoz allaqachon mavjud',
    'CLIENT_NOT_FOUND': 'Mijoz topilmadi',
    'ADDRESS_NOT_FOUND': 'Manzil topilmadi',
    'ORDER_NOT_FOUND': 'Buyurtma topilmadi',
    'PRODUCT_NOT_FOUND': 'Mahsulot topilmadi',
    'BRANCH_NOT_FOUND': 'Filial topilmadi',
    'PAYMENT_METHOD_NOT_FOUND': "To'lov usuli topilmadi",
    'PERMISSION_DENIED': "Sizda ruxsat yo'q",
    'VALIDATION_FAILED': 'Validatsiya xatosi',
    'BAD_REQUEST': "So'rov noto'g'ri",
    'UNAUTHORIZED': 'Avtorizatsiya talab qilinadi',
    'FORBIDDEN': "Sizda ruxsat yo'q",
    'NOT_FOUND': 'Topilmadi',
    'INTERNAL_SERVER_ERROR': 'Server ichki xatosi',
  },
};

String resolveApiErrorMessage({
  required Object? data,
  required int statusCode,
  required String? languageCode,
}) {
  final language = _normalizeLanguage(languageCode);
  final body = _asMap(data);
  final errorCode = _stringValue(body?['errorCode'] ?? body?['error_code']);
  final translated = _translatedMessage(language, errorCode);
  if (translated != null) return translated;

  final serverMessage = _extractServerMessage(data);
  if (serverMessage != null && serverMessage.isNotEmpty) {
    return serverMessage;
  }

  return _defaultMessageForStatus(language, statusCode);
}

String _normalizeLanguage(String? languageCode) {
  final normalized = languageCode?.toLowerCase().split(RegExp('[-_]')).first;
  if (_errorMessages.containsKey(normalized)) return normalized!;
  return _fallbackLanguage;
}

String? _translatedMessage(String language, String? errorCode) {
  if (errorCode == null || errorCode.isEmpty) return null;
  return _errorMessages[language]?[errorCode] ??
      _errorMessages[_fallbackLanguage]?[errorCode] ??
      _errorMessages['en']?[errorCode];
}

String _defaultMessageForStatus(String language, int statusCode) {
  if (statusCode == 401) {
    return _translatedMessage(language, 'UNAUTHORIZED')!;
  }
  if (statusCode == 403) {
    return _translatedMessage(language, 'FORBIDDEN')!;
  }
  if (statusCode == 404) {
    return _translatedMessage(language, 'NOT_FOUND')!;
  }
  if (statusCode >= 500) {
    return _translatedMessage(language, 'INTERNAL_SERVER_ERROR')!;
  }
  if (statusCode >= 400) {
    return _translatedMessage(language, 'BAD_REQUEST')!;
  }
  return _translatedMessage(language, 'INTERNAL_SERVER_ERROR')!;
}

Map<Object?, Object?>? _asMap(Object? data) {
  if (data is Map<Object?, Object?>) return data;
  return null;
}

String? _extractServerMessage(Object? data) {
  if (data is Map<Object?, Object?>) {
    return _stringValue(data['message']) ??
        _stringValue(data['error']) ??
        _stringValue(data['detail']);
  }
  return _stringValue(data);
}

String? _stringValue(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Iterable) {
    return value.map(_stringValue).whereType<String>().join('\n');
  }
  return value.toString();
}
