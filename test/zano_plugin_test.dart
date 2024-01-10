import 'package:flutter_test/flutter_test.dart';
import 'package:zano_plugin/zano_plugin.dart';
import 'package:zano_plugin/zano_plugin_platform_interface.dart';
import 'package:zano_plugin/zano_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockZanoPluginPlatform
    with MockPlatformInterfaceMixin
    implements ZanoPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ZanoPluginPlatform initialPlatform = ZanoPluginPlatform.instance;

  test('$MethodChannelZanoPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelZanoPlugin>());
  });

  test('getPlatformVersion', () async {
    ZanoPlugin zanoPlugin = ZanoPlugin();
    MockZanoPluginPlatform fakePlatform = MockZanoPluginPlatform();
    ZanoPluginPlatform.instance = fakePlatform;

    expect(await zanoPlugin.getPlatformVersion(), '42');
  });
}
