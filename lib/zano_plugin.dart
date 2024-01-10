
import 'zano_plugin_platform_interface.dart';

class ZanoPlugin {
  Future<String?> getPlatformVersion() {
    return ZanoPluginPlatform.instance.getPlatformVersion();
  }
}
