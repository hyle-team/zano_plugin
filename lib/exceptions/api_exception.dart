import 'package:cw_zano/exceptions/zano_exception.dart';

class ApiException extends ZanoException {
  final String code;
  final String message;

  ApiException(this.code, this.message);

  @override
  String toString() => '${this.runtimeType}(code: $code, message: $message)';
}
