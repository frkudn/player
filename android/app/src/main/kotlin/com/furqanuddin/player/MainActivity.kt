// android/app/src/main/kotlin/com/yourpackage/MainActivity.kt
package com.furqanuddin.player

import android.media.audiofx.Equalizer
import android.media.audiofx.BassBoost
import android.media.audiofx.Virtualizer
import android.media.audiofx.PresetReverb
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.furqanuddin.player/equalizer"
    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
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
                        val band = call.argument<Int>("band") ?: 0
                        val range = equalizer?.getBandFreqRange(band.toShort())
                        result.success(range?.toList())
                    }

                    "getBandLevel" -> {
                        val band = call.argument<Int>("band") ?: 0
                        result.success(equalizer?.getBandLevel(band.toShort())?.toInt() ?: 0)
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
                        result.success(equalizer?.getPresetName(preset.toShort()) ?: "")
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
    }
}