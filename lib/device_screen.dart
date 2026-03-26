import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'ble_provider.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});
  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _sendCtrl = TextEditingController();

  @override
  void dispose() {
    _sendCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          ble.connectedDevice?.platformName ?? '设备详情',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ble.disconnect();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('断开', style: TextStyle(color: Color(0xFFF87171))),
          )
        ],
      ),
      body: Column(
        children: [
          // 服务/特征值列表
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text('服务 & 特征值',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height(6)),
                ...ble.services.map((svc) => ExpansionTile(
                  collapsedBackgroundColor: const Color(0xFF1E1E3A),
                  backgroundColor: const Color(0xFF13131F),
                  title: Text(
                    svc.uuid.toString(),
                    style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  children: svc.characteristics.map((char) {
                    final selected = ble.selectedChar?.uuid == char.uuid;
                    return ListTile(
                      tileColor: selected
                          ? const Color(0xFF1E3A5F)
                          : const Color(0xFF13131F),
                      title: Text(
                        char.uuid.toString(),
                        style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        char.properties.toString(),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      onTap: () => ble.selectChar(char),
                    );
                  }).toList(),
                )),
              ],
            ),
          ),
          // 操作区
          Container(
            color: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _sendCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'HEX (01 02) 或文本',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF13131F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5)),
                      onPressed: () => ble.writeChar(_sendCtrl.text),
                      child: const Text('发送', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF0891B2))),
                        onPressed: ble.readChar,
                        child: const Text('📖 读取'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF059669))),
                        onPressed: ble.subscribeNotify,
                        child: const Text('🔔 订阅通知'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 日志
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFF13131F),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('日志', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: ble.logs.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          ble.logs[i],
                          style: const TextStyle(
                              color: Color(0xFFA5B4FC),
                              fontSize: 11,
                              fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}