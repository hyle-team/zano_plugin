import 'package:cw_zano/exceptions/zano_exception.dart';

class WalletRestoreFromKeysException implements ZanoException {
  WalletRestoreFromKeysException({required this.message});

  final String message;
}
