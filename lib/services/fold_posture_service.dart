import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/app_logger.dart';

enum FoldPosture { unknown, unsupported, flat, halfOpened }

enum FoldOrientation { unknown, horizontal, vertical }

enum FoldOcclusion { none, full }

@immutable
class FoldPostureState {
  const FoldPostureState({
    required this.posture,
    this.orientation = FoldOrientation.unknown,
    this.boundsPhysicalPixels,
    this.separating = false,
    this.occlusion = FoldOcclusion.none,
  });

  const FoldPostureState.unknown() : this(posture: FoldPosture.unknown);

  const FoldPostureState.unsupported() : this(posture: FoldPosture.unsupported);

  final FoldPosture posture;
  final FoldOrientation orientation;

  /// Android window coordinates, intentionally kept in physical pixels.
  /// Divide by the active Flutter view's device-pixel ratio at layout time.
  final Rect? boundsPhysicalPixels;
  final bool separating;
  final FoldOcclusion occlusion;

  bool get isTabletop => posture == FoldPosture.halfOpened && orientation == FoldOrientation.horizontal;

  factory FoldPostureState.fromMap(Map<dynamic, dynamic> value) {
    final boundsValue = value['boundsPhysicalPixels'];
    Rect? bounds;
    if (boundsValue is Map) {
      final left = boundsValue['left'];
      final top = boundsValue['top'];
      final right = boundsValue['right'];
      final bottom = boundsValue['bottom'];
      if (left is num && top is num && right is num && bottom is num && right >= left && bottom >= top) {
        bounds = Rect.fromLTRB(left.toDouble(), top.toDouble(), right.toDouble(), bottom.toDouble());
      }
    }

    return FoldPostureState(
      posture: switch (value['posture']) {
        'unsupported' => FoldPosture.unsupported,
        'flat' => FoldPosture.flat,
        'halfOpened' => FoldPosture.halfOpened,
        _ => FoldPosture.unknown,
      },
      orientation: switch (value['orientation']) {
        'horizontal' => FoldOrientation.horizontal,
        'vertical' => FoldOrientation.vertical,
        _ => FoldOrientation.unknown,
      },
      boundsPhysicalPixels: bounds,
      separating: value['separating'] == true,
      occlusion: value['occlusion'] == 'full' ? FoldOcclusion.full : FoldOcclusion.none,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FoldPostureState &&
      posture == other.posture &&
      orientation == other.orientation &&
      boundsPhysicalPixels == other.boundsPhysicalPixels &&
      separating == other.separating &&
      occlusion == other.occlusion;

  @override
  int get hashCode => Object.hash(posture, orientation, boundsPhysicalPixels, separating, occlusion);
}

/// Application-facing fold state. Consumers never need Android device checks.
class FoldPostureService {
  FoldPostureService({MethodChannel? channel}) : _channel = channel ?? platformChannel;

  static final FoldPostureService instance = FoldPostureService();

  @visibleForTesting
  static const MethodChannel platformChannel = MethodChannel('com.plezy/fold_posture');

  final MethodChannel _channel;
  final ValueNotifier<FoldPostureState> _state = ValueNotifier(const FoldPostureState.unsupported());
  bool _started = false;

  FoldPostureState get state => _state.value;
  ValueListenable<FoldPostureState> get listenable => _state;

  void ensureStarted() {
    if (_started || defaultTargetPlatform != TargetPlatform.android) return;
    _started = true;
    _state.value = const FoldPostureState.unknown();
    _channel.setMethodCallHandler(_handlePlatformCall);
    unawaited(_refresh());
  }

  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    if (call.method == 'onChanged' && call.arguments is Map) {
      _apply(FoldPostureState.fromMap(call.arguments as Map));
    }
    return null;
  }

  Future<void> _refresh() async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>('getState');
      if (result != null) _apply(FoldPostureState.fromMap(result));
    } on MissingPluginException {
      _apply(const FoldPostureState.unsupported());
    } on PlatformException catch (error, stackTrace) {
      appLogger.w('Failed to read fold posture', error: error, stackTrace: stackTrace);
      _apply(const FoldPostureState.unsupported());
    }
  }

  void _apply(FoldPostureState next) {
    if (_state.value == next) return;
    appLogger.i(
      'Fold posture: ${next.posture.name}, orientation=${next.orientation.name}, '
      'tabletop=${next.isTabletop}, bounds=${next.boundsPhysicalPixels}',
    );
    _state.value = next;
  }

  @visibleForTesting
  void debugReset() {
    _started = false;
    _state.value = const FoldPostureState.unsupported();
    _channel.setMethodCallHandler(null);
  }
}
