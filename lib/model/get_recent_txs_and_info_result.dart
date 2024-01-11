import 'package:cw_zano/model/history.dart';
import 'package:cw_zano/model/pi.dart';

class GetRecentTxsAndInfoResult {
  final int lastItemIndex;
  final Pi pi;
  final int totalTransfers;
  final List<History> transfers;

  GetRecentTxsAndInfoResult({
    required this.lastItemIndex,
    required this.pi,
    required this.totalTransfers,
    required this.transfers,
  });

  factory GetRecentTxsAndInfoResult.fromJson(Map<String, dynamic> json) => GetRecentTxsAndInfoResult(
        lastItemIndex: json['last_item_index'] as int,
        pi: Pi.fromJson(json['pi'] as Map<String, dynamic>),
        totalTransfers: json['total_transfers'] as int,
        transfers: json['transfers'] == null ? [] : (json['transfers'] as List<dynamic>).map((e) => History.fromJson(e as Map<String, dynamic>)).toList()
      );
}
