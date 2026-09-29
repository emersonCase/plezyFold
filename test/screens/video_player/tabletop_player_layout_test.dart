import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/video_player/tabletop_player_layout.dart';
import 'package:plezy/services/fold_posture_service.dart';

void main() {
  const viewport = Size(1076, 1038);
  const tabletop = FoldPostureState(
    posture: FoldPosture.halfOpened,
    orientation: FoldOrientation.horizontal,
    boundsPhysicalPixels: Rect.fromLTRB(0, 1038, 2152, 1038),
    separating: true,
  );

  test('tabletop places video above the physical fold and controls below it', () {
    final layout = TabletopPlayerLayout.resolve(posture: tabletop, viewport: viewport, devicePixelRatio: 2);

    expect(layout, isNotNull);
    expect(layout!.videoRect, const Rect.fromLTRB(0, 0, 1076, 519));
    expect(layout.controlsRect, const Rect.fromLTRB(0, 519, 1076, 1038));
  });

  test('flat and vertical half-open postures keep the ordinary player layout', () {
    const flat = FoldPostureState(
      posture: FoldPosture.flat,
      orientation: FoldOrientation.horizontal,
      boundsPhysicalPixels: Rect.fromLTRB(0, 1038, 2152, 1038),
    );
    const book = FoldPostureState(
      posture: FoldPosture.halfOpened,
      orientation: FoldOrientation.vertical,
      boundsPhysicalPixels: Rect.fromLTRB(1038, 0, 1038, 2152),
      separating: true,
    );

    expect(TabletopPlayerLayout.resolve(posture: flat, viewport: viewport, devicePixelRatio: 2), isNull);
    expect(TabletopPlayerLayout.resolve(posture: book, viewport: viewport, devicePixelRatio: 2), isNull);
  });

  test('missing or out-of-window hinge geometry falls back safely', () {
    const missingBounds = FoldPostureState(
      posture: FoldPosture.halfOpened,
      orientation: FoldOrientation.horizontal,
      separating: true,
    );
    const outsideViewport = FoldPostureState(
      posture: FoldPosture.halfOpened,
      orientation: FoldOrientation.horizontal,
      boundsPhysicalPixels: Rect.fromLTRB(0, 2200, 2152, 2200),
      separating: true,
    );

    expect(TabletopPlayerLayout.resolve(posture: missingBounds, viewport: viewport, devicePixelRatio: 2), isNull);
    expect(TabletopPlayerLayout.resolve(posture: outsideViewport, viewport: viewport, devicePixelRatio: 2), isNull);
  });
}
