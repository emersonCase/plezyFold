import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/platform/player_android_mpv.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('default Android mpv player forwards tabletop bounds to its native surface', () async {
    final calls = <MethodCall>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        calls.add(call);
        return call.method == 'initialize' ? true : null;
      },
      testBody: () async {
        final player = PlayerAndroidMpv();
        try {
          await player.setVideoRect(left: 0, top: 0, right: 2152, bottom: 1038, devicePixelRatio: 2);
        } finally {
          await player.dispose();
        }
      },
    );

    final call = calls.singleWhere((call) => call.method == 'setVideoRect');
    expect(call.arguments, containsPair('left', 0));
    expect(call.arguments, containsPair('top', 0));
    expect(call.arguments, containsPair('right', 2152));
    expect(call.arguments, containsPair('bottom', 1038));
  });
}
