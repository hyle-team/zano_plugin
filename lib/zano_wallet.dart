import 'package:cw_zano/api/api_calls.dart';
import 'package:cw_zano/exceptions/zano_rpc_exceptions.dart';
import 'package:cw_zano/exceptions/wallet_wrong_id_exception.dart';
import 'package:cw_zano/exceptions/zano_exception.dart';
import 'package:cw_zano/model/create_wallet_result.dart';
import 'package:cw_zano/model/get_address_info_result.dart';
import 'package:cw_zano/model/get_connectivity_status_result.dart';
import 'package:cw_zano/model/get_recent_txs_and_info_params.dart';
import 'package:cw_zano/model/get_recent_txs_and_info_result.dart';
import 'package:cw_zano/model/get_wallet_info_result.dart';
import 'package:cw_zano/model/get_wallet_status_result.dart';
import 'package:cw_zano/model/store_result.dart';
import 'package:cw_zano/model/transfer_params.dart';
import 'package:cw_zano/model/transfer_result.dart';
import 'package:cw_zano/model/wi.dart';
import 'package:cw_zano/model/wi_extended.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:logger/logger.dart';

/// ZanoWallet interface
class ZanoWallet {
  static const defaultHost = '195.201.107.230:33336';
  static const walletWrongId = 'WALLET_WRONG_ID';
  static const unitialized = 'UNINITIALIZED';
  static const statusDelivered = 'delivered';
  static const maxAttempts = 10;
  int hWallet = -1;
  final logger = Logger();

  /// Requesting current API's version
  String getVersion() => ApiCalls.getVersion();

  /// Setting up node. Call before connecting (creating, restoring) to any wallet
  bool setupNode() {
    logger.d('setup_node');
    final isSetupNode = ApiCalls.setupNode(address: defaultHost, login: '', password: '', useSSL: false, isLightWallet: false);
    logger.d('setup_node result $isSetupNode');
    return isSetupNode;
  }

  /// Checking if there a wallet file at provided [path]
  bool isWalletExist({required String path}) {
    logger.d('is_wallet_exist path $path');
    final isExist = ApiCalls.isWalletExist(path: path);
    logger.d('is_wallet_exist result $isExist');
    return isExist;
  }

  /// Creating a new wallet (there shouldn't be an existing wallet at provided [path])
  CreateWalletResult? createWallet({required String path, required String password}) {
    final map = json.decode(ApiCalls.createWallet(path: path, password: password)) as Map<String, dynamic>;
    if (map['result'] != null) {
      logger.d('create_wallet path $path password $password');
      final result = CreateWalletResult.fromJson(map['result'] as Map<String, dynamic>);
      logger.d('create_wallet result $result');
      hWallet = result.walletId;
      return result;
    }
    hWallet = -1;
    return null;
  }

  /// Restore wallet from seed (there shouldn't be an existing wallet at provided [path])
  CreateWalletResult? restoreWalletFromSeed({required String path, required String password, required String seed}) {
    final json = ApiCalls.restoreWalletFromSeed(path: path, password: password, seed: seed);
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (map['result'] != null) {
      logger.i('restore_wallet_from_seed path $path password $password seed $seed');
      final result = CreateWalletResult.fromJson(map['result'] as Map<String, dynamic>);
      logger.i('restore_wallet_from_seed result $result');
      hWallet = result.walletId;
      return result;
    }
    hWallet = -1;
    return null;
  }

  /// Loading existing wallet from [path]
  CreateWalletResult? loadWallet({required String path, required String password}) {
    final map = json.decode(ApiCalls.loadWallet(path: path, password: password)) as Map<String, dynamic>;
    if (map['result'] != null) {
      logger.d('load_wallet path $path password $password');
      final result = CreateWalletResult.fromJson(map['result'] as Map<String, dynamic>);
      logger.d('load_wallet result $result');
      hWallet = result.walletId;
      return result;
    }
    hWallet = -1;
    return null;
  }

  /// Closing a wallet file
  void closeWallet() {
    logger.d('close_wallet hWallet $hWallet');
    ApiCalls.closeWallet(hWallet: hWallet);
  }

