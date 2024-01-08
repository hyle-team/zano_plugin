// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:math';

import 'package:cw_zano/exceptions/transfer_exception.dart';
import 'package:cw_zano/model/destination.dart';
import 'package:cw_zano/model/get_recent_txs_and_info_params.dart';
import 'package:cw_zano/model/history.dart';
import 'package:cw_zano/model/transfer_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zano/disconnected_widget.dart';
import 'package:zano/logic/zano_wallet_provider.dart';

class ConnectedWidget extends StatefulWidget {
  const ConnectedWidget({super.key});
  static const route = 'connected';

  @override
  State<ConnectedWidget> createState() => _ConnectedWidgetState();
}

class _ConnectedWidgetState extends State<ConnectedWidget> {
  final int _mixin = 10;
  late final TextEditingController _destinationAddress;
  static const defaultAmount = 1.0;
  late final TextEditingController _amount = TextEditingController(text: defaultAmount.toString());
  late String _amountFormatted = _mulBy10_12(defaultAmount);
  late final TextEditingController _paymentId = TextEditingController();
  late final TextEditingController _comment = TextEditingController(text: "test");
  bool _pushPayer = false;
  bool _hideReceiver = true;
  String _transferResult = '';
  List<History>? _transactions;

  @override
  void initState() {
    super.initState();
    final zanoWallet = Provider.of<ZanoWalletProvider>(context, listen: false);
    _destinationAddress = TextEditingController(text: zanoWallet.myAddress);
  }

