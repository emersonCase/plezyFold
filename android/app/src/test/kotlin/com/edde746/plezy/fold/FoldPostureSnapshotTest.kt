package com.edde746.plezy.fold

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FoldPostureSnapshotTest {

  @Test
  fun noFoldingFeatureDegradesToUnsupported() {
    val snapshot = foldPostureSnapshot(emptyList())

    assertEquals(FoldPostureKind.UNSUPPORTED, snapshot.posture)
    assertEquals(FoldOrientation.UNKNOWN, snapshot.orientation)
    assertNull(snapshot.bounds)
    assertFalse(snapshot.isTabletop)
  }

  @Test
  fun flatFoldIsDistinguishedWithoutSelectingTabletop() {
    val snapshot = foldPostureSnapshot(
      listOf(signal(posture = FoldPostureKind.FLAT, orientation = FoldOrientation.VERTICAL))
    )

    assertEquals(FoldPostureKind.FLAT, snapshot.posture)
    assertEquals(FoldOrientation.VERTICAL, snapshot.orientation)
    assertFalse(snapshot.isTabletop)
  }

  @Test
  fun horizontalHalfOpenedFoldIsTabletop() {
    val snapshot = foldPostureSnapshot(
      listOf(signal(posture = FoldPostureKind.HALF_OPENED, orientation = FoldOrientation.HORIZONTAL))
    )

    assertEquals(FoldPostureKind.HALF_OPENED, snapshot.posture)
    assertTrue(snapshot.isTabletop)
    assertEquals(FoldBounds(0, 900, 1840, 940), snapshot.bounds)
  }

  @Test
  fun verticalHalfOpenedFoldIsNotTabletop() {
    val snapshot = foldPostureSnapshot(
      listOf(signal(posture = FoldPostureKind.HALF_OPENED, orientation = FoldOrientation.VERTICAL))
    )

    assertEquals(FoldPostureKind.HALF_OPENED, snapshot.posture)
    assertFalse(snapshot.isTabletop)
  }

  @Test
  fun halfOpenedFeatureWinsWhenPlatformReportsMultipleFolds() {
    val flat = signal(posture = FoldPostureKind.FLAT, orientation = FoldOrientation.VERTICAL)
    val halfOpened = signal(posture = FoldPostureKind.HALF_OPENED, orientation = FoldOrientation.HORIZONTAL)

    assertEquals(FoldPostureKind.HALF_OPENED, foldPostureSnapshot(listOf(flat, halfOpened)).posture)
  }

  @Test
  fun wirePayloadKeepsPhysicalGeometryAndOcclusion() {
    val snapshot = foldPostureSnapshot(
      listOf(
        signal(
          posture = FoldPostureKind.HALF_OPENED,
          orientation = FoldOrientation.HORIZONTAL,
          separating = true,
          occlusion = FoldOcclusion.FULL
        )
      )
    )

    assertEquals(
      mapOf("left" to 0, "top" to 900, "right" to 1840, "bottom" to 940),
      snapshot.toMap()["boundsPhysicalPixels"]
    )
    assertEquals(true, snapshot.toMap()["separating"])
    assertEquals("full", snapshot.toMap()["occlusion"])
  }

  private fun signal(
    posture: FoldPostureKind,
    orientation: FoldOrientation,
    separating: Boolean = true,
    occlusion: FoldOcclusion = FoldOcclusion.NONE
  ) = FoldFeatureSignal(
    posture = posture,
    orientation = orientation,
    bounds = FoldBounds(0, 900, 1840, 940),
    separating = separating,
    occlusion = occlusion
  )
}
