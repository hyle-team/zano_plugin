// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:math';

import 'package:cw_zano/exceptions/transfer_exception.dart';
import 'package:cw_zano/model/destination.dart';
import 'package:cw_zano/model/get_recent_txs_and_info_params.dart';
import 'package:cw_zano/model/history.dart';
import 'package:cw_zano/model/transfer_params.dart';
import 'package:cw_zano/zano_wallet.dart';
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
  late final TextEditingController _destinationAddress;
  static const defaultAmount = 1.0;
  late final TextEditingController _amount = TextEditingController(text: defaultAmount.toString());
  late String _amountFormatted = _mulBy10_12(defaultAmount);
  late final TextEditingController _paymentId = TextEditingController();
  late final TextEditingController _comment = TextEditingController(text: 'test');
  bool _pushPayer = false;
  bool _hideReceiver = true;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ZanoWalletProvider>(context, listen: false);
    _destinationAddress = TextEditingController(text: provider.myAddress);
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
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
              title: Consumer<ZanoWalletProvider>(builder: (context, provider, _) => Text('Version ${provider.version}')),
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
                  Consumer<ZanoWalletProvider>(builder: (context, provider, _) {
                    if (provider.createWalletResult != null && provider.createWalletResult!.recentHistory.history != null) {
                      return Tab(text: 'History (${provider.createWalletResult!.recentHistory.history!.length})');
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
                  _mainTab(),
                  _transferTab(),
                  _historyTab(),
                  _transactionsTab(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _transactionsTab() {
    final result = Provider.of<ZanoWalletProvider>(context).getRecentTxsAndInfoResult;
    final error = Provider.of<ZanoWalletProvider>(context).getRecentTxsAndInfoError;
    return Column(children: [
      if (result != null) Text('Last item index: ${result.lastItemIndex}, total transfers: ${result.totalTransfers}'),
      if (result != null) Text('Transfer entries count: ${result.pi.transferEntriesCount}, transfers count: ${result.pi.transfersCount}'),
      if (error != null) Text('Transactions result $error'),
      TextButton(onPressed: () => Provider.of<ZanoWalletProvider>(context, listen: false).getRecentTxsAndInfo(), child: Text('Update list of Transactions')),
      if (result != null) Expanded(child: _transactionsListView(result.transfers)),
    ]);
  }

  Widget _historyTab() => Consumer<ZanoWalletProvider>(
        builder: (context, provider, _) => provider.createWalletResult == null
            ? Text('Empty')
            : _transactionsListView(
                provider.createWalletResult!.recentHistory.history,
              ),
      );

  ListView _transactionsListView(List<History>? list) {
    return ListView.builder(
      itemCount: list != null ? list.length : 0,
      itemBuilder: (context, index) {
        final item = list![index];
        late String addr;
        if (item.remoteAddresses.isNotEmpty) {
          addr = Provider.of<ZanoWalletProvider>(context, listen: false).shorten(item.remoteAddresses.first);
        } else {
          addr = 'empty';
        }
        final txHash = Provider.of<ZanoWalletProvider>(context, listen: false).shorten(item.txHash);
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${index + 1}. ${_dateTime(item.timestamp)} Remote addr: $addr'),
                if (item.remoteAddresses.isNotEmpty)
                  IconButton(
                    onPressed: () => Clipboard.setData(ClipboardData(text: item.remoteAddresses.first)),
                    icon: Icon(Icons.copy),
                  ),
                if (item.remoteAliases.isNotEmpty) Text(' (${item.remoteAliases.first})'),
              ],
            ),
            Row(
              children: [
                Text('  txHash: $txHash '),
                IconButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: item.txHash)),
                  icon: Icon(Icons.copy, size: 16),
                ),
              ],
            ),
            Text('  comment: ${item.comment} paymentId: ${item.paymentId} height: ${item.height} fee: ${_divBy10_12(item.fee)}'),
            if (item.employedEntries.receive.isNotEmpty) Text('  Receive', style: TextStyle(fontWeight: FontWeight.bold)),
            for (int i = 0; i < item.employedEntries.receive.length; i++)
              Text(
                  '  ${item.employedEntries.receive[i].index}. ${Provider.of<ZanoWalletProvider>(context, listen: false).getAssetName(item.employedEntries.receive[i].assetId)} ${_divBy10_12(item.employedEntries.receive[i].amount)}'),
            if (item.employedEntries.send.isNotEmpty) Text('  Spent', style: TextStyle(fontWeight: FontWeight.bold)),
            for (int i = 0; i < item.employedEntries.send.length; i++)
              Text(
                  '  ${item.employedEntries.send[i].index}. ${Provider.of<ZanoWalletProvider>(context, listen: false).getAssetName(item.employedEntries.send[i].assetId)} ${_divBy10_12(item.employedEntries.send[i].amount)}'),
            if (item.subtransfers.isNotEmpty) Text('  Subtransfers', style: TextStyle(fontWeight: FontWeight.bold)),
            for (int i = 0; i < item.subtransfers.length; i++)
              Text(
                  '  ${item.subtransfers[i].isIncome ? 'In' : 'Out'}. ${Provider.of<ZanoWalletProvider>(context, listen: false).getAssetName(item.subtransfers[i].assetId)} ${_divBy10_12(item.subtransfers[i].amount)}'),
            Divider(),
          ],
        );
      },
    );
  }

  Widget _transferTab() {
    final provider = Provider.of<ZanoWalletProvider>(context);
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
              IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: _destinationAddress.text)), icon: Icon(Icons.copy, size: 16)),
              IconButton(
                  onPressed: () async {
                    final clipboard = await Clipboard.getData('text/plain');
                    if (clipboard == null || clipboard.text == null) return;
                    setState(() {
                      _destinationAddress.text = clipboard.text!;
                    });
                  },
                  icon: Icon(Icons.paste, size: 16)),
            ],
          ),
          Row(
            children: [
              Text('Amount ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: TextField(
                  controller: _amount,
                  onChanged: (value) => setState(() {
                    try {
                      _amountFormatted = _mulBy10_12(double.parse(value));
                    } catch (e) {
                      _amountFormatted = '0';
                    }
                  }),
                ),
              ),
              Text('= $_amountFormatted'),
              IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: _amount.text)), icon: Icon(Icons.copy, size: 16)),
            ],
          ),
          Text('Fee: ${_divBy10_12(provider.txFee)} (${provider.txFee})'),
          Text('Mixin: $provider.mixin'),
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
          TextButton(
              onPressed: () => Provider.of<ZanoWalletProvider>(context, listen: false)
                  .transfer(_amount.text, _destinationAddress.text, _paymentId.text, _comment.text, _pushPayer, _hideReceiver),
              child: Text('Transfer')),
          const SizedBox(height: 16),
          if (provider.transferResult != null) Text('Transfer result txHash: ${provider.transferResult!.txHash} txSize: ${provider.transferResult!.txSize}'),
          if (provider.transferError != null) Text('Transfer error ${provider.transferError}'),
        ],
      ),
    );
  }

  Widget _mainTab() {
    final provider = Provider.of<ZanoWalletProvider>(context);
    final walletStatus = provider.getWalletStatusResult;
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
                provider.myAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
              IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: provider.myAddress)), icon: Icon(Icons.copy, size: 16)),
            ],
          ),
          for (final balance in provider.balances) Text('Balance (${balance.assetInfo.ticker}) total: ${_divBy10_12(balance.total)}, unlocked: ${_divBy10_12(balance.unlocked)}'),
          Row(
            children: [
              Text('Seed ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(provider.seed, maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: provider.seed)), icon: Icon(Icons.copy, size: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Wallet Status  (${provider.walletSyncing ? 'SYNC' : 'CONNECTED'})', style: TextStyle(fontWeight: FontWeight.bold)),
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
          Text('Tx Fee: ${_divBy10_12(provider.txFee)} (${provider.txFee})'),
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

  // Future<void> _getTransactions(ZanoWallet zanoWallet) async {
  //   try {
  //     Provider.of<ZanoWalletProvider>(context, listen: false).getRecentTxsAndInfo();
  //     final result = await zanoWallet.getRecentTxsAndInfo(GetRecentTxsAndInfoParams(offset: 0, count: 30));
  //     setState(() {
  //       _lastItemIndex = result.lastItemIndex;
  //       _totalTransfers = result.totalTransfers;
  //       _transferEntriesCount = result.pi.transferEntriesCount;
  //       _transfersCount = result.pi.transfersCount;
  //       _transactions = result.transfers;
  //       _transactionsError = '';
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _lastItemIndex = _totalTransfers = _transferEntriesCount = _transfersCount = 0;
  //       _transactions = [];
  //       _transactionsError = e.toString();
  //     });
  //   }
  // }

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
