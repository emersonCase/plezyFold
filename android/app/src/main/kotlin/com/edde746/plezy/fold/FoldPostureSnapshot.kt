package com.edde746.plezy.fold

internal enum class FoldPostureKind(val wireName: String) {
  UNKNOWN("unknown"),
  UNSUPPORTED("unsupported"),
  FLAT("flat"),
  HALF_OPENED("halfOpened")
}

internal enum class FoldOrientation(val wireName: String) {
  UNKNOWN("unknown"),
  HORIZONTAL("horizontal"),
  VERTICAL("vertical")
}

internal enum class FoldOcclusion(val wireName: String) {
  NONE("none"),
  FULL("full")
}

internal data class FoldBounds(
  val left: Int,
  val top: Int,
  val right: Int,
  val bottom: Int
) {
  fun toMap(): Map<String, Int> = mapOf(
    "left" to left,
    "top" to top,
    "right" to right,
    "bottom" to bottom
  )
}

internal data class FoldFeatureSignal(
  val posture: FoldPostureKind,
  val orientation: FoldOrientation,
  val bounds: FoldBounds,
  val separating: Boolean,
  val occlusion: FoldOcclusion
)

internal data class FoldPostureSnapshot(
  val posture: FoldPostureKind,
  val orientation: FoldOrientation = FoldOrientation.UNKNOWN,
  val bounds: FoldBounds? = null,
  val separating: Boolean = false,
  val occlusion: FoldOcclusion = FoldOcclusion.NONE
) {
  val isTabletop: Boolean
    get() = posture == FoldPostureKind.HALF_OPENED && orientation == FoldOrientation.HORIZONTAL

  fun toMap(): Map<String, Any?> = mapOf(
    "posture" to posture.wireName,
    "orientation" to orientation.wireName,
    "boundsPhysicalPixels" to bounds?.toMap(),
    "separating" to separating,
    "occlusion" to occlusion.wireName,
    "isTabletop" to isTabletop
  )

  companion object {
    val INITIAL = FoldPostureSnapshot(FoldPostureKind.UNKNOWN)
    val UNSUPPORTED = FoldPostureSnapshot(FoldPostureKind.UNSUPPORTED)
  }
}

/**
 * Reduces WindowManager's display-feature list to the one fold posture Plezy consumes.
 *
 * A half-opened feature wins if a platform reports more than one feature. Otherwise a
 * separating feature wins, then the first fold. An empty list is the ordinary-device
 * fallback and deliberately carries no synthetic hinge geometry.
 */
internal fun foldPostureSnapshot(features: List<FoldFeatureSignal>): FoldPostureSnapshot {
  val feature = features.firstOrNull { it.posture == FoldPostureKind.HALF_OPENED }
    ?: features.firstOrNull { it.separating }
    ?: features.firstOrNull()
    ?: return FoldPostureSnapshot.UNSUPPORTED

  return FoldPostureSnapshot(
    posture = feature.posture,
    orientation = feature.orientation,
    bounds = feature.bounds,
    separating = feature.separating,
    occlusion = feature.occlusion
  )
}
