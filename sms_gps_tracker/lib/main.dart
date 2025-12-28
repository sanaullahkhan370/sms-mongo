import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const MethodChannel _channel = MethodChannel('sms_channel');

  String lastSms = "No SMS yet";
  String lat = "-";
  String lng = "-";
  String status = "Waiting...";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Permission.sms.request();
    _listenSms();
    print("🔥 SMS APP STARTED");
  }

  void _listenSms() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onSmsReceived") {
        final sms = call.arguments.toString();
        print("📩 SMS RECEIVED: $sms");

        setState(() => lastSms = sms);

        final parsed = _parseGps(sms);
        if (parsed != null) {
          setState(() {
            lat = parsed['lat']!;
            lng = parsed['lng']!;
          });

          await _sendToServer(lat, lng);
        }
      }
    });
  }

  // 🔥 UPDATED GPS PARSER (GF-07 + Google Maps)
  Map<String, String>? _parseGps(String sms) {

    // Format 1: lat:31.69 lng:74.24
    final latMatch = RegExp(r'lat[:=]\s*([0-9.+-]+)').firstMatch(sms);
    final lngMatch = RegExp(r'lng[:=]\s*([0-9.+-]+)').firstMatch(sms);

    if (latMatch != null && lngMatch != null) {
      return {
        'lat': latMatch.group(1)!,
        'lng': lngMatch.group(1)!,
      };
    }

    // Format 2: Google Maps link
    // http://maps.google.com/?q=31.7007450,74.2532420
    final mapMatch = RegExp(r'q=([0-9.+-]+),([0-9.+-]+)').firstMatch(sms);
    if (mapMatch != null) {
      return {
        'lat': mapMatch.group(1)!,
        'lng': mapMatch.group(2)!,
      };
    }

    return null;
  }

  Future<void> _sendToServer(String lat, String lng) async {
    try {
      setState(() => status = "Sending to server...");
      await http.post(
        Uri.parse("http://10.75.32.20:5000/api/location/update"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "busId": "UET-021",
          "lat": lat,
          "lng": lng,
        }),
      );
      setState(() => status = "✅ Sent to MongoDB");
    } catch (e) {
      setState(() => status = "❌ Error sending");
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("SMS → MongoDB Tracker")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Status: $status"),
              const SizedBox(height: 10),
              const Text("Last SMS:"),
              Text(lastSms),
              const SizedBox(height: 10),
              Text("Latitude: $lat"),
              Text("Longitude: $lng"),
            ],
          ),
        ),
      ),
    );
  }
}