  /// Getting a wallet status
  ///
  /// Wallet status [GetWalletStatusResult] contains of:
  /// - current daemon height (int)
  /// - current wallet height (int)
  /// - is daemon connected (bool)
  /// - is in long refresh (bool)
  /// - progress (current progress of refreshing, int)
  /// - wallet state (1-syncing, 2-ready, 3-error)
  GetWalletStatusResult getWalletStatus() {
    logger.d('get_wallet_status hWallet $hWallet');
    final json = ApiCalls.getWalletStatus(hWallet: hWallet);
    logger.d('get_wallet_status result $json');
    if (json == walletWrongId) throw WalletWrongIdException();
    return GetWalletStatusResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Getting a wallet information
  ///
  /// Wallet information ([GetWalletInfoResult]) contains of:
  /// - [Wi] structure (address, balances, path, etc.)
  /// - [WiExtended] structure (seed, private and public keys)
  ///
  /// Note, you can call getWalletInfo ONLY if getWalletStatus returns NOT is in long refresh and wallet state is 2 (ready)
  /// ```
  /// final walletStatusResult = zanoWallet.getWalletStatus();
  /// if (!walletStatusResult!.isInLongRefresh && walletStatusResult!.walletState == 2) {
  ///   walletSyncing = false;
  ///   final walletInfoResult = await zanoWallet.getWalletInfo();
  ///   . . .
  /// } else {
  ///   walletSyncing = true;
  /// }
  /// ```
  Future<GetWalletInfoResult> getWalletInfo() async {
    logger.d('get_wallet_info hWallet $hWallet');
    final json = await compute<int, String>(ApiCalls.getWalletInfo, hWallet);
    logger.d('get_wallet_info result $json');
    if (json == walletWrongId) throw WalletWrongIdException();
    return GetWalletInfoResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Getting current transaction fee for provided priority 
  /// Priority can be 0 (default), 1 (unimportant), 2 (normal), 3 (elevated), 4 (priority)
  int getCurrentTxFee({required int priority}) {
    logger.d('get_current_tx_fee priority $priority');
    final result = ApiCalls.getCurrentTxFee(priority: priority);
    logger.d('get_current_tx_fee result $result');
    return result;
  }

  /// Getting connectivity status with server (online/offline)
  GetConnectivityStatusResult? getConnectivityStatus() {
    final json = ApiCalls.getConnectivityStatus();
    logger.d('get_connectivity_status result $json');
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (map['result'] != null && map['result']['return_code'] == unitialized) return null;
    return GetConnectivityStatusResult.fromJson(map);
  }

  /// Get validity of provided address
  GetAddressInfoResult getAddressInfo({required String address}) {
    logger.d('get_address_info $address');
    final json = ApiCalls.getAddressInfo(address: address);
    logger.d('get_address_info result $json');
    return GetAddressInfoResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Storing wallet file
  Future<StoreResult?> store() async {
    logger.d('store');
    final json = await _invokeMethod(hWallet, 'store', '{}');
    logger.d('store result $json');
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (map['result'] == null || map['result']['result'] == null) return null;
    return StoreResult.fromJson(map['result']['result']);
  }

  /// Making a transfer
  /// 
  /// Parameters of a tranfer ([TransferParams])
  /// - List of [Destination]
  /// - fee (int)
  /// - mixin (10, int)
  /// - paymentId (hex string, can be ommited)
  /// - comment (string, can be ommited)
  /// - push payer (bool)
  /// - hide receiver (bool)
  /// 
  /// Results of a transfer ([TransferParams]): hash (string), size (int)
  Future<TransferResult> transfer(TransferParams params) async {
    final result = await _invokeMethod(hWallet, 'transfer', params);
    Map<String, dynamic> map;
    try {
      map = jsonDecode(result);
    } catch (e) {
      throw ZanoException();
    }
    if (map['result'] == null) throw ZanoException();
    if (map['result']['error'] != null) throw _exceptionFromMapResultError(map['result']['error']);
    if (map['result']['result'] != null) return TransferResult.fromJson(map['result']['result']);
    throw ZanoException();
  }

  /// Getting a list of last N transactions and additional info
  Future<GetRecentTxsAndInfoResult> getRecentTxsAndInfo(GetRecentTxsAndInfoParams params) async {
    final result = await _invokeMethod(hWallet, 'get_recent_txs_and_info', params);
    Map<String, dynamic> map;
    try {
      map = jsonDecode(result);
    } catch (e) {
      throw ZanoException();
    }
    if (map['result'] == null) throw ZanoException();
    if (map['result']['error'] != null) throw _exceptionFromMapResultError(map['result']['error']);
    if (map['result']['result'] != null) return GetRecentTxsAndInfoResult.fromJson(map['result']['result']);
    throw ZanoException();
  }

  Future<String> _invokeMethod(int hWallet, String methodName, Object params) async {
    logger.i('invokeMethod hWallet: $hWallet methodName: $methodName params type: ${params.runtimeType} encoded: ${jsonEncode(params)}');
    var invokeResult = ApiCalls.asyncCall(methodName: 'invoke', hWallet: hWallet, params: '{"method": "$methodName","params": ${jsonEncode(params)}}');
    logger.i('async_call result $invokeResult');
    var map = json.decode(invokeResult) as Map<String, dynamic>;
    int attempts = 0;
    if (map['job_id'] != null) {
      final jobId = map['job_id'] as int;
      do {
        await Future.delayed(Duration(milliseconds: attempts < 2 ? 100 : 500));
        logger.i('tryPullResult jobId: $jobId (${attempts + 1} attempt)');
        final result = ApiCalls.tryPullResult(jobId);
        logger.i('tryPullResult result $result');
        map = jsonDecode(result);
        if (map['status'] != null && map['status'] == statusDelivered && map['result'] != null) {
          return result;
        }
      } while (++attempts < maxAttempts);
    }
    return invokeResult;
  }

  Exception _exceptionFromMapResultError(Map<String, dynamic> map) {
    if (map['code'] != null && map['code'] is int && map['message'] != null && map['message'] is String) {
      return ZanoRpcException.fromCodeAndMessage(map['code'] as int, map['message'] as String);
    } else {
      return ZanoException();
    }
  }
}
