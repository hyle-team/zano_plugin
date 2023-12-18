import 'dart:async';
import 'dart:convert';

import 'package:cw_zano/api/calls.dart' as calls;
import 'package:cw_zano/api/model/balance.dart';
import 'package:cw_zano/api/model/create_wallet_result.dart';
import 'package:cw_zano/utils/generate_wallet_password.dart';
import 'package:cw_zano/utils/key_service.dart';
import 'package:cw_zano/utils/path_for_wallet.dart';
import 'package:cw_zano/utils/wallet_type.dart';
import 'package:cw_zano/zano/zano_new_wallet_credentials.dart';
import 'package:example/connected_widget.dart';
import 'package:example/disconnected_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DisconnectedWidget(), //HomeWidget(),
      routes: {
        ConnectedWidget.route: (context) {
          final address = ModalRoute.of(context)!.settings.arguments! as String;
          return ConnectedWidget(address: address);
        },
        DisconnectedWidget.route: (context) => DisconnectedWidget(),
      },
    );
  }
}

int hWallet = 0;
CreateWalletResult? lwr;
List<Balance> balances = [];
String seed = '', version = '';
final assetIds = <String, String>{};
const walletWrongId = 'WALLET_WRONG_ID';
const walletName = 'walletName';

Future<void> init() async {
  version = calls.getVersion();
  final setupNode = await calls.setupNode(
      address: '195.201.107.230:33336',
      login: '',
      password: '',
      useSSL: false,
      isLightWallet: false);
  if (!setupNode) {
    debugPrint('error setting up node!');
  }
}

Future<String?> create(String name) async {
  debugPrint('create $name');
  await init();
  final path = await pathForWallet(name: name, type: WalletType.zano);
  final credentials = ZanoNewWalletCredentials(name: name);
  final keyService = KeyService(FlutterSecureStorage());
  final password = generateWalletPassword();
  credentials.password = password;
  await keyService.saveWalletPassword(password: password, walletName: credentials.name);
  debugPrint('path $path password $password');
  final result = calls.createWallet(path: path, password: password, language: '');
  debugPrint('create result $result');
  return _parseResult(result);
}

Future<String?> connect(String name) async {
  debugPrint('connect');
  await init();
  final path = await pathForWallet(name: name, type: WalletType.zano);
  final credentials = ZanoNewWalletCredentials(name: name);
  final keyService = KeyService(FlutterSecureStorage());
  final password = await keyService.getWalletPassword(walletName: credentials.name);
  debugPrint('path $path password $password');
  final result = await calls.loadWallet(path, password, 0);
  return _parseResult(result);
}

Future<String?> restore(String name, String seed) async {
  debugPrint("restore");
  await init();
  final path = await pathForWallet(name: name, type: WalletType.zano);
  final credentials = ZanoNewWalletCredentials(name: name);
  final keyService = KeyService(FlutterSecureStorage());
  final password = generateWalletPassword();
  credentials.password = password;
  await keyService.saveWalletPassword(password: password, walletName: credentials.name);
  debugPrint('path $path password $password');
  var result = calls.restoreWalletFromSeed(path, password, seed);
  debugPrint('restore result $result');
  //result = await calls.loadWallet(path, password, 0);
  return _parseResult(result);
}

String? _parseResult(String result) {
  final map = json.decode(result) as Map<String, dynamic>;
  if (map['result'] != null) {
    lwr = CreateWalletResult.fromJson(map['result'] as Map<String, dynamic>);
    balances = lwr!.wi.balances;
    hWallet = lwr!.walletId;
    assetIds.clear();
    for (final balance in lwr!.wi.balances) {
      assetIds[balance.assetInfo.assetId] = balance.assetInfo.ticker;
    }
    return lwr!.wi.address;
  }
  return null;
}

void close() {
  calls.closeWallet(hWallet);
}


