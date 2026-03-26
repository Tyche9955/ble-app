import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ble_provider.dart';
import 'scan_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE 调试工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ScanScreen(),
    );
  }
}