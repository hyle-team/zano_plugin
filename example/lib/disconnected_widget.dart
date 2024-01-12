// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zano/connected_widget.dart';
import 'package:zano/zano_wallet_provider.dart';

class DisconnectedWidget extends StatefulWidget {
  const DisconnectedWidget({super.key});
  static const route = 'disconnected';

  @override
  State<DisconnectedWidget> createState() => _DisconnectedWidgetState();
}

class _DisconnectedWidgetState extends State<DisconnectedWidget> {
  TextEditingController? _name;
  late final TextEditingController _seed = TextEditingController(text: '');
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
      builder: (context, provider, _) => Scaffold(
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
                        Text('Version: ${provider.version}'),
                        if (provider.connectivityStatusResult != null)
                          Text('Is Online: ${provider.connectivityStatusResult!.isOnline}, IsServerBusy: ${provider.connectivityStatusResult!.isServerBusy}'),
                        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Wallet name'), onChanged: (value) => provider.walletName = value),
                        const SizedBox(height: 16),
                        Text('Is wallet exists: ${provider.isWalletExists}'),
                        TextButton(
                            onPressed: provider.isWalletExists
                                ? null
                                : () async {
                                    final result = await provider.create();
                                    if (result) {
                                      if (!mounted) return;
                                      Navigator.of(context).pushReplacementNamed(ConnectedWidget.route, arguments: result);
                                    }
                                  },
                            child: Text('Create New Wallet')),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: !provider.isWalletExists
                              ? null
                              : () async {
                                  final result = await provider.connect();
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
                          onPressed: provider.isWalletExists
                              ? null
                              : () async {
                                  final result = await provider.restore(_seed.text);
                                  if (result) {
                                    if (!mounted) return;
                                    Navigator.of(context).pushReplacementNamed(ConnectedWidget.route, arguments: result);
                                  }
                                },
                          child: Text('Restore from seed'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(child: Text('Close Wallet'), onPressed: () => provider.close()),
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
