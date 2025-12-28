package com.example.sms_gps_tracker;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.telephony.SmsMessage;
import io.flutter.plugin.common.MethodChannel;

public class SmsReceiver extends BroadcastReceiver {

    public static MethodChannel channel;

    @Override
    public void onReceive(Context context, Intent intent) {

        Bundle bundle = intent.getExtras();
        if (bundle == null) return;

        Object[] pdus = (Object[]) bundle.get("pdus");
        if (pdus == null) return;

        String format = bundle.getString("format");

        for (Object pdu : pdus) {
            SmsMessage sms;
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                sms = SmsMessage.createFromPdu((byte[]) pdu, format);
            } else {
                sms = SmsMessage.createFromPdu((byte[]) pdu);
            }

            String sender = sms.getOriginatingAddress();
            String message = sms.getMessageBody();

            if (channel != null) {
                channel.invokeMethod(
                    "onSmsReceived",
                    sender + "|" + message
                );
            }
        }
    }
}
