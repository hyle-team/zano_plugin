import 'package:example/connected_widget.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisconnectedWidget extends StatefulWidget {
  const DisconnectedWidget({super.key});
  static const route = 'disconnected';

  @override
  State<DisconnectedWidget> createState() => _DisconnectedWidgetState();
}

class _DisconnectedWidgetState extends State<DisconnectedWidget> {
  late final TextEditingController _name = TextEditingController(text: "wallet");
  late final TextEditingController _seed = TextEditingController(
      text:
          "palm annoy brush task almost through here sent doll guilty smart horse mere canvas flirt advice fruit known shower happiness steel autumn beautiful approach anymore canvas");
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    () async {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString(walletName);
      if (value != null && value.isNotEmpty) _name.text = value;
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Disconnected')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Stack(
            children: [
              Opacity(
                opacity: _loading ? 0.5 : 1,
                child: Column(
                  children: [
                    TextField(controller: _name, decoration: InputDecoration(labelText: 'Wallet name')),
                    TextButton(
                        child: Text('Connect and Open Wallet'),
                        onPressed: () async {
                          //setState(() => _loading = true);
                          final preferences = await SharedPreferences.getInstance();
                          await preferences.setString(walletName, _name.text);
                          final result = await connect(_name.text);
                          //setState(() => _loading = false);
                          if (result != null) {
                            debugPrint("navigated to connected");
                            Navigator.of(context).pushReplacementNamed(
                              ConnectedWidget.route,
                              arguments: result,
                            );
                          } else {
                            debugPrint('connect no result');
                          }
                        }),
                    const SizedBox(height: 16),
                    TextButton(
                        child: Text('Create and Open Wallet'),
                        onPressed: () async {
                          //setState(() => _loading = true);
                          final preferences = await SharedPreferences.getInstance();
                          await preferences.setString(walletName, _name.text);
                          final result = await create(_name.text);
                          //setState(() => _loading = false);
                          if (result != null) {
                            debugPrint("navigating to connected");
                            Navigator.of(context).pushReplacementNamed(
                              ConnectedWidget.route,
                              arguments: result,
                            );
                          } else {
                            debugPrint('create no result');
                          }
                        }),
                    const SizedBox(height: 16),
                    TextField(controller: _seed, decoration: InputDecoration(labelText: 'Wallet seed')),
                    TextButton(
                        child: Text('Restore from seed'),
                        onPressed: () async {
                          final preferences = await SharedPreferences.getInstance();
                          await preferences.setString(walletName, _name.text);
                          final result = await restore(_name.text, _seed.text);
                          if (result != null) {
                            Navigator.of(context).pushReplacementNamed(
                              ConnectedWidget.route,
                              arguments: result,
                            );
                          } else {
                            debugPrint('restore no result');
                          }
                        }),
                    const SizedBox(height: 16),
                    TextButton(child: Text('Close Wallet'), onPressed: close),
                  ],
                ),
              ),
              if (_loading) Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
