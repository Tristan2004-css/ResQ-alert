package com.example.flutter_application_1

import android.content.Intent
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.util.Log

class MyFirebaseMessagingService : FirebaseMessagingService() {
    private val TAG = "MyFirebaseMsgService"

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        try {
            val data = remoteMessage.data
            if (data.isNullOrEmpty()) {
                Log.d(TAG, "Received message with no data payload")
                return
            }

            // Extract fields (server should send these keys)
            val title = data["title"] ?: "Emergency Alert"
            val body = data["body"] ?: ""
            val alertType = data["type"] ?: "emergency"

            val intent = Intent(this, OverlayService::class.java).apply {
                putExtra("title", title)
                putExtra("body", body)
                putExtra("type", alertType)
            }

            // Start foreground service so overlay can be shown when app backgrounded
            ContextCompat.startForegroundService(this, intent)
        } catch (e: Exception) {
            Log.e(TAG, "onMessageReceived error", e)
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // TODO: send token to server if needed
    }
}
