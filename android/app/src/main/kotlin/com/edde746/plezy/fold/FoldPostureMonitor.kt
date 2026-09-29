package com.edde746.plezy.fold

import android.app.Activity
import android.util.Log
import androidx.window.layout.FoldingFeature
import androidx.window.layout.WindowInfoTracker
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

/** Lifecycle-bounded Jetpack WindowManager posture observer for the Flutter activity. */
internal class FoldPostureMonitor(
  private val activity: Activity,
  private val tracker: WindowInfoTracker = WindowInfoTracker.getOrCreate(activity)
) {
  private val scope = MainScope()
  private var collection: Job? = null
  private var onChanged: ((FoldPostureSnapshot) -> Unit)? = null

  var state: FoldPostureSnapshot = FoldPostureSnapshot.INITIAL
    private set

  fun start(onChanged: (FoldPostureSnapshot) -> Unit) {
    this.onChanged = onChanged
    if (collection != null) return
    collection = scope.launch {
      tracker.windowLayoutInfo(activity).collect { layoutInfo ->
        publish(
          foldPostureSnapshot(
            layoutInfo.displayFeatures.filterIsInstance<FoldingFeature>().map(::toSignal)
          )
        )
      }
    }
  }

  fun stop() {
    collection?.cancel()
    collection = null
  }

  fun release() {
    stop()
    onChanged = null
    scope.cancel()
  }

  private fun publish(next: FoldPostureSnapshot) {
    if (state == next) return
    state = next
    Log.i(
      TAG,
      "posture=${next.posture.wireName} orientation=${next.orientation.wireName} " +
        "tabletop=${next.isTabletop} separating=${next.separating} bounds=${next.bounds}"
    )
    onChanged?.invoke(next)
  }

  private fun toSignal(feature: FoldingFeature): FoldFeatureSignal = FoldFeatureSignal(
    posture = when (feature.state) {
      FoldingFeature.State.FLAT -> FoldPostureKind.FLAT
      FoldingFeature.State.HALF_OPENED -> FoldPostureKind.HALF_OPENED
      else -> FoldPostureKind.UNKNOWN
    },
    orientation = when (feature.orientation) {
      FoldingFeature.Orientation.HORIZONTAL -> FoldOrientation.HORIZONTAL
      FoldingFeature.Orientation.VERTICAL -> FoldOrientation.VERTICAL
      else -> FoldOrientation.UNKNOWN
    },
    bounds = FoldBounds(
      left = feature.bounds.left,
      top = feature.bounds.top,
      right = feature.bounds.right,
      bottom = feature.bounds.bottom
    ),
    separating = feature.isSeparating,
    occlusion = when (feature.occlusionType) {
      FoldingFeature.OcclusionType.FULL -> FoldOcclusion.FULL
      else -> FoldOcclusion.NONE
    }
  )

  private companion object {
    const val TAG = "PlezyFoldPosture"
  }
}
