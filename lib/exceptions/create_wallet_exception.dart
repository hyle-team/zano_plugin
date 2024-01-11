import 'package:cw_zano/exceptions/zano_exception.dart';

class CreateWalletException extends ZanoException {
  final String message;

  CreateWalletException(this.message) : super();
  @override
  String toString() => '${this.runtimeType}(message: $message)';
}
