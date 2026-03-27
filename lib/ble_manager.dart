import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DataType { hex, ascii, utf8, decimal }

class LogEntry {
  final DateTime time;
  final String message;
  final LogType type;
  final String? data;
  LogEntry(this.message, this.type, {this.data}) : time = DateTime.now();
}

enum LogType {
  info,
  send,
  receive,
  error,
  success,
  notify,
}

class ConnectedDevice {
  final BluetoothDevice device;
  List<BluetoothService> services = [];
  BluetoothCharacteristic? selectedChar;
  BluetoothDescriptor? selectedDesc;
  bool isExpanded = false;
  String? error;
  int mtu = 23;
  ConnectedDevice(this.device);
  String get name => device.localName.isEmpty ? device.remoteId.str : device.localName;
}

class BleManager extends ChangeNotifier {
  bool isScanning = false;
  List<ScanResult> scanResults = [];
  Map<String, ConnectedDevice> connectedDevices = {};
  List<LogEntry> logs = [];
  DataType dataType = DataType.hex;
  bool autoReconnect = false;
  String scanFilter = '';

  // RSSI tracking
  Map<String, List<int>> rssiHistory = {};
  Timer? _rssiTimer;

  void addLog(String msg, LogType type, {String? data}) {
    logs.insert(0, LogEntry(msg, type, data: data));
    if (logs.length > 500) logs.removeLast();
    notifyListeners();
  }

  // ── Scan ──
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    scanResults.clear();
    isScanning = true;
    notifyListeners();
    addLog('开始扫描...', LogType.info);

