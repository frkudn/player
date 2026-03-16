package com.furqanuddin.player

import android.content.Context
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.Virtualizer
import android.os.Build
import android.os.Environment
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    // ── Channel names ────────────────────────────────────────────────────────
    private val EQ_CHANNEL      = "com.furqanuddin.player/equalizer"
    private val STORAGE_CHANNEL = "com.furqanuddin.player/storage"

    // ── Equalizer instances ──────────────────────────────────────────────────
    private var equalizer:   Equalizer?   = null
    private var bassBoost:   BassBoost?   = null
    private var virtualizer: Virtualizer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ════════════════════════════════════════════════════════════════════
        //  EQUALIZER CHANNEL
        // ════════════════════════════════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EQ_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "init" -> {
                        val audioSessionId = call.argument<Int>("audioSessionId") ?: 0
                        try {
                            equalizer   = Equalizer(0, audioSessionId).apply { enabled = true }
                            bassBoost   = BassBoost(0, audioSessionId).apply { enabled = true }
                            virtualizer = Virtualizer(0, audioSessionId).apply { enabled = true }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INIT_FAILED", e.message, null)
                        }
                    }

                    "getNumberOfBands" -> {
                        result.success(equalizer?.numberOfBands?.toInt() ?: 0)
                    }

                    "getBandFreqRange" -> {
                        val band  = call.argument<Int>("band") ?: 0
                        val range = equalizer?.getBandFreqRange(band.toShort())
                        result.success(range?.toList())
                    }

                    "getBandLevel" -> {
                        val band = call.argument<Int>("band") ?: 0
                        result.success(
                            equalizer?.getBandLevel(band.toShort())?.toInt() ?: 0
                        )
                    }

                    "setBandLevel" -> {
                        val band  = call.argument<Int>("band")  ?: 0
                        val level = call.argument<Int>("level") ?: 0
                        equalizer?.setBandLevel(band.toShort(), level.toShort())
                        result.success(true)
                    }

                    "getBandLevelRange" -> {
                        val range = equalizer?.bandLevelRange
                        result.success(range?.map { it.toInt() })
                    }

                    "getNumberOfPresets" -> {
                        result.success(equalizer?.numberOfPresets?.toInt() ?: 0)
                    }

                    "getPresetName" -> {
                        val preset = call.argument<Int>("preset") ?: 0
                        result.success(
                            equalizer?.getPresetName(preset.toShort()) ?: ""
                        )
                    }

                    "usePreset" -> {
                        val preset = call.argument<Int>("preset") ?: 0
                        equalizer?.usePreset(preset.toShort())
                        result.success(true)
                    }

                    "setBassBoost" -> {
                        val strength = call.argument<Int>("strength") ?: 0
                        bassBoost?.setStrength(strength.toShort())
                        result.success(true)
                    }

                    "setVirtualizer" -> {
                        val strength = call.argument<Int>("strength") ?: 0
                        virtualizer?.setStrength(strength.toShort())
                        result.success(true)
                    }

                    "setEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        equalizer?.enabled   = enabled
                        bassBoost?.enabled   = enabled
                        virtualizer?.enabled = enabled
                        result.success(true)
                    }

                    "release" -> {
                        equalizer?.release()
                        bassBoost?.release()
                        virtualizer?.release()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════════════════════════════════
        //  STORAGE CHANNEL
        // ════════════════════════════════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "getStorageDirectories" -> {
                        try {
                            result.success(getStorageDirectories())
                        } catch (e: Exception) {
                            result.error(
                                "STORAGE_ERROR",
                                "Failed to get storage directories: ${e.message}",
                                null
                            )
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ════════════════════════════════════════════════════════════════════════
    //  STORAGE HELPERS
    // ════════════════════════════════════════════════════════════════════════

    private fun getStorageDirectories(): List<String> {
        val paths = mutableListOf<String>()

        try {
            val storageManager =
                getSystemService(Context.STORAGE_SERVICE) as StorageManager

            val volumes: List<StorageVolume> = storageManager.storageVolumes

            for (volume in volumes) {
                val volumePath = getVolumePath(volume) ?: continue
                val dir        = File(volumePath)

                if (!dir.exists()) continue

                paths.add(volumePath)

                if (volume.isRemovable) {
                    android.util.Log.i(
                        "Storage", "Removable (SD card): $volumePath")
                } else {
                    android.util.Log.i(
                        "Storage", "Internal storage: $volumePath")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e(
                "Storage", "Error getting storage volumes: ${e.message}")
        }

        // ── Fallback: always include internal storage ────────────────────
        val internal = Environment.getExternalStorageDirectory()?.absolutePath
        if (internal != null &&
            paths.none { it == internal }) {
            paths.add(internal)
        }

        return paths.distinct()
    }

    private fun getVolumePath(volume: StorageVolume): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Android 12+ — public API, no reflection needed
                volume.directory?.absolutePath
            } else {
                // Android 7–11 — use reflection
                val method = StorageVolume::class.java
                    .getDeclaredMethod("getPath")
                method.isAccessible = true
                method.invoke(volume) as? String
            }
        } catch (e: Exception) {
            android.util.Log.w(
                "Storage",
                "Could not get path for volume '${volume.getDescription(this)}': ${e.message}"
            )
            null
        }
    }
}