import 'dart:async';

import '../models.dart';
import 'player_native.dart';

/// A player whose video lives in a native surface behind the Flutter window
/// and must be told where Flutter laid out the picture.
abstract interface class VideoRectSupport {
  StreamController<PlayerError> get errorController;

  Future<void> setVideoRect({
    required int left,
    required int top,
    required int right,
    required int bottom,
    required double devicePixelRatio,
  });
}

/// Shared bridge for the desktop [PlayerNative] implementations.
mixin NativeVideoRectSupport on PlayerNative implements VideoRectSupport {
  @override
  Future<void> setVideoRect({
    required int left,
    required int top,
    required int right,
    required int bottom,
    required double devicePixelRatio,
  }) async {
    await invoke('setVideoRect', {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
      'devicePixelRatio': devicePixelRatio,
    });
  }
}
