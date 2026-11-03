package com.example.achievia

import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth (biometric prompt) needs a FragmentActivity.
class MainActivity : FlutterFragmentActivity() {
    private var ringtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Short alert for the Sleep Time Reminder. It uses the default
        // notification sound on the notification stream, so the device's
        // volume, silent mode and Do Not Disturb settings are respected.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "achievia/alert_sound")
            .setMethodCallHandler { call, result ->
                if (call.method == "playNotification") {
                    try {
                        ringtone?.stop()
                        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                        val tone = RingtoneManager.getRingtone(applicationContext, uri)
                        tone?.audioAttributes = AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                        tone?.play()
                        ringtone = tone
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("alert_sound", e.message, null)
                    }
                } else if (call.method == "playAnswerTone") {
                    // Positive double beep for a correct answer, a lower
                    // error tone for an incorrect one, on the media volume.
                    try {
                        val correct = call.argument<Boolean>("correct") ?: true
                        val generator = ToneGenerator(AudioManager.STREAM_MUSIC, 80)
                        val tone = if (correct) ToneGenerator.TONE_PROP_BEEP2 else ToneGenerator.TONE_PROP_NACK
                        val ms = if (correct) 200 else 350
                        generator.startTone(tone, ms)
                        Handler(Looper.getMainLooper()).postDelayed({ generator.release() }, ms + 250L)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("answer_tone", e.message, null)
                    }
                } else if (call.method == "vibrate") {
                    try {
                        val ms = (call.argument<Int>("ms") ?: 250).toLong()
                        val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            (getSystemService(VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
                        } else {
                            @Suppress("DEPRECATION")
                            getSystemService(VIBRATOR_SERVICE) as Vibrator
                        }
                        if (vibrator != null && vibrator.hasVibrator()) {
                            vibrator.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("vibrate", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        ringtone?.stop()
        ringtone = null
        super.onDestroy()
    }
}
