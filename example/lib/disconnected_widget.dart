// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zano/connected_widget.dart';
import 'package:zano/logic/zano_wallet_provider.dart';

class DisconnectedWidget extends StatefulWidget {
  const DisconnectedWidget({super.key});
  static const route = 'disconnected';

  @override
  State<DisconnectedWidget> createState() => _DisconnectedWidgetState();
}

class _DisconnectedWidgetState extends State<DisconnectedWidget> {
  TextEditingController? _name;
  late final TextEditingController _seed = TextEditingController(
      text:
          "palm annoy brush task almost through here sent doll guilty smart horse mere canvas flirt advice fruit known shower happiness steel autumn beautiful approach anymore canvas");
  bool _loading = false;

  @override
  void initState() {
    final zanoWalletProvider = Provider.of<ZanoWalletProvider>(context, listen: false);
    super.initState();
    _name = TextEditingController(text: zanoWalletProvider.walletName.isEmpty ? 'wallet' : zanoWalletProvider.walletName);
    // () async {
    //   final preferences = await SharedPreferences.getInstance();
    //   final value = preferences.getString(Consts.walletName);
    //   if (value != null && value.isNotEmpty) _name.text = value;
    // }();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ZanoWalletProvider>(
      builder: (context, zanoWallet, _) => Scaffold(
        appBar: AppBar(title: Text('Disconnected')),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Stack(
                children: [
                  Opacity(
                    opacity: _loading ? 0.5 : 1,
                    child: Column(
                      children: [
                        Text('Version: ${zanoWallet.version}'),
                        if (zanoWallet.connectivityStatus != null)
                          Text('Is Online: ${zanoWallet.connectivityStatus!.isOnline}, IsServerBusy: ${zanoWallet.connectivityStatus!.isServerBusy}'),
                        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Wallet name'), onChanged: (value) => zanoWallet.walletName = value),
                        const SizedBox(height: 16),
                        Text('Is wallet exists: ${zanoWallet.isWalletExists}'),
                        TextButton(
                            onPressed: zanoWallet.isWalletExists
                                ? null
                                : () async {
                                    final result = await zanoWallet.create();
                                    if (result) {
                                      if (!mounted) return;
                                      Navigator.of(context).pushReplacementNamed(ConnectedWidget.route, arguments: result);
                                    }
                                  },
                            child: Text('Create New Wallet')),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: !zanoWallet.isWalletExists
                              ? null
                              : () async {
                                  final result = await Provider.of<ZanoWalletProvider>(context, listen: false).connect();
                                  if (result) {
                                    if (!mounted) return;
                                    Navigator.of(context).pushReplacementNamed(ConnectedWidget.route, arguments: result);
                                  }
                                },
                          child: Text('Connect to Existing Wallet'),
                        ),
                        const SizedBox(height: 16),
                        TextField(controller: _seed, decoration: InputDecoration(labelText: 'Wallet seed')),
                        TextButton(
                          onPressed: zanoWallet.isWalletExists
                              ? null
                              : () async {
                                  final result = await zanoWallet.restore(_seed.text);
                                  if (result) {
                                    if (!mounted) return;
                                    Navigator.of(context).pushReplacementNamed(ConnectedWidget.route, arguments: result);
                                  }
                                },
                          child: Text('Restore from seed'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(child: Text('Close Wallet'), onPressed: () => zanoWallet.close()),
                      ],
                    ),
                  ),
                  if (_loading) Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