  @override
  void dispose() {
    _destinationAddress.dispose();
    _amount.dispose();
    _paymentId.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Consumer<ZanoWalletProvider>(builder: (context, zanoWallet, child) {
        return Scaffold(
          appBar: AppBar(
              title: Text('Version ${zanoWallet.version}'),
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Provider.of<ZanoWalletProvider>(context, listen: false).close();
                    Navigator.of(context).pushReplacementNamed(DisconnectedWidget.route);
                  },
                )
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Main'),
                  Tab(text: 'Transfer'),
                  Builder(builder: (context) {
                    if (zanoWallet.createWalletResult != null && zanoWallet.createWalletResult!.recentHistory.history != null) {
                      return Tab(text: 'History (${zanoWallet.createWalletResult!.recentHistory.history!.length})');
                    }
                    return Tab(text: 'History');
                  }),
                  Tab(text: 'Transactions')
                ],
              )),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TabBarView(
                children: [
                  _mainTab(context, zanoWallet),
                  _transferTab(context, zanoWallet),
                  _historyTab(context, zanoWallet),
                  _transactionsTab(context, zanoWallet),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _transactionsTab(BuildContext context, ZanoWalletProvider zanoWallet) {
    return Column(children: [
      TextButton(onPressed: () => _getTransactions(zanoWallet), child: Text('Update list of Transactions')),
      Expanded(child: _transactionsListView(_transactions)),
    ]);
  }

  Widget _historyTab(BuildContext context, ZanoWalletProvider zanoWallet) {
    if (zanoWallet.createWalletResult == null) return Text("Empty");
    return _transactionsListView(zanoWallet.createWalletResult!.recentHistory.history);
  }

  ListView _transactionsListView(List<History>? list) {
    return ListView.builder(
      itemCount: list != null ? list.length : 0,
      itemBuilder: (context, index) {
        final item = list![index];
        late String addr;
        if (item.remoteAddresses.isNotEmpty) {
          addr = Provider.of<ZanoWalletProvider>(context, listen: false).shorten(item.remoteAddresses.first);
        } else {
          addr = "???";
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("${index + 1}. ${_dateTime(item.timestamp)} Remote addr: $addr"),
                if (item.remoteAddresses.isNotEmpty)
                  IconButton(
                    onPressed: () => Clipboard.setData(ClipboardData(text: item.remoteAddresses.first)),
                    icon: Icon(Icons.copy),
                  ),
                if (item.remoteAliases.isNotEmpty) Text(" (${item.remoteAliases.first})"),
              ],
            ),
            Text("  txHash: ${item.txHash} comment: ${item.comment}"),
            Text("  paymentId: ${item.paymentId} height: ${item.height} fee: ${_divBy10_12(item.fee)}"),
            if (item.employedEntries.receive.isNotEmpty) Text("  Receive", style: TextStyle(fontWeight: FontWeight.bold)),
            for (int i = 0; i < item.employedEntries.receive.length; i++)
              Text(
                  '  ${item.employedEntries.receive[i].index}. ${Provider.of<ZanoWalletProvider>(context, listen: false).getAssetName(item.employedEntries.receive[i].assetId)} ${_divBy10_12(item.employedEntries.receive[i].amount)}'),
            if (item.employedEntries.send.isNotEmpty) Text("  Spent", style: TextStyle(fontWeight: FontWeight.bold)),
            for (int i = 0; i < item.employedEntries.send.length; i++)
              Text(
                  '  ${item.employedEntries.send[i].index}. ${Provider.of<ZanoWalletProvider>(context, listen: false).getAssetName(item.employedEntries.send[i].assetId)} ${_divBy10_12(item.employedEntries.send[i].amount)}'),
            if (item.subtransfers.isNotEmpty) Text("  Subtransfers", style: TextStyle(fontWeight: FontWeight.bold)),
            for (int i = 0; i < item.subtransfers.length; i++)
              Text(
                  '  ${item.subtransfers[i].isIncome ? 'In' : 'Out'}. ${Provider.of<ZanoWalletProvider>(context, listen: false).getAssetName(item.subtransfers[i].assetId)} ${_divBy10_12(item.subtransfers[i].amount)}'),
            Divider(),
          ],
        );
      },
    );
  }

  Widget _transferTab(BuildContext context, ZanoWalletProvider zanoWallet) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Remote Address ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: TextField(
                  controller: _destinationAddress,
                ),
              ),
              IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: _destinationAddress.text)), icon: Icon(Icons.copy)),
              IconButton(
                  onPressed: () async {
                    final clipboard = await Clipboard.getData("text/plain");
                    if (clipboard == null || clipboard.text == null) return;
                    setState(() {
                      _destinationAddress.text = clipboard.text!;
                    });
                  },
                  icon: Icon(Icons.paste)),
            ],
          ),
          Row(
            children: [
              //  ${lwr!.wi.address}
              Text('Amount ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: TextField(
                  controller: _amount,
                  onChanged: (value) => setState(() {
                    _amountFormatted = _mulBy10_12(double.parse(value));
                  }),
                ),
              ),
              Text("= ${_amountFormatted}"),
              IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: _amount.text)), icon: Icon(Icons.copy)),
            ],
          ),
          Text('Fee: ${_divBy10_12(zanoWallet.txFee)} (${zanoWallet.txFee})'),
          Text('Mixin: $_mixin'),
          Row(children: [
            Text('Payment Id ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: TextField(controller: _paymentId)),
          ]),
          Row(children: [
            Text('Comment ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: TextField(controller: _comment)),
          ]),
          Row(
            children: [
              Text('Push Payer ', style: TextStyle(fontWeight: FontWeight.bold)),
              Checkbox(value: _pushPayer, onChanged: (value) => setState(() => _pushPayer = value ?? false)),
            ],
          ),
          Row(
            children: [
              Text('Hide Receiver ', style: TextStyle(fontWeight: FontWeight.bold)),
              Checkbox(value: _hideReceiver, onChanged: (value) => setState(() => _hideReceiver = value ?? false)),
            ],
          ),
          TextButton(onPressed: () => _transfer(zanoWallet), child: Text('Transfer')),
          const SizedBox(height: 16),
          Text('Transfer result $_transferResult'),
        ],
      ),
    );
  }

  Widget _mainTab(BuildContext context, ZanoWalletProvider zanoWallet) {
    final walletStatus = zanoWallet.getWalletStatusResult;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wallet Info', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text('My Address ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                  child: Text(
                zanoWallet.myAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
              IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: zanoWallet.myAddress)), icon: Icon(Icons.copy)),
            ],
          ),
          for (final balance in zanoWallet.balances) Text('Balance (${balance.assetInfo.ticker}) total: ${_divBy10_12(balance.total)}, unlocked: ${_divBy10_12(balance.unlocked)}'),
          Row(
            children: [
              Text('Seed ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(zanoWallet.seed, maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: zanoWallet.seed)), icon: Icon(Icons.copy)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Wallet Status  (${zanoWallet.walletSyncing ? "SYNC" : "CONNECTED"})', style: TextStyle(fontWeight: FontWeight.bold)),
          if (walletStatus != null) ...[
            Row(
              children: [
                Expanded(child: Text('Daemon Height ${walletStatus!.currentDaemonHeight}')),
                Expanded(child: Text('Wallet Height ${walletStatus!.currentWalletHeight}')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Daemon Connected ${walletStatus!.isDaemonConnected}')),
                Expanded(child: Text('In Long Refresh ${walletStatus!.isInLongRefresh}')),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Progress ${walletStatus!.progress}')),
                Expanded(child: Text('WalletState ${walletStatus!.walletState}')),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text('Tx Fee: ${_divBy10_12(zanoWallet.txFee)} (${zanoWallet.txFee})'),
          TextButton(
              onPressed: () {
                Provider.of<ZanoWalletProvider>(context, listen: false).store();
              },
              child: Text('Store')),
          const SizedBox(height: 16),
          TextButton(
              onPressed: () {
                Provider.of<ZanoWalletProvider>(context, listen: false).close();
                Navigator.of(context).pushReplacementNamed(DisconnectedWidget.route);
              },
              child: Text('Disconnect')),
        ],
      ),
    );
  }

  Future<void> _transfer(ZanoWalletProvider zanoWallet) async {
    try {
      final result = await zanoWallet.transfer(TransferParams(
        destinations: [
          Destination(
            amount: _mulBy10_12(double.parse(_amount.text)),
            address: _destinationAddress.text,
            assetId: zanoWallet.assetIds.keys.first,
          )
        ],
        fee: 0,
        mixin: _mixin,
        paymentId: _paymentId.text,
        comment: _comment.text,
        pushPayer: _pushPayer,
        hideReceiver: _hideReceiver,
      ));
      if (result == null) {
        setState(() => _transferResult = 'empty result');
      } else {
        setState(() => _transferResult = "transfer tx hash ${result.txHash} size ${result.txSize} ");
      }
    } on TransferException catch (e) {
      setState(() => _transferResult = "error code ${e.code} message ${e.message}");
    }
  }

  Future<void> _getTransactions(ZanoWalletProvider zanoWallet) async {
    final transactions = await zanoWallet.getRecentTxsAndInfo(GetRecentTxsAndInfoParams(offset: 0, count: 30));
    setState(() {
      _transactions = transactions;
    });
  }

  String _divBy10_12(int value) {
    return (value / pow(10, 12)).toString();
  }

  String _mulBy10_12(double value) {
    var str = (value * pow(10, 12)).toString();
    if (str.contains('.')) str = str.split('.')[0];
    return str;
  }

  String _dateTime(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _row(String first, String second, String third, String forth, String fifth, String sixth) => Row(
        children: [
          Expanded(child: Text(first)),
          Expanded(flex: 2, child: Text(second)),
          Expanded(flex: 2, child: Text(third)),
          Expanded(flex: 3, child: Text(forth)),
          Expanded(flex: 3, child: Text(fifth)),
          Expanded(child: Text(sixth)),
        ],
      );
}
