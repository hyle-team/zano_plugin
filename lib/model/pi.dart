class Pi {
  final int balance;
  final int currentHeight;
  final int transferEntriesCount;
  final int transfersCount;
  final int unlockedBalance;

  Pi({
    required this.balance,
    required this.currentHeight,
    required this.transferEntriesCount,
    required this.transfersCount,
    required this.unlockedBalance,
  });

  factory Pi.fromJson(Map<String, dynamic> json) => Pi(
        balance: json['balance'] as int,
        currentHeight: json['curent_height'] as int,
        transferEntriesCount: json['transfer_entries_count'] as int,
        transfersCount: json['transfers_count'] as int,
        unlockedBalance: json['unlocked_balance'] as int,
      );
}
