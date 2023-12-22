import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class Utils {
  static const String _prefix = 'zano';
  static const ivEncodedStringLength = 12;

  static Future<String> pathForWalletDir({required String name}) async {
    final root = await getApplicationDocumentsDirectory();
    final walletsDir = Directory('${root.path}/wallets');
    final walletDire = Directory('${walletsDir.path}/$_prefix/$name');

    if (!walletDire.existsSync()) {
      walletDire.createSync(recursive: true);
    }

    return walletDire.path;
  }

  static Future<String> pathForWallet({required String name}) async => await pathForWalletDir(name: name).then((path) => path + '/$name');

  static Future<String> outdatedAndroidPathForWalletDir({required String name}) async {
    final directory = await getApplicationDocumentsDirectory();
    final pathDir = directory.path + '/$name';

    return pathDir;
  }

  static String generateKey() {
    final key = encrypt.Key.fromSecureRandom(512);
    final iv = encrypt.IV.fromSecureRandom(8);

    return key.base64 + iv.base64;
  }

  static List<String> extractKeys(String key) {
    final _key = key.substring(0, key.length - ivEncodedStringLength);
    final iv = key.substring(key.length - ivEncodedStringLength);

    return [_key, iv];
  }

  static Future<String> encode({required encrypt.Key key, required encrypt.IV iv, required String data}) async {
    final encrypter = encrypt.Encrypter(encrypt.Salsa20(key));
    final encrypted = encrypter.encrypt(data, iv: iv);

    return encrypted.base64;
  }

  static Future<String> decode({required String password, required String data}) async {
    final keys = extractKeys(password);
    final key = encrypt.Key.fromBase64(keys.first);
    final iv = encrypt.IV.fromBase64(keys.last);
    final encrypter = encrypt.Encrypter(encrypt.Salsa20(key));
    final encrypted = encrypter.decrypt64(data, iv: iv);

    return encrypted;
  }
}
