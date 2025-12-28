package com.example.sms_gps_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.telephony.SmsMessage
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "sms_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val bundle = intent?.extras ?: return
                val pdus = bundle["pdus"] as Array<*>

                for (pdu in pdus) {
                    val msg = SmsMessage.createFromPdu(pdu as ByteArray)
                    MethodChannel(
                        flutterEngine!!.dartExecutor.binaryMessenger,
                        CHANNEL
                    ).invokeMethod("onSmsReceived", msg.messageBody)
                }
            }
        }

        registerReceiver(
            receiver,
            IntentFilter("android.provider.Telephony.SMS_RECEIVED")
        )
    }
}
