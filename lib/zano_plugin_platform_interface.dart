import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'zano_plugin_method_channel.dart';

abstract class ZanoPluginPlatform extends PlatformInterface {
  /// Constructs a ZanoPluginPlatform.
  ZanoPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static ZanoPluginPlatform _instance = MethodChannelZanoPlugin();

  /// The default instance of [ZanoPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelZanoPlugin].
  static ZanoPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ZanoPluginPlatform] when
  /// they register themselves.
  static set instance(ZanoPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
