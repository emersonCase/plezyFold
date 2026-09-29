import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/fold_posture_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = FoldPostureService.platformChannel;
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late FoldPostureService service;
  late List<String> calls;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls = [];
    service = FoldPostureService();
  });

  tearDown(() {
    service.debugReset();
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('ordinary Android device degrades to unsupported', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return <String, Object?>{'posture': 'unsupported'};
    });

    service.ensureStarted();
    expect(service.state.posture, FoldPosture.unknown);
    await pumpEventQueue();

    expect(calls, ['getState']);
    expect(service.state, const FoldPostureState.unsupported());
  });

  test('flat and half-opened platform transitions stay distinguishable', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => <String, Object?>{
        'posture': 'flat',
        'orientation': 'vertical',
        'boundsPhysicalPixels': <String, int>{'left': 900, 'top': 0, 'right': 940, 'bottom': 2208},
        'separating': false,
        'occlusion': 'none',
      },
    );

    service.ensureStarted();
    await pumpEventQueue();
    expect(service.state.posture, FoldPosture.flat);
    expect(service.state.isTabletop, isFalse);

    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        const MethodCall('onChanged', <String, Object?>{
          'posture': 'halfOpened',
          'orientation': 'horizontal',
          'boundsPhysicalPixels': <String, int>{'left': 0, 'top': 900, 'right': 1840, 'bottom': 940},
          'separating': true,
          'occlusion': 'full',
        }),
      ),
      (_) {},
    );

    expect(service.state.posture, FoldPosture.halfOpened);
    expect(service.state.isTabletop, isTrue);
    expect(service.state.boundsPhysicalPixels, const Rect.fromLTRB(0, 900, 1840, 940));
    expect(service.state.occlusion, FoldOcclusion.full);
  });

  test('malformed geometry is discarded without losing posture', () {
    final state = FoldPostureState.fromMap({
      'posture': 'halfOpened',
      'orientation': 'horizontal',
      'boundsPhysicalPixels': {'left': 10, 'top': 10, 'right': 5, 'bottom': 5},
    });

    expect(state.posture, FoldPosture.halfOpened);
    expect(state.boundsPhysicalPixels, isNull);
  });

  test('non-Android platforms never touch the channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });

    service.ensureStarted();
    await pumpEventQueue();

    expect(calls, isEmpty);
    expect(service.state, const FoldPostureState.unsupported());
  });

  test('missing native channel degrades to unsupported', () async {
    service.ensureStarted();
    await pumpEventQueue();

    expect(service.state, const FoldPostureState.unsupported());
  });
}
