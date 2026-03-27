import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'ble_manager.dart';
import 'device_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  Color _rssiColor(int r) {
    if (r >= -60) return const Color(0xFF4CAF50);
    if (r >= -75) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  int _rssiBars(int r) {
    if (r >= -60) return 4;
    if (r >= -70) return 3;
    if (r >= -80) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleManager>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(children:[
          Container(width:10,height:10,decoration:const BoxDecoration(color:Color(0xFF00A9CE),shape:BoxShape.circle)),
          const SizedBox(width:8),
          const Text('nRF BLE Tool',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600,fontSize:18)),
        ]),
        actions:[
          if (ble.connectedDevices.isNotEmpty)
            TextButton(onPressed:()=>ble.disconnectAll(),child:const Text('全部断开',style:TextStyle(color:Color(0xFFF44336)))),
          if (ble.isScanning)
            const Padding(padding:EdgeInsets.only(right:16),child:Center(child: SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Color(0xFF00A9CE))))),
        ],
      ),
      body: Column(children:[
        if (ble.connectedDevices.isNotEmpty)
          Container(color:const Color(0xFF1A3A1A),padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
            child:Row(children:[
              const Icon(Icons.bluetooth_connected,color:Color(0xFF4CAF50),size:16),
              const SizedBox(width:8),
              Text('已连接 ${ble.connectedDevices.length} 台',style:const TextStyle(color:Color(0xFF4CAF50),fontSize:13)),
              const Spacer(),
              ...ble.connectedDevices.values.map((cd)=>Padding(padding:const EdgeInsets.only(left:8),
                child:GestureDetector(
                  onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>DeviceScreen(devId:cd.device.remoteId.str))),
                  child:Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
                    decoration:BoxDecoration(color:const Color(0xFF00A9CE),borderRadius:BorderRadius.circular(12)),
                    child:Text(cd.name.length>8?cd.name.substring(0,8):cd.name,style:const TextStyle(color:Colors.white,fontSize:12))),
                ))),
            ])),

        Container(color:const Color(0xFF1E1E1E),padding:const EdgeInsets.all(12),
          child:Column(children:[
            Row(children:[
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(ble.isScanning?'扫描中...':'${ble.filteredResults.length} 台设备',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w500,fontSize:15)),
                Text(ble.isScanning?'正在搜索 BLE 设备':'点击设备连接',style:const TextStyle(color:Colors.grey,fontSize:12)),
              ])),
              SizedBox(width:120,child:TextField(
                onChanged:ble.setScanFilter,
                style:const TextStyle(color:Colors.white,fontSize:13),
                decoration:const InputDecoration(hintText:'筛选...',hintStyle:TextStyle(color:Colors.grey,fontSize:12),contentPadding:EdgeInsets.symmetric(horizontal:10,vertical:8)),
              )),
              const SizedBox(width:8),
              GestureDetector(
                onTap:()async{
                  if(ble.isScanning){ble.stopScan();return;}
                  await[Permission.bluetooth,Permission.bluetoothScan,Permission.bluetoothConnect,Permission.locationWhenInUse].request();
                  ble.startScan(timeout:const Duration(seconds:15));
                },
                child:Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
                  decoration:BoxDecoration(color:ble.isScanning?const Color(0xFF3A3A3A):const Color(0xFF00A9CE),borderRadius:BorderRadius.circular(20)),
                  child:Text(ble.isScanning?'停止':'扫描',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:13))),
              ),
            ]),
            const SizedBox(height:8),
            Row(children:[
              _filterChip('全部', ble.scanFilter.isEmpty, ()=>ble.setScanFilter('')),
              const SizedBox(width:8),
              _filterChip('已连接', false, (){}),
            ]),
          ])),

        const Divider(height:1,color:Color(0xFF2A2A2A)),

        Expanded(child:ble.filteredResults.isEmpty
          ?Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Icon(Icons.bluetooth_searching,size:56,color:Colors.grey.shade700),
              const SizedBox(height:12),
              Text(ble.isScanning?'扫描中...':'未发现设备',style:TextStyle(color:Colors.grey.shade500,fontSize:15)),
            ]))
          :ListView.separated(
            itemCount:ble.filteredResults.length,
            separatorBuilder:(_,__)=> const Divider(height:1,color:Color(0xFF2A2A2A),indent:16),
            itemBuilder:(ctx,i){
              final r=ble.filteredResults[i];
              final name=r.device.localName.isEmpty?'未知设备':r.device.localName;
              final id=r.device.remoteId.str;
              final bars=_rssiBars(r.rssi);
              final rc=_rssiColor(r.rssi);
              final isConn=ble.connectedDevices.containsKey(id);

              return InkWell(
                onTap:()async{
                  if(isConn){
                    Navigator.push(ctx,MaterialPageRoute(builder:(_)=>DeviceScreen(devId:id)));
                  }else{
                    final ok=await ble.connect(r.device);
                    if(ok && ctx.mounted) Navigator.push(ctx,MaterialPageRoute(builder:(_)=>DeviceScreen(devId:id)));
                  }
                },
                child:Container(color:const Color(0xFF1E1E1E),padding:const EdgeInsets.symmetric(horizontal:16,vertical:10),
                  child:Row(children:[
                    SizedBox(width:30,height:28,child:Column(mainAxisAlignment:MainAxisAlignment.end,children:List.generate(4,(j)=>Container(width:5,height:5+j*5,margin:const EdgeInsets.only(top:1),
                      decoration:BoxDecoration(color:j<bars?rc:const Color(0xFF3A3A3A),borderRadius:BorderRadius.circular(1)))))),
                    const SizedBox(width:12),
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Row(children:[
                        Text(name,style:TextStyle(color:isConn?const Color(0xFF00A9CE):Colors.white,fontWeight:FontWeight.w600,fontSize:15)),
                        if(isConn)...[
                          const SizedBox(width:6),
                          Container(width:6,height:6,decoration:const BoxDecoration(color:Color(0xFF4CAF50),shape:BoxShape.circle)),
                        ],
                      ]),
                      const SizedBox(height:2),
                      Text(id,style:const TextStyle(color:Color(0xFF6B7280),fontSize:11,fontFamily:'monospace')),
                    ])),
                    Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                      Text('${r.rssi}',style:TextStyle(color:rc,fontWeight:FontWeight.bold,fontSize:14)),
                      Text('dBm',style:TextStyle(color:Colors.grey.shade600,fontSize:10)),
                    ]),
                    const SizedBox(width:8),
                    Icon(isConn?Icons.chevron_right:Icons.add_circle_outline,color:isConn?const Color(0xFF00A9CE):Colors.grey.shade600,size:20),
                  ])));
            })),
      ]),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap:onTap,
      child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
        decoration:BoxDecoration(color:selected?const Color(0xFF00A9CE):const Color(0xFF2A2A2A),borderRadius:BorderRadius.circular(12)),
        child:Text(label,style:TextStyle(color:selected?Colors.white:Colors.grey.shade500,fontSize:12))));
  }
}
