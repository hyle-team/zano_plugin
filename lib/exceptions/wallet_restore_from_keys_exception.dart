import 'package:cw_zano/exceptions/zano_wallet_exception.dart';

class WalletRestoreFromKeysException implements ZanoWalletException {
  WalletRestoreFromKeysException({required this.message});
  
  final String message;
}