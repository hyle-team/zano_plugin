import 'package:cw_zano/api/api_calls.dart';
import 'package:cw_zano/exceptions/transfer_exception.dart';
import 'package:cw_zano/exceptions/unitialized_exception.dart';
import 'package:cw_zano/exceptions/wallet_wrong_id_exception.dart';
import 'package:cw_zano/exceptions/zano_wallet_exception.dart';
import 'package:cw_zano/model/create_wallet_result.dart';
import 'package:cw_zano/model/get_address_info_result.dart';
import 'package:cw_zano/model/get_connectivity_status_result.dart';
import 'package:cw_zano/model/get_recent_txs_and_info_params.dart';
import 'package:cw_zano/model/get_wallet_info_result.dart';
import 'package:cw_zano/model/get_wallet_status_result.dart';
import 'package:cw_zano/model/history.dart';
import 'package:cw_zano/model/store_result.dart';
import 'package:cw_zano/model/transfer_params.dart';
import 'package:cw_zano/model/transfer_result.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:logger/logger.dart';

class ZanoWallet {
  static const defaultHost = '195.201.107.230:33336';
  static const walletWrongId = 'WALLET_WRONG_ID';
  static const unitialized = 'UNINITIALIZED';
  static const statusDelivered = 'delivered';
  static const maxAttempts = 10;
  int hWallet = -1;
  final logger = Logger();

  Future<String> _invokeMethod(int hWallet, String methodName, String params, {required bool async}) async {
    logger.i('invoke method ${async ? "async" : "sync"} methodName: $methodName params: $params');
    final methodParams = json.encode({
      'method': methodName,
      'params': params,
    });
    if (async) {
      logger.i('async_call method_name: $methodName hWallet: $hWallet params: $methodParams');
      final invokeResult = ApiCalls.asyncCall(methodName: 'invoke', hWallet: hWallet, params: methodParams);
      logger.i('async_call result $invokeResult');
      var map = json.decode(invokeResult) as Map<String, dynamic>;
      int attempts = 0;
      if (map['job_id'] != null) {
        do {
          if (map['job_id'] != null) {
            await Future.delayed(Duration(milliseconds: attempts < 2 ? 100 : 500));
            final jobId = map['job_id'] as int;
            logger.i('try_pull_result jobId $jobId');
            final result = ApiCalls.tryPullResult(jobId: jobId);
            logger.i('try_pull_result result $result');
            map = jsonDecode(result);
            if (map['status'] != null && map['status'] == statusDelivered && map['result'] != null) {
              return result;
            }
          }
        } while (++attempts < maxAttempts);
        return '';
      }
      return invokeResult;
    } else {
      logger.i('sync_call method_name $methodName hWallet $hWallet params $methodParams');
      final invokeResult = ApiCalls.syncCall(methodName: 'invoke', hWallet: hWallet, params: methodParams);
      logger.i('invoke result $invokeResult');
      return invokeResult;
    }
  }

  String getVersion() => ApiCalls.getVersion();

  bool setupNode() {
    logger.d('setup_node');
    final isSetupNode = ApiCalls.setupNode(address: defaultHost, login: '', password: '', useSSL: false, isLightWallet: false);
    logger.d('setup_node result $isSetupNode');
    return isSetupNode;
  }

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

  bool isWalletExist({required String path}) {
    logger.d('is_wallet_exist path $path');
    final isExist = ApiCalls.isWalletExist(path: path);
    logger.d('is_wallet_exist result $isExist');
    return isExist;
  }

  void closeWallet() {
    logger.d('close_wallet hWallet $hWallet');
    ApiCalls.closeWallet(hWallet: hWallet);
  }

  Future<GetWalletInfoResult> getWalletInfo() async {
    logger.d('get_wallet_info hWallet $hWallet');
    final json = await compute<int, String>(ApiCalls.getWalletInfo, hWallet);
    logger.d('get_wallet_info result $json');
    if (json == walletWrongId) throw WalletWrongIdException();
    return GetWalletInfoResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  GetWalletStatusResult getWalletStatus() {
    logger.d('get_wallet_status hWallet $hWallet');
    final json = ApiCalls.getWalletStatus(hWallet: hWallet);
    logger.d('get_wallet_status result $json');
    if (json == walletWrongId) throw WalletWrongIdException();
    return GetWalletStatusResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  int getCurrentTxFee({required int priority}) {
    logger.d('get_current_tx_fee priority $priority');
    final result = ApiCalls.getCurrentTxFee(priority: priority);
    logger.d('get_current_tx_fee result $result');
    return result;
  }

  GetConnectivityStatusResult? getConnectivityStatus() {
    final json = ApiCalls.getConnectivityStatus();
    logger.d('get_connectivity_status result $json');
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (map['result'] != null && map['result']['return_code'] == unitialized) return null;
    return GetConnectivityStatusResult.fromJson(map);
  }

  GetAddressInfoResult getAddressInfo({required String address}) {
    logger.d('get_address_info $address');
    final json = ApiCalls.getAddressInfo(address: address);
    logger.d('get_address_info result $json');
    return GetAddressInfoResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<StoreResult?> store() async {
    logger.d('store');
    final json = await _invokeMethod(hWallet, 'store', '{}', async: true);
    logger.d('store result $json');
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (map['result'] == null || map['result']['result'] == null) return null;
    return StoreResult.fromJson(map['result']['result']);
  }

  Future<TransferResult?> transfer(TransferParams params) async {
    final result = await _invokeMethod(hWallet, 'transfer', jsonEncode(params), async: true);
    final map = jsonDecode(result);
    if (map['result'] == null) throw new ZanoWalletException();
    if (map['result']['error'] != null)
      throw TransferException(
        map['result']['error']['code'] as int,
        map['result']['error']['message'] as String,
      );
    if (map['result']['result'] != null) return TransferResult.fromJson(map['result']['result']);
    return null;
  }

  Future<List<History>?> getRecentTxsAndInfo(GetRecentTxsAndInfoParams params) async {
    final result = await _invokeMethod(hWallet, 'get_recent_txs_and_info', json.encode(params), async: true);
    final map = jsonDecode(result);
    if (map == null || map["result"] == null || map["result"]["result"] == null || map["result"]["result"]["transfers"] == null) return null;
    return (map["result"]["result"]["transfers"] as List<dynamic>).map((e) => History.fromJson(e as Map<String, dynamic>)).toList();
  }
}
