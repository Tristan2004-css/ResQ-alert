package com.example.flutter_application_1

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat

class FullScreenActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Simple programmatic fullscreen view to avoid R resource references while iterating
        val tv = TextView(this).apply {
            text = "Full Screen Alarm"
            textSize = 24f
            setPadding(40, 40, 40, 40)

            @Suppress("DEPRECATION")
            systemUiVisibility = (View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
        }

        setContentView(tv)

        // Forward extras to service if caller requested that
        val startServiceFlag = intent?.getBooleanExtra("startService", false) ?: false
        val title = intent?.getStringExtra(AlarmService.EXTRA_TITLE) ?: "Emergency"
        val body = intent?.getStringExtra(AlarmService.EXTRA_BODY) ?: ""

        if (startServiceFlag) {
            val startIntent: Intent = Intent(this, AlarmService::class.java).apply {
                putExtra(AlarmService.EXTRA_TITLE, title)
                putExtra(AlarmService.EXTRA_BODY, body)
            }
            ContextCompat.startForegroundService(this, startIntent)
        }
    }

    override fun onResume() {
        super.onResume()
        // re-apply fullscreen flags
        window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
    }
}
