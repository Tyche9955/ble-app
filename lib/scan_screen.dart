import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'ble_provider.dart';
import 'device_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('🔵 BLE 扫描', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text('${ble.scanResults.length} 台设备',
                style: const TextStyle(color: Colors.grey)),
          )
        ],
      ),
      body: Column(
        children: [
          // 扫描按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ble.isScanning
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (ble.isScanning) {
                    ble.stopScan();
                  } else {
                    await _requestPermissions();
                    ble.startScan();
                  }
                },
                icon: ble.isScanning
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search, color: Colors.white),
                label: Text(
                  ble.isScanning ? '停止扫描' : '开始扫描',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          // 设备列表
          Expanded(
            child: ble.scanResults.isEmpty
                ? Center(
                    child: Text(
                      ble.isScanning ? '扫描中，请稍候...' : '点击上方按钮开始扫描',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ble.scanResults.length,
                    itemBuilder: (ctx, i) {
                      final r = ble.scanResults[i];
                      final name = r.device.platformName.isEmpty
                          ? '(未知设备)'
                          : r.device.platformName;
                      return Card(
                        color: const Color(0xFF1E1E3A),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(name,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text(r.device.remoteId.str,
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${r.rssi}',
                                  style: const TextStyle(
                                      color: Color(0xFF818CF8),
                                      fontWeight: FontWeight.bold)),
                              const Text('dBm',
                                  style: TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                          onTap: () async {
                            if (ble.isConnecting) return;
                            await ble.connect(r.device);
                            if (ble.connectedDevice != null && ctx.mounted) {
                              Navigator.push(ctx, MaterialPageRoute(
                                  builder: (_) => const DeviceScreen()));
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}