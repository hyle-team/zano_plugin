import 'dart:async';

import 'package:cw_zano/model/balance.dart';
import 'package:cw_zano/model/create_wallet_result.dart';
import 'package:cw_zano/utils/utils.dart';
import 'package:cw_zano/zano/zano_new_wallet_credentials.dart';
import 'package:cw_zano/zano_wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zano/connected_widget.dart';
import 'package:zano/disconnected_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zano/logic/zano_wallet_provider.dart';
import 'package:logger/logger.dart';



//Logger.level = Level.warning;

void main() {
  Logger.level = Level.info;
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
    return ChangeNotifierProvider<ZanoWalletProvider>(
      create: (_) => ZanoWalletProvider(),
      child: MaterialApp(
        home: const DisconnectedWidget(), //HomeWidget(),
        routes: {
          ConnectedWidget.route: (context) {
            return const ConnectedWidget();
          },
          DisconnectedWidget.route: (context) => const DisconnectedWidget(),
        },
      ),
    );
  }
}
