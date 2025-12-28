import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    _askPermissions();
    _listenSms();
  }

  Future<void> _askPermissions() async {
    await Permission.sms.request();
  }

  void _listenSms() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onSmsReceived") {
        final msg = call.arguments.toString();
        setState(() => lastSms = msg);

        // GF-07 simple parser example
        final parsed = _parseGps(msg);
        if (parsed != null) {
          setState(() {
            lat = parsed['lat']!;
            lng = parsed['lng']!;
          });

          // Send to Node.js API
          await _sendToServer(parsed['lat']!, parsed['lng']!);
        }
      }
    });
  }

  Map<String, String>? _parseGps(String sms) {
    // Example GF-07 text often contains: lat:31.5204 lng:74.3587
    final latMatch = RegExp(r'lat[:=]\s*([0-9.+-]+)').firstMatch(sms);
    final lngMatch = RegExp(r'lng[:=]\s*([0-9.+-]+)').firstMatch(sms);
    if (latMatch != null && lngMatch != null) {
      return {
        'lat': latMatch.group(1)!,
        'lng': lngMatch.group(1)!,
      };
    }
    return null;
  }

  Future<void> _sendToServer(String lat, String lng) async {
    try {
      await http.post(
        Uri.parse('https://YOUR_NODE_API/api/location/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'busId': 'UET-01',
          'lat': lat,
          'lng': lng,
        }),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("SMS GPS Tracker")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Last SMS:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(lastSms),
              const SizedBox(height: 16),
              Text("Latitude: $lat"),
              Text("Longitude: $lng"),
            ],
          ),
        ),
      ),
    );
  }
}
