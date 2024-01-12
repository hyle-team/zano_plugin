import 'dart:async';
import 'dart:math';

import 'package:cw_zano/model/balance.dart';
import 'package:cw_zano/model/create_wallet_result.dart';
import 'package:cw_zano/model/destination.dart';
import 'package:cw_zano/model/get_connectivity_status_result.dart';
import 'package:cw_zano/model/get_recent_txs_and_info_params.dart';
import 'package:cw_zano/model/get_recent_txs_and_info_result.dart';
import 'package:cw_zano/model/get_wallet_info_result.dart';
import 'package:cw_zano/model/get_wallet_status_result.dart';
import 'package:cw_zano/model/history.dart';
import 'package:cw_zano/model/transfer_params.dart';
import 'package:cw_zano/model/transfer_result.dart';
import 'package:cw_zano/utils/utils.dart';
import 'package:cw_zano/zano_wallet.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../consts.dart';

class ZanoWalletProvider extends ChangeNotifier {
  final int mixin = 10;
  static const defaultPassword = 'defaultPassword';
  final zanoWallet = ZanoWallet();
  GetConnectivityStatusResult? connectivityStatus;
  CreateWalletResult? createWalletResult;
  GetWalletInfoResult? getWalletInfoResult;
  GetWalletStatusResult? getWalletStatusResult;
  GetRecentTxsAndInfoResult? getRecentTxsAndInfoResult;
  String? getRecentTxsAndInfoError;
  TransferResult? transferResult;
  String? transferError;
  List<Balance> balances = [];
  String seed = '', version = '';
  final assetIds = <String, String>{};
  late Timer _timer;
  bool _connected = false, walletSyncing = true;
  bool isWalletExists = false;
  String myAddress = '';
  int txFee = 0;

  String _walletName = '';

  String get walletName => _walletName;

  set walletName(String value) {
    _walletName = value;
    _saveWalletNameAndCheckIfExists();
  }

  ZanoWalletProvider() {
    _init();
  }

  Future _init() async {
    final prefs = await SharedPreferences.getInstance();
    _walletName = prefs.getString(Consts.walletName) ?? 'wallet';
    isWalletExists = zanoWallet.isWalletExist(path: await Utils.pathForWallet(name: _walletName));
    version = zanoWallet.getVersion();
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      connectivityStatus = zanoWallet.getConnectivityStatus();
      if (_connected) {
        getWalletStatusResult = zanoWallet.getWalletStatus();
        if (!getWalletStatusResult!.isInLongRefresh && getWalletStatusResult!.walletState == 2) {
          walletSyncing = false;
          getWalletInfoResult = await zanoWallet.getWalletInfo();
          seed = getWalletInfoResult!.wiExtended.seed;
          balances = getWalletInfoResult!.wi.balances;
          assetIds.clear();
          for (final balance in getWalletInfoResult!.wi.balances) {
            assetIds[balance.assetInfo.assetId] = balance.assetInfo.ticker;
          }
        } else {
          walletSyncing = true;
        }
      }
      notifyListeners();
    });

    if (!zanoWallet.setupNode()) {
      debugPrint('error setting up node!');
    }
    notifyListeners();
  }

  Future _saveWalletNameAndCheckIfExists() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(Consts.walletName, _walletName);
    isWalletExists = zanoWallet.isWalletExist(path: await Utils.pathForWallet(name: _walletName));
    notifyListeners();
  }

  Future<bool> connect() async {
    final path = await Utils.pathForWallet(name: _walletName);
    debugPrint('connect path $path password $defaultPassword');
    final result = zanoWallet.loadWallet(path: path, password: defaultPassword);
    if (result != null) {
      _parseResult(result);
      _connected = true;
      myAddress = result.wi.address;
      return true;
    }
    _connected = false;
    return false;
  }

  Future<bool> create() async {
    final path = await Utils.pathForWallet(name: _walletName);
    debugPrint('create name $_walletName path $path password $defaultPassword');
    final result = zanoWallet.createWallet(path: path, password: defaultPassword);
    if (result != null) {
      _parseResult(result);
      _connected = true;
      myAddress = result.wi.address;
      return true;
    }
    _connected = false;
    return false;
  }

  Future<bool> restore(String seed) async {
    final path = await Utils.pathForWallet(name: _walletName);
    debugPrint('restore $_walletName path $path');
    final result = zanoWallet.restoreWalletFromSeed(path: path, password: defaultPassword, seed: seed);
    if (result != null) {
      _parseResult(result);
      _connected = true;
      myAddress = result.wi.address;
      return true;
    }
    _connected = false;
    return false;
  }

  void close() {
    _connected = false;
    zanoWallet.closeWallet();
  }

  void _parseResult(CreateWalletResult result) {
    createWalletResult = result;
    balances = createWalletResult!.wi.balances;
    assetIds.clear();
    for (final balance in createWalletResult!.wi.balances) {
      assetIds[balance.assetInfo.assetId] = balance.assetInfo.ticker;
    }
    notifyListeners();
  }

  String shorten(String someId) {
    if (someId.length < 9) return someId;
    return '${someId.substring(0, 4).toUpperCase()}...${someId.substring(someId.length - 2)}';
  }

  String getAssetName(String assetId) {
    if (assetIds[assetId] != null) {
      return assetIds[assetId]!;
    } else {
      return shorten(assetId);
    }
  }

  Future<void> store() => zanoWallet.store();

  Future getRecentTxsAndInfo() async {
    try {
      getRecentTxsAndInfoResult = await zanoWallet.getRecentTxsAndInfo(GetRecentTxsAndInfoParams(offset: 0, count: 30));
      getRecentTxsAndInfoError = null;
    } catch (e) {
      getRecentTxsAndInfoResult = null;
      getRecentTxsAndInfoError = e.toString();
    }
    notifyListeners();
  }

  Future<void> transfer(
    String amount,
    String destinationAddress,
    String paymentId,
    String comment,
    bool pushPayer,
    bool hideReceiver,
  ) async {
    try {
      txFee = zanoWallet.getCurrentTxFee(priority: 0);
      transferResult = await zanoWallet.transfer(TransferParams(
        destinations: [
          Destination(
            amount: _mulBy10_12(double.parse(amount)),
            address: destinationAddress,
            assetId: assetIds.keys.first,
          )
        ],
        fee: txFee,
        mixin: mixin,
        paymentId: paymentId,
        comment: comment,
        pushPayer: pushPayer,
        hideReceiver: hideReceiver,
      ));
      transferError = null;
      // if (result == null) {
      //   setState(() => _transferResult = 'empty result');
      // } else {
      //   setState(() => _transferResult = 'transfer tx hash ${result.txHash} size ${result.txSize} ');
      // }
    } catch (e) {
      transferResult = null;
      transferError = e.toString();
    }
    notifyListeners();
  }

  String _mulBy10_12(double value) {
    var str = (value * pow(10, 12)).toString();
    if (str.contains('.')) str = str.split('.')[0];
    return str;
  }
}
