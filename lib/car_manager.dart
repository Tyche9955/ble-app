import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum Direction { stop, forward, backward, left, right }
enum LedState { off, on }

class CarManager extends ChangeNotifier {
  bool isScanning = false;
  bool isConnected = false;
  BluetoothDevice? device;
  BluetoothCharacteristic? txChar; // 鍙戦€佹寚浠?  BluetoothCharacteristic? rxChar; // 鎺ユ敹鏁版嵁
  List<ScanResult> devices = [];
  Direction direction = Direction.stop;
  int speed = 50; // 0-100
  LedState led = LedState.off;
  List<String> logs = [];
  String? errorMsg;
  String txUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // Nordic UART TX
  String rxUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // Nordic UART RX

  void addLog(String msg) {
    final t = DateTime.now().toString().substring(11, 19);
    logs.insert(0, '[$t] $msg');
    if (logs.length > 100) logs.removeLast();
    notifyListeners();
  }

  Future<void> startScan() async {
    devices.clear();
    isScanning = true;
    notifyListeners();
    addLog('寮€濮嬫壂鎻?..');

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    FlutterBluePlus.scanResults.listen((r) {
      devices = r;
      notifyListeners();
    });
    await Future.delayed(const Duration(seconds: 10));
    isScanning = false;
    addLog('鎵弿瀹屾垚锛屽彂鐜?${devices.length} 鍙拌澶?);
    notifyListeners();
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    addLog('鎵弿宸插仠姝?);
    notifyListeners();
  }

  Future<bool> connect(BluetoothDevice d) async {
    try {
      addLog('杩炴帴 ${d.localName}...');
      await d.connect(timeout: const Duration(seconds: 15));
      device = d;
      isConnected = true;
      addLog('杩炴帴鎴愬姛锛?);
      _discoverServices();
      d.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          isConnected = false;
          txChar = null; rxChar = null;
          direction = Direction.stop;
          led = LedState.off;
          addLog('杩炴帴宸叉柇寮€');
          notifyListeners();
        }
      });
      notifyListeners();
      return true;
    } catch (e) {
      addLog('杩炴帴澶辫触: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> _discoverServices() async {
    try {
      final svcs = await device!.discoverServices();
      for (final svc in svcs) {
        for (final c in svc.characteristics) {
          // 鏀寔澶氱 UART 鐗瑰緛鍊?UUID
          final u = c.uuid.toString().toLowerCase();
          if (u.contains('002') || u.contains('003') ||
              u.contains('ffe1') || u.contains('ffe2') ||
              u.contains('aa02') || u.contains('aa03')) {
            if (u.contains('002') || u.contains('ffe1') || u.contains('aa02')) {
              txChar = c;
              addLog('鍙戦€佺壒寰? ${c.uuid}');
            }
            if (u.contains('003') || u.contains('ffe2') || u.contains('aa03')) {
              rxChar = c;
              await c.setNotifyValue(true);
              c.onValueReceived.listen((d) {
                addLog('鏀跺埌: ${d.map((b)=>b.toRadixString(16).padLeft(2,"0")).join(" ")}');
              });
              addLog('鎺ユ敹鐗瑰緛: ${c.uuid}');
            }
          }
        }
      }
      if (txChar == null) {
        addLog('鏈壘鍒癠ART鐗瑰緛锛岃嚜鍔ㄦā寮忓凡鍚敤');
        addLog('璇峰湪璁剧疆涓墜鍔ㄩ€夋嫨鐗瑰緛鍊?);
      }
      notifyListeners();
    } catch (e) {
      addLog('鍙戠幇鏈嶅姟澶辫触: $e');
    }
  }

  Future<void> disconnect() async {
    if (device == null) return;
    await device!.disconnect();
    isConnected = false;
    txChar = null; rxChar = null;
    direction = Direction.stop;
    led = LedState.off;
    addLog('宸叉柇寮€');
    notifyListeners();
  }

  Future<void> sendCommand(List<int> data) async {
    if (txChar == null) {
      addLog('鏈厤缃彂閫佺壒寰侊紝璇峰厛鍦ㄨ缃腑閫夋嫨');
      return;
    }
    try {
      await txChar!.write(data);
      final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
      addLog('鍙戦€? $hex');
    } catch (e) {
      addLog('鍙戦€佸け璐? $e');
    }
  }

  // 鍙戦€佸甫閫熷害鐨勬柟鍚戝懡浠?  Future<void> sendDirection(Direction dir) async {
    direction = dir;
    notifyListeners();
    int cmd;
    switch (dir) {
      case Direction.forward: cmd = 0x01; break;
      case Direction.backward: cmd = 0x02; break;
      case Direction.left: cmd = 0x03; break;
      case Direction.right: cmd = 0x04; break;
      case Direction.stop: cmd = 0x00; break;
    }
    // 鏍煎紡: [鍛戒护, 閫熷害0-100]
    await sendCommand([cmd, speed]);
  }

  void stop() => sendDirection(Direction.stop);

  void setSpeed(int s) {
    speed = s.clamp(0, 100);
    notifyListeners();
    // 閲嶆柊鍙戦€佸綋鍓嶆柟鍚戜互搴旂敤鏂伴€熷害
    if (direction != Direction.stop && isConnected) {
      sendDirection(direction);
    }
  }

  void toggleLed() {
    led = led == LedState.off ? LedState.on : LedState.off;
    notifyListeners();
    sendCommand(led == LedState.on ? [0x10] : [0x11]);
  }

  void sendBuzzer() => sendCommand([0x20]);

  void sendCustom(String hex) {
    try {
      final h = hex.replaceAll(' ', '');
      final data = List.generate(h.length ~/ 2,
        (i) => int.parse(h.substring(i * 2, i * 2 + 2), radix: 16));
      sendCommand(data);
    } catch (e) {
      addLog('HEX鏍煎紡閿欒: $e');
    }
  }

  void setTxChar(BluetoothCharacteristic c) {
    txChar = c;
    addLog('鍙戦€佺壒寰佸凡璁剧疆: ${c.uuid}');
    notifyListeners();
  }
}
