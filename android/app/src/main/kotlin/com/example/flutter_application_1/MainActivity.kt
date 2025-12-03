package com.example.flutter_application_1

import android.content.Intent
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "resq_alert/emergency"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startEmergency" -> {
                    val title = call.argument<String>("title") ?: "Emergency"
                    val body = call.argument<String>("body") ?: ""
                    startEmergencyService(title, body)
                    result.success(true)
                }
                "stopEmergency" -> {
                    stopEmergencyService()
                    result.success(true)
                }
                "openDndSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_DND_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startEmergencyService(title: String, body: String) {
        val intent = Intent(this, AlarmService::class.java).apply {
            putExtra(AlarmService.EXTRA_TITLE, title)
            putExtra(AlarmService.EXTRA_BODY, body)
        }
        ContextCompat.startForegroundService(this, intent)
    }

    private fun stopEmergencyService() {
        val intent = Intent(this, AlarmService::class.java)
        stopService(intent)
    }
}
