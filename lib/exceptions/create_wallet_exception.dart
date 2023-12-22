import 'package:cw_zano/exceptions/zano_wallet_exception.dart';

class CreateWalletException extends ZanoWalletException {
  final String message;

  CreateWalletException(this.message): super();
  @override
  String toString() => '${this.runtimeType}(message: $message)';
}