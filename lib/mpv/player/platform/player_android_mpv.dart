import '../player_native.dart';
import '../video_rect_support.dart';

/// Default Android mpv player with a native surface that follows Flutter's
/// video bounds, including the upper pane of a tabletop foldable.
class PlayerAndroidMpv extends PlayerNative with NativeVideoRectSupport {
  PlayerAndroidMpv({super.hardwareDecoding});
}
