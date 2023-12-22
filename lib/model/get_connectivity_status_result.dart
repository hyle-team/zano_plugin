class GetConnectivityStatusResult {
  final bool isOnline;
  final bool isServerBusy;
  final bool lastDaemonIsDisconnected;
  final DateTime lastProxyCommunicateTimestamp;

  GetConnectivityStatusResult({required this.isOnline, required this.isServerBusy, required this.lastDaemonIsDisconnected, required this.lastProxyCommunicateTimestamp});

  factory GetConnectivityStatusResult.fromJson(Map<String, dynamic> json) => GetConnectivityStatusResult(
        isOnline: json['is_online'] as bool,
        isServerBusy: json['is_server_busy'] as bool,
        lastDaemonIsDisconnected: json['last_daemon_is_disconnected'] as bool,
        lastProxyCommunicateTimestamp: DateTime.fromMillisecondsSinceEpoch((json['last_proxy_communicate_timestamp'] as int) * 1000),
      );
}
