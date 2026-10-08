import 'package:enjoy_lavash_mobile/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CountingSecureStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'mobile_client_access_token': 'stored-access',
    });
    storage = _CountingSecureStorage();
    TokenStorage.storage = storage;
  });

  tearDown(TokenStorage.resetStorage);

  test('the access token is read from the keystore once', () async {
    expect(await TokenStorage.getAccessToken(), 'stored-access');
    expect(await TokenStorage.getAccessToken(), 'stored-access');
    expect(await TokenStorage.getAccessToken(), 'stored-access');

    expect(storage.reads, 1);
  });

  test('saving and clearing keep the cached token current', () async {
    await TokenStorage.saveAccessToken('fresh-access');
    expect(await TokenStorage.getAccessToken(), 'fresh-access');

    await TokenStorage.clear();
    expect(await TokenStorage.getAccessToken(), isNull);
    expect(storage.reads, 0);
  });
}

class _CountingSecureStorage extends FlutterSecureStorage {
  int reads = 0;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    reads++;
    return super.read(key: key);
  }
}
