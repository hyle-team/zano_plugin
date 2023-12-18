import 'package:cw_zano/utils/crypto_currency.dart';
import 'package:cw_zano/utils/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'wallet_type.g.dart';

const walletTypes = [
  WalletType.zano,
];

@HiveType(typeId: WALLET_TYPE_TYPE_ID)
enum WalletType {
  @HiveField(6)
  zano,
}

int serializeToInt(WalletType type) {
  switch (type) {
    case WalletType.zano:
      return 5;
    default:
      return -1;
  }
}

WalletType deserializeFromInt(int raw) {
  switch (raw) {
    case 5:
      return WalletType.zano;
    default:
      throw Exception(
          'Unexpected token: $raw for WalletType deserializeFromInt');
  }
}

String walletTypeToString(WalletType type) {
  switch (type) {
    case WalletType.zano:
      return 'Zano';
    default:
      return '';
  }
}

String walletTypeToDisplayName(WalletType type) {
  switch (type) {
    case WalletType.zano:
      return 'Zano (ZANO)';
    default:
      return '';
  }
}

CryptoCurrency walletTypeToCryptoCurrency(WalletType type) {
  switch (type) {
    case WalletType.zano:
      return CryptoCurrency.zano;
    default:
      throw Exception(
          'Unexpected wallet type: ${type.toString()} for CryptoCurrency walletTypeToCryptoCurrency');
  }
}
