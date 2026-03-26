import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleProvider extends ChangeNotifier {
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];
  BluetoothCharacteristic? selectedChar;
  List<String> logs = [];
  bool isScanning = false;
  bool isConnecting = false;
  StreamSubscription? _scanSub;

  void addLog(String msg) {
    final time = TimeOfDay.now().format(const _FakeContext());
    logs.insert(0, '[$time] $msg');
    if (logs.length > 100) logs.removeLast();
    notifyListeners();
  }

  Future<void> startScan() async {
    scanResults.clear();
    isScanning = true;
    notifyListeners();
    addLog('开始扫描...');
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });
    await Future.delayed(const Duration(seconds: 8));
    isScanning = false;
    addLog('扫描完成，发现 ${scanResults.length} 台设备');
    notifyListeners();
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  Future<void> connect(BluetoothDevice device) async {
    isConnecting = true;
    notifyListeners();
    addLog('正在连接 ${device.platformName}...');
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      connectedDevice = device;
      services = await device.discoverServices();
      addLog('连接成功，发现 ${services.length} 个服务');
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          connectedDevice = null;
          services = [];
          selectedChar = null;
          addLog('设备已断开');
          notifyListeners();
        }
      });
    } catch (e) {
      addLog('连接失败: $e');
    }
    isConnecting = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await connectedDevice?.disconnect();
    connectedDevice = null;
    services = [];
    selectedChar = null;
    addLog('已断开连接');
    notifyListeners();
  }

  void selectChar(BluetoothCharacteristic char) {
    selectedChar = char;
    addLog('已选择特征值: ${char.uuid}');
    notifyListeners();
  }

  Future<void> readChar() async {
    if (selectedChar == null) return;
    try {
      final data = await selectedChar!.read();
      final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      final txt = String.fromCharCodes(data);
      addLog('[读取] HEX: $hex');
      addLog('[读取] TXT: $txt');
    } catch (e) {
      addLog('[错误] 读取失败: $e');
    }
  }

  Future<void> writeChar(String input) async {
    if (selectedChar == null) return;
    try {
      List<int> data;
      final hexReg = RegExp(r'^([0-9a-fA-F]{2}\s*)+$');
      if (hexReg.hasMatch(input.trim())) {
        final hex = input.replaceAll(' ', '');
        data = List.generate(hex.length ~/ 2,
            (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16));
        addLog('[发送 HEX] $input');
      } else {
        data = input.codeUnits;
        addLog('[发送 TXT] $input');
      }
      await selectedChar!.write(data);
      addLog('发送成功 ✓');
    } catch (e) {
      addLog('[错误] 发送失败: $e');
    }
  }

  Future<void> subscribeNotify() async {
    if (selectedChar == null) return;
    try {
      await selectedChar!.setNotifyValue(true);
      selectedChar!.onValueReceived.listen((data) {
        final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
        final txt = String.fromCharCodes(data);
        addLog('[通知] HEX: $hex | TXT: $txt');
      });
      addLog('[订阅] 已订阅通知: ${selectedChar!.uuid}');
    } catch (e) {
      addLog('[错误] 订阅失败: $e');
    }
  }
}

class _FakeContext implements BuildContext {
  const _FakeContext();
  @override
  dynamic noSuchMethod(Invocation i) => '';
}