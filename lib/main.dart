import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ble_manager.dart';
import 'scan_screen.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => BleManager(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nRF BLE Tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00A9CE),
          secondary: Color(0xFF00A9CE),
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), elevation: 0),
        cardTheme: CardTheme(color: const Color(0xFF1E1E1E), elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
        ),
      ),
      home: const ScanScreen(),
    );
  }
}