    await FlutterBluePlus.startScan(timeout: timeout);
    FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });

    await Future.delayed(timeout);
    isScanning = false;
    addLog('扫描完成，发现 ${scanResults.length} 台设备', LogType.success);
    notifyListeners();
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    addLog('扫描已停止', LogType.info);
    notifyListeners();
  }

  void clearScanResults() {
    scanResults.clear();
    notifyListeners();
  }

  void setScanFilter(String filter) {
    scanFilter = filter.toLowerCase();
    notifyListeners();
  }

  List<ScanResult> get filteredResults {
    if (scanFilter.isEmpty) return scanResults;
    return scanResults.where((r) =>
      r.device.localName.toLowerCase().contains(scanFilter) ||
      r.device.remoteId.str.toLowerCase().contains(scanFilter)
    ).toList();
  }

  // ── Connect ──
  Future<bool> connect(BluetoothDevice device) async {
    final id = device.remoteId.str;
    if (connectedDevices.containsKey(id)) return true;

    addLog('连接 ${device.localName.isEmpty ? id : device.localName}...', LogType.info);
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      final mtu = await device.requestMtu(512);
      await Future.delayed(const Duration(milliseconds: 100));
      final services = await device.discoverServices();

      final cd = ConnectedDevice(device);
      cd.services = services;
      cd.mtu = mtu;
      connectedDevices[id] = cd;

      addLog('已连接，MTU=$mtu，${services.length} 个服务', LogType.success);

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          connectedDevices.remove(id);
          addLog('${cd.name} 已断开', LogType.error);
          notifyListeners();
          if (autoReconnect) {
            addLog('自动重连中...', LogType.info);
            Future.delayed(const Duration(seconds: 2), () => connect(device));
          }
        }
      });

      notifyListeners();
      return true;
    } catch (e) {
      addLog('连接失败: $e', LogType.error);
      return false;
    }
  }

  Future<void> disconnect(String id) async {
    final cd = connectedDevices[id];
    if (cd == null) return;
    addLog('断开 ${cd.name}', LogType.info);
    try {
      await cd.device.disconnect();
    } catch (e) {
      addLog('断开失败: $e', LogType.error);
    }
    connectedDevices.remove(id);
    notifyListeners();
  }

  Future<void> disconnectAll() async {
    for (final id in connectedDevices.keys.toList()) {
      await disconnect(id);
    }
  }

  // ── Read ──
  Future<void> readChar(String devId, BluetoothCharacteristic c) async {
    try {
      final data = await c.read();
      final hex = _formatData(data, DataType.hex);
      final txt = _formatData(data, DataType.utf8);
      addLog('[读取] ${c.uuid}\nHEX: $hex\nTXT: $txt', LogType.receive, data: hex);
    } catch (e) {
      addLog('[读取失败] ${c.uuid}: $e', LogType.error);
    }
  }

  // ── Write ──
  Future<void> writeChar(String devId, BluetoothCharacteristic c, String input, {bool withResponse = true}) async {
    if (input.isEmpty) return;
    try {
      List<int> data;
      if (RegExp(r'^([0-9a-fA-F]{2}[\s,]*)+$').hasMatch(input.trim())) {
        final h = input.replaceAll(RegExp(r'[\s,]'), '');
        data = List.generate(h.length ~/ 2, (i) => int.parse(h.substring(i * 2, i * 2 + 2), radix: 16));
      } else {
        data = input.codeUnits;
      }
      if (withResponse) {
        await c.write(data, withoutResponse: false);
      } else {
        await c.write(data, withoutResponse: true);
      }
      final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
      addLog('[写入${withResponse ? '' : ' NO RSP'}] ${c.uuid}\n$hex', LogType.send, data: hex);
    } catch (e) {
      addLog('[写入失败] ${c.uuid}: $e', LogType.error);
    }
  }

  // ── Notify ──
  Future<void> toggleNotify(String devId, BluetoothCharacteristic c) async {
    try {
      final shouldNotify = !c.isNotifying;
      await c.setNotifyValue(shouldNotify);
      if (shouldNotify) {
        c.onValueReceived.listen((data) {
          final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
          final txt = String.fromCharCodes(data);
          addLog('[通知] ${c.uuid}\nHEX: $hex\nTXT: $txt', LogType.notify, data: hex);
        });
        addLog('[已订阅通知] ${c.uuid}', LogType.success);
      } else {
        addLog('[已取消通知] ${c.uuid}', LogType.info);
      }
      notifyListeners();
    } catch (e) {
      addLog('[通知失败] ${c.uuid}: $e', LogType.error);
    }
  }

  // ── Descriptor Read/Write ──
  Future<void> readDesc(BluetoothDescriptor d) async {
    try {
      final data = await d.read();
      final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
      addLog('[读取描述符] ${d.uuid}: $hex', LogType.receive);
    } catch (e) {
      addLog('[描述符读取失败] $e', LogType.error);
    }
  }

  Future<void> writeDesc(BluetoothDescriptor d, String input) async {
    try {
      List<int> data;
      if (RegExp(r'^([0-9a-fA-F]{2}[\s,]*)+$').hasMatch(input.trim())) {
        final h = input.replaceAll(RegExp(r'[\s,]'), '');
        data = List.generate(h.length ~/ 2, (i) => int.parse(h.substring(i * 2, i * 2 + 2), radix: 16));
      } else {
        data = input.codeUnits;
      }
      await d.write(data);
      addLog('[写入描述符] ${d.uuid}: ${data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}', LogType.send);
    } catch (e) {
      addLog('[描述符写入失败] $e', LogType.error);
    }
  }

  // ── Data format ──
  String _formatData(List<int> data, DataType type) {
    switch (type) {
      case DataType.hex:
        return data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
      case DataType.ascii:
        return String.fromCharCodes(data.where((b) => b >= 32 && b <= 126));
      case DataType.utf8:
        return String.fromCharCodes(data);
      case DataType.decimal:
        return data.join(', ');
    }
  }

  String formatForDisplay(String? data) {
    if (data == null) return '';
    final bytes = <int>[];
    final hex = data.replaceAll(' ', '');
    for (int i = 0; i < hex.length; i += 2) {
      if (i + 2 <= hex.length) bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    switch (dataType) {
      case DataType.hex: return data;
      case DataType.ascii: return String.fromCharCodes(bytes.where((b) => b >= 32 && b <= 126));
      case DataType.utf8: return String.fromCharCodes(bytes);
      case DataType.decimal: return bytes.join(', ');
    }
  }

  void setDataType(DataType t) {
    dataType = t;
    notifyListeners();
  }

  void clearLogs() {
    logs.clear();
    notifyListeners();
  }

  void exportLogs() async {
    final lines = logs.map((l) {
      final t = l.type.toString().split('.').last.toUpperCase();
      return '[${l.time}] [$t] ${l.message}';
    }).toList().reversed.join('\n');
    // Save to clipboard
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('log_export', lines);
    addLog('日志已导出（${logs.length}条记录）', LogType.success);
  }
}
