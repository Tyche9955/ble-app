import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'car_manager.dart';
import 'scan_screen.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => CarManager(), child: const CarApp()));
}

class CarApp extends StatelessWidget {
  const CarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE 灏忚溅鎺у埗',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE94560),
          secondary: Color(0xFF0F3460),
          surface: Color(0xFF16213E),
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF16213E)),
      ),
      home: const ScanScreen(),
    );
  }
}
