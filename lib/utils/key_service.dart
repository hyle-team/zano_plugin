import 'package:cw_zano/utils/encrypt.dart';
import 'package:cw_zano/utils/secret_store_key.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyService {
  KeyService(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  Future<String> getWalletPassword({required String walletName}) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.zanoWalletPassword, walletName: walletName);
    final encodedPassword = await _secureStorage.read(key: key);
    return decodeWalletPassword(password: encodedPassword!);
  }

  Future<void> saveWalletPassword({required String walletName, required String password}) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.zanoWalletPassword, walletName: walletName);
    final encodedPassword = encodeWalletPassword(password: password);

    await _secureStorage.write(key: key, value: encodedPassword);
  }

  Future<void> deleteWalletPassword({required String walletName}) async {
    final key = generateStoreKeyFor(key: SecretStoreKey.zanoWalletPassword, walletName: walletName);

    await _secureStorage.delete(key: key);
  }
}
