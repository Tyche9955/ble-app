import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'car_manager.dart';
import 'control_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final car = context.watch<CarManager>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Row(children:[
          Container(width:10,height:10,decoration:const BoxDecoration(color:Color(0xFFE94560),shape:BoxShape.circle)),
          const SizedBox(width:8),
          const Text('BLE 灏忚溅鎺у埗',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600,fontSize:18)),
        ]),
        actions:[
          if(car.isConnected)
            ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFE94560)),
            TextButton(onPressed:()=>car.disconnect(),child:const Text('鏂紑',style:TextStyle(color:Color(0xFFE94560)))),
        ],
      ),
      body: car.isConnected
        ? ControlScreen()
        : Column(children:[
            // 鎵弿鎸夐挳
            Container(color:const Color(0xFF16213E),padding:const EdgeInsets.all(16),
              child:Column(children:[
                Row(children:[
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(car.isScanning?'鎵弿涓?..':'${car.devices.length} 鍙拌澶?,
                      style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w500,fontSize:15)),
                    Text(car.isScanning?'姝ｅ湪鎼滅储BLE璁惧':'鐐瑰嚮璁惧杩炴帴',
                      style:const TextStyle(color:Colors.grey,fontSize:12)),
                  ])),
                  GestureDetector(
                    onTap:()async{
                      if(car.isScanning){car.stopScan();return;}
                      await[Permission.bluetooth,Permission.bluetoothScan,
                        Permission.bluetoothConnect,Permission.locationWhenInUse].request();
                      car.startScan();
                    },
                    child:Container(padding:const EdgeInsets.symmetric(horizontal:20,vertical:10),
                      decoration:BoxDecoration(
                        color:car.isScanning?Colors.grey:const Color(0xFFE94560),
                        borderRadius:BorderRadius.circular(25),
                      ),
                      child:Row(children:[
                        if(car.isScanning)
                          const SizedBox(width:16,height:16,
                            child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)),
                        const SizedBox(width:6),
                        Text(car.isScanning?'鍋滄':'鎵弿',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
                      ])),
                  ),
                ])),
                const SizedBox(height:12),
                // 蹇嵎鎸囦护璇存槑
                Container(
                  padding:const EdgeInsets.all(12),
                  decoration:BoxDecoration(color:const Color(0xFF0F3460),borderRadius:BorderRadius.circular(10)),
                  child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text('鏀寔鐨勫皬杞﹀崗璁細',style:TextStyle(color:Color(0xFFE94560),fontWeight:FontWeight.w600,fontSize:13)),
                    SizedBox(height:6),
                    Text('鍓嶈繘 01 + 閫熷害 | 鍚庨€€ 02 | 宸﹁浆 03 | 鍙宠浆 04 | 鍋滄 00',style:TextStyle(color:Colors.white70,fontSize:12,fontFamily:'monospace')),
                    Text('寮€鐏?10 | 鍏崇伅 11 | 铚傞福 20',style:TextStyle(color:Colors.white70,fontSize:12,fontFamily:'monospace')),
                    Text('鏀寔 Nordic UART / 涓插彛閫忎紶 BLE 妯″潡',style:TextStyle(color:Colors.grey,fontSize:11)),
                  ]),
                ),
              ])),

            const Divider(height:1,color:Color(0xFF0F3460)),

            // 璁惧鍒楄〃
            Expanded(child:car.devices.isEmpty
              ?Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                  Icon(Icons.bluetooth_searching,size:60,color:Colors.grey.shade600),
                  const SizedBox(height:12),
                  Text(car.isScanning?'鎵弿涓?..':'鏈彂鐜拌澶?,style:TextStyle(color:Colors.grey.shade500,fontSize:15)),
                  if(!car.isScanning)
                    Text('鐐瑰嚮涓婃柟"鎵弿"寮€濮嬫悳绱?,style:TextStyle(color:Colors.grey.shade700,fontSize:12)),
                ]))
              :ListView.separated(
                itemCount:car.devices.length,
                separatorBuilder:(_,__)=>const Divider(height:1,color:Color(0xFF0F3460)),
                itemBuilder:(ctx,i){
                  final r=car.devices[i];
                  final name=r.device.localName.isEmpty?'鏈煡璁惧':r.device.localName;
                  final rc=r.rssi>= -60?const Color(0xFF4CAF50):r.rssi>= -75?const Color(0xFFFF9800):const Color(0xFFF44336);
                  return InkWell(
                    onTap:()async{
                      final ok=await car.connect(r.device);
                      if(ok && ctx.mounted){
                        Navigator.push(ctx,MaterialPageRoute(builder:(_)=>const ControlScreen()));
                      }
                    },
                    child:Container(color:const Color(0xFF16213E),padding:const EdgeInsets.symmetric(horizontal:16,vertical:14),
                      child:Row(children:[
                        Container(width:40,height:40,
                          decoration:BoxDecoration(color:const Color(0xFF0F3460),borderRadius:BorderRadius.circular(10)),
                          child:const Icon(Icons.toys,color:Color(0xFFE94560),size:22)),
                        const SizedBox(width:12),
                        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                          Text(name,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600,fontSize:15)),
                          const SizedBox(height:2),
                          Text(r.device.remoteId.str,style:const TextStyle(color:Color(0xFF6B7280),fontSize:11,fontFamily:'monospace')),
                        ])),
                        Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                          Text('${r.rssi}',style:TextStyle(color:rc,fontWeight:FontWeight.bold,fontSize:16)),
                          const Text('dBm',style:TextStyle(color:Colors.grey.shade600,fontSize:10)),
                        ]),
                        const SizedBox(width:8),
                        const Icon(Icons.chevron_right,color:Color(0xFF3A3A5A),size:20),
                      ])));
                })),
          ]),
    );
  }
}
