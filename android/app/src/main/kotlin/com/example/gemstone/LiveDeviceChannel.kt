package com.example.gemstone

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.telephony.TelephonyManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/// What a live show's visit record needs that no plugin here gives: the
/// battery (battery_plus clashes with wakelock_plus) and the SIM operator.
/// Neither needs a permission.
object LiveDeviceChannel {
    private const val NAME = "gemworld/live_device"

    fun register(messenger: BinaryMessenger, context: Context) {
        val app = context.applicationContext
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "battery" -> result.success(battery(app))
                "simOperatorName" -> result.success(simOperatorName(app))
                else -> result.notImplemented()
            }
        }
    }

    private fun battery(context: Context): Map<String, Any?> {
        // Sticky broadcast: returns the last state without a receiver.
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            ?: return emptyMap()
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        return mapOf(
            "level" to if (level >= 0 && scale > 0) level * 100 / scale else null,
            "charging" to (status == BatteryManager.BATTERY_STATUS_CHARGING),
        )
    }

    private fun simOperatorName(context: Context): String? {
        val telephony = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        return telephony?.simOperatorName?.takeIf { it.isNotBlank() }
    }
}
