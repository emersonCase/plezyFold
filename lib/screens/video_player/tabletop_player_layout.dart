import 'dart:ui';

import '../../services/fold_posture_service.dart';

/// Geometry for the fold-aware player. A null result means the ordinary
/// full-screen player layout must remain untouched.
class TabletopPlayerLayout {
  const TabletopPlayerLayout({required this.videoRect, required this.controlsRect});

  final Rect videoRect;
  final Rect controlsRect;

  static TabletopPlayerLayout? resolve({
    required FoldPostureState posture,
    required Size viewport,
    required double devicePixelRatio,
  }) {
    final hinge = posture.boundsPhysicalPixels;
    if (!posture.isTabletop || hinge == null || devicePixelRatio <= 0 || viewport.isEmpty) return null;

    final hingeTop = hinge.top / devicePixelRatio;
    final hingeBottom = hinge.bottom / devicePixelRatio;
    if (!hingeTop.isFinite || !hingeBottom.isFinite || hingeTop <= 0 || hingeBottom < hingeTop) return null;
    if (hingeBottom >= viewport.height) return null;

    return TabletopPlayerLayout(
      videoRect: Rect.fromLTRB(0, 0, viewport.width, hingeTop),
      controlsRect: Rect.fromLTRB(0, hingeBottom, viewport.width, viewport.height),
    );
  }
}
