# Zano Wallet Plugin for Flutter

Take look at example code in example/lib/*.dart


### Setting Up a Node

Before any wallet operation, set up a node:

```dart
ZanoWallet zanoWallet = ZanoWallet();
zanoWallet.setupNode();
```

### Checking if there a Wallet File
```dart
isWalletExists = zanoWallet.isWalletExist(path: await Utils.pathForWallet(name: 'wallet name'));
```

### Creating a New Wallet File

There shouldn't be a wallet file at provided path!

```dart
final path = await Utils.pathForWallet(name: 'wallet name');
final result = zanoWallet.createWallet(path: path, password: 'default password');
if (result != null) {
  _parseCreateWalletResult(result);
  _connected = true
  . . .
```

### Restoring Wallet from a Seed

There shouldn't be a wallet file at provided path!

```dart
final path = await Utils.pathForWallet(name: 'wallet name');
final result = zanoWallet.restoreWalletFromSeed(path: path, password: 'default password', seed: 'seed');
if (result != null) {
  _parseCreateWalletResult(result);
  _connected = true;
  . . .
```

### Loading Existing Wallet File

Check file's existence before calling

```dart
final path = await Utils.pathForWallet(name: 'wallet name');
final result = zanoWallet.loadWallet(path: path, password: 'default password');
if (result != null) {
  _parseCreateWalletResult(result);
  _connected = true;
  . . .
```

### Getting a Wallet Status

Wallet status [GetWalletStatusResult] contains of:
- current daemon height (int)
- current wallet height (int)
- is daemon connected (bool)
- is in long refresh (bool)
- progress (current progress of refreshing, int)
- wallet state (1-syncing, 2-ready, 3-error)

See example below

### Getting a Wallet Information

Wallet information ([GetWalletInfoResult]) contains of:
- [Wi] structure (address, balances, path, etc.)
- [WiExtended] structure (seed, private and public keys)

Note, you can call getWalletInfo ONLY if getWalletStatus returns NOT is in long refresh and wallet state is 2 (ready)
```dart
final walletStatusResult = zanoWallet.getWalletStatus();
if (!walletStatusResult!.isInLongRefresh && walletStatusResult!.walletState == 2) {
  walletSyncing = false;
  final walletInfoResult = await zanoWallet.getWalletInfo();
  . . .
} else {
  walletSyncing = true;
}
```

### Getting Current Transaction Fee
Priority can be 0 (default), 1 (unimportant), 2 (normal), 3 (elevated), 4 (priority)
```dart 
int getCurrentTxFee({required int priority});
```

### Getting Validity of Provided Address
```dart
addressInfoResult = zanoWallet.getAddressInfo(address: address);
print(addressInfoResult.valid);
```

### Storing a Wallet File
```dart
storeResult = await zanoWallet.store();
print(storeResult.walletFileSize);
```

### Making a Transfer
Parameters of a tranfer ([TransferParams])
- List of [Destination]
- fee (int)
- mixin (10, int)
- paymentId (hex string, can be ommited)
- comment (string, can be ommited)
- push payer (bool)
- hide receiver (bool)

Results of a transfer ([TransferParams]): hash (string), size (int)
```dart
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
} catch (e) {
  transferResult = null;
  transferError = e.toString();
}
```

### Getting a List of Transactions
```dart
await zanoWallet.getRecentTxsAndInfo(GetRecentTxsAndInfoParams(offset: 0, count: 30));
```