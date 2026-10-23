package com.example.gemstone

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.PowerManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/// What the 3D simulators adapt their rendering to: how much memory this
/// app may use on this device, how much is free, and how hot it runs.
/// Nothing here is a fixed device class; the OS reports its own limits.
object DevicePerfChannel {
    private const val NAME = "gemworld/device_perf"

    fun register(messenger: BinaryMessenger, context: Context) {
        val app = context.applicationContext
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "snapshot" -> result.success(snapshot(app))
                else -> result.notImplemented()
            }
        }
    }

    private fun snapshot(context: Context): Map<String, Any?> {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo().also { am.getMemoryInfo(it) }
        val out = mutableMapOf<String, Any?>(
            "appMemoryBytes" to am.memoryClass.toLong() * 1024L * 1024L,
            "availableBytes" to info.availMem,
            "totalBytes" to info.totalMem,
            "lowMemory" to (info.lowMemory || am.isLowRamDevice),
        )
        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        if (pm != null) {
            out["powerSaving"] = pm.isPowerSaveMode
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // THERMAL_STATUS_NONE (0) .. THERMAL_STATUS_SHUTDOWN (6).
                out["thermalStatus"] = pm.currentThermalStatus
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // 1.0 is where the device starts throttling hard; NaN when
                // asked too often or unsupported.
                val headroom = pm.getThermalHeadroom(10)
                if (!headroom.isNaN()) out["thermalHeadroom"] = headroom.toDouble()
            }
        }
        return out
    }
}
