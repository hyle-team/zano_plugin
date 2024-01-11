// #define WALLET_RPC_ERROR_CODE_UNKNOWN_ERROR           -1
// #define WALLET_RPC_ERROR_CODE_WRONG_ADDRESS           -2
// #define WALLET_RPC_ERROR_CODE_DAEMON_IS_BUSY          -3
// #define WALLET_RPC_ERROR_CODE_GENERIC_TRANSFER_ERROR  -4
// #define WALLET_RPC_ERROR_CODE_WRONG_PAYMENT_ID        -5
// #define WALLET_RPC_ERROR_CODE_WRONG_ARGUMENT          -6

abstract class ZanoRpcException implements Exception {
  final String message;

  ZanoRpcException(this.message);

  factory ZanoRpcException.fromCodeAndMessage(int code, String message) {
    switch (code) {
      case -1:
        return UnknownErrorException(message);
      case -2:
        return WrongAddressException(message);
      case -3:
        return DaemonIsBusyException(message);
      case -4:
        return GenericTransferErrorException(message);
      case -5:
        return WrongPaymentId(message);
      case -6:
        return WrongArgument(message);
      default:
        return UnknownErrorException(message);
    }
  }

  @override
  String toString() => '${this.runtimeType} $message';
}

class UnknownErrorException extends ZanoRpcException {
  UnknownErrorException(super.message);
}

class WrongAddressException extends ZanoRpcException {
  WrongAddressException(super.message);
}

class DaemonIsBusyException extends ZanoRpcException {
  DaemonIsBusyException(super.message);
}

class GenericTransferErrorException extends ZanoRpcException {
  GenericTransferErrorException(super.message);
}

class WrongPaymentId extends ZanoRpcException {
  WrongPaymentId(super.message);
}

class WrongArgument extends ZanoRpcException {
  WrongArgument(super.message);
}
