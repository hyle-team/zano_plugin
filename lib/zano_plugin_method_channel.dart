import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'zano_plugin_platform_interface.dart';

/// An implementation of [ZanoPluginPlatform] that uses method channels.
class MethodChannelZanoPlugin extends ZanoPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('zano_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
