import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'car_manager.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});
  @override State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool _showLog = false;
  final _hexCtrl = TextEditingController();
  Direction _activeDir = Direction.stop;

  @override void dispose() { _hexCtrl.dispose(); super.dispose(); }

  Color _dirColor(Direction d) => _activeDir == d
      ? const Color(0xFFE94560) : Colors.grey.shade700;

  @override
  Widget build(BuildContext context) {
    final car = context.watch<CarManager>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios,size:18), onPressed:()=>Navigator.pop(context)),
        title: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(car.device?.localName.isEmpty == false
              ? car.device!.localName : '宸茶繛鎺?, style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600,fontSize:16)),
          Row(children:[
            Container(width:6,height:6,decoration:const BoxDecoration(color:Color(0xFF4CAF50),shape:BoxShape.circle)),
            const SizedBox(width:4),
            Text(car.txChar != null ? '宸插氨缁? : '鑷姩妯″紡', style:const TextStyle(color:Color(0xFF4CAF50),fontSize:11)),
          ]),
        ]),
        actions:[
          IconButton(
            icon: Icon(_showLog ? Icons.gamepad : Icons.article, color: _showLog ? const Color(0xFFE94560) : Colors.white),
            onPressed:()=>setState(()=>_showLog=!_showLog)),
          TextButton(
            onPressed:()=>car.disconnect(),
            child: const Text('鏂紑', style:TextStyle(color:Color(0xFFF44336)))),
        ],
      ),
      body: _showLog ? _buildLog(car) : _buildControl(car),
    );
  }

  Widget _buildControl(CarManager car) {
    return Column(children:[
      const SizedBox(height:16),

      // 閫熷害鏉?      Container(
        margin: const EdgeInsets.symmetric(horizontal:20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color:const Color(0xFF16213E), borderRadius:BorderRadius.circular(16)),
        child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            const Icon(Icons.speed,color:Color(0xFFE94560),size:18),
            const SizedBox(width:8),
            const Text('閫熷害鎺у埗',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal:12,vertical:4),
              decoration: BoxDecoration(color:const Color(0xFFE94560),borderRadius:BorderRadius.circular(20)),
              child: Text('${car.speed}%',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold))),
          ]),
          const SizedBox(height:12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFE94560),
              inactiveTrackColor: Colors.grey.shade800,
              thumbColor: const Color(0xFFE94560),
              overlayColor: const Color(0xFFE94560).withOpacity(0.2),
              trackHeight: 8,
            ),
            child: Slider(
              value: car.speed.toDouble(),
              min: 0, max: 100, divisions: 20,
              onChanged: (v) => car.setSpeed(v.toInt()),
            ),
          ),
        ]),
      ),

      const SizedBox(height:20),

      // 鏂瑰悜鎺у埗鍖?      Center(
        child: Column(children:[
          // 鍓嶈繘
          _dirBtn(Direction.forward, Icons.arrow_upward, '鍓嶈繘', car),
          const SizedBox(height:8),
          Row(mainAxisAlignment:MainAxisAlignment.center, children:[
            _dirBtn(Direction.left, Icons.turn_left, '宸﹁浆', car),
            const SizedBox(width:8),
            // 鍋滄
            GestureDetector(
              onTap:()=>setState(()=>_activeDir=Direction.stop),
              onTapDown:(_){car.sendDirection(Direction.stop);setState(()=>_activeDir=Direction.stop);},
              child:Container(
                width:72,height:72,
                decoration:BoxDecoration(color:_activeDir==Direction.stop?const Color(0xFFE94560):const Color(0xFF0F3460),
                  shape:BoxShape.circle,border:Border.all(color:_activeDir==Direction.stop?const Color(0xFFE94560):Colors.grey.shade700,width:2)),
                child:const Icon(Icons.stop,color:Colors.white,size:36))),
            const SizedBox(width:8),
            _dirBtn(Direction.right, Icons.turn_right, '鍙宠浆', car),
          ]),
          const SizedBox(height:8),
          // 鍚庨€€
          _dirBtn(Direction.backward, Icons.arrow_downward, '鍚庨€€', car),
        ]),
      ),

      const SizedBox(height:20),

      // 鍔熻兘鎸夐挳
      Padding(
        padding: const EdgeInsets.symmetric(horizontal:20),
        child: Row(children:[
          _funcBtn(Icons.highlight, '鐏厜', car.led==LedState.on?const Color(0xFFFFEB3B):Colors.grey.shade700, ()=>car.toggleLed()),
          const SizedBox(width:10),
          _funcBtn(Icons.volume_up, '铚傞福', Colors.grey.shade700, ()=>car.sendBuzzer()),
          const SizedBox(width:10),
          _funcBtn(Icons.settings, '璁剧疆', Colors.grey.shade700, ()=>_showSettings(car)),
        ]),
      ),

      const Spacer(),

      // 鑷畾涔塇EX鍙戦€?      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color:const Color(0xFF16213E), borderRadius:BorderRadius.circular(12)),
        child: Row(children:[
          Expanded(child:TextField(controller:_hexCtrl,
            style: const TextStyle(color:Colors.white,fontFamily:'monospace'),
            decoration: const InputDecoration(
              hintText:'HEX鎸囦护濡? 01 64',
              hintStyle:TextStyle(color:Colors.grey),
              border:InputBorder.none,
            ))),
          GestureDetector(
            onTap:(){
              if(_hexCtrl.text.isNotEmpty){
                car.sendCustom(_hexCtrl.text);
                _hexCtrl.clear();
              }
            },
            child:Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
              decoration:BoxDecoration(color:const Color(0xFFE94560),borderRadius:BorderRadius.circular(8)),
              child:const Text('鍙戦€?,style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold))),
          ),
        ]),
      ),
    ]);
  }

  Widget _dirBtn(Direction dir, IconData icon, String label, CarManager car) {
    final active = _activeDir == dir;
    return GestureDetector(
      onTapDown:(_){car.sendDirection(dir);setState(()=>_activeDir=dir);},
      onTapUp:(_){car.sendDirection(Direction.stop);setState(()=>_activeDir=Direction.stop);},
      onTapCancel:(){car.sendDirection(Direction.stop);setState(()=>_activeDir=Direction.stop);},
      child:Container(
        width:72,height:72,
        decoration:BoxDecoration(
          color:active?const Color(0xFFE94560).withOpacity(0.2):const Color(0xFF0F3460),
          borderRadius:BorderRadius.circular(16),
          border:Border.all(color:active?const Color(0xFFE94560):Colors.grey.shade700,width:2),
        ),
        child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          Icon(icon,color:active?const Color(0xFFE94560):Colors.grey.shade400,size:28),
          const SizedBox(height:2),
          Text(label,style:TextStyle(color:active?const Color(0xFFE94560):Colors.grey.shade400,fontSize:11)),
        ]),
      ),
    );
  }

  Widget _funcBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child:GestureDetector(
        onTap:onTap,
        child:Container(
          padding:const EdgeInsets.symmetric(vertical:12),
          decoration:BoxDecoration(color:const Color(0xFF16213E),borderRadius:BorderRadius.circular(12)),
          child:Column(children:[
            Icon(icon,color:color,size:24),
            const SizedBox(height:4),
            Text(label,style:TextStyle(color:color,fontSize:12)),
          ]),
        ),
      ),
    );
  }

  Widget _buildLog(CarManager car) {
    return Column(children:[
      Container(color:const Color(0xFF16213E),padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
        child:Row(children:[
          const Text('閫氫俊鏃ュ織',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),
          const Spacer(),
          GestureDetector(onTap:()=>car.logs.clear(),child:const Text('娓呴櫎',style:TextStyle(color:Color(0xFFE94560)))),
        ])),
      Expanded(child:car.logs.isEmpty
        ?const Center(child:Text('鏆傛棤鏃ュ織',style:TextStyle(color:Colors.grey)))
        :ListView.builder(
          padding:const EdgeInsets.all(12),
          itemCount:car.logs.length,
          itemBuilder:(ctx,i)=>Container(
            margin:const EdgeInsets.only(bottom:4),
            padding:const EdgeInsets.all(8),
            decoration:BoxDecoration(color:const Color(0xFF16213E),borderRadius:BorderRadius.circular(6)),
            child:Text(car.logs[i],style:const TextStyle(color:Color(0xFF4CAF50),fontSize:12,fontFamily:'monospace')),
          ))),
    ]);
  }

  void _showSettings(CarManager car) {
    showModalBottomSheet(context:context,backgroundColor:const Color(0xFF1A1A2E),
      builder:(ctx)=>Padding(padding:const EdgeInsets.all(20),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Text('璁剧疆',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600,fontSize:18)),
          const SizedBox(height:16),
          _settingRow('鍙戦€佺壒寰乁UID', car.txChar?.uuid.toString() ?? '鑷姩'),
          _settingRow('鎺ユ敹鐗瑰緛UUID', car.rxChar?.uuid.toString() ?? '鑷姩'),
          _settingRow('杩炴帴鐘舵€?, car.isConnected?'宸茶繛鎺?:'鏈繛鎺?,
            valueColor:car.isConnected?const Color(0xFF4CAF50):Colors.grey),
          _settingRow('閫熷害', '${car.speed}%'),
          _settingRow('鍗忚', 'Nordic UART / 涓插彛閫忎紶'),
          const SizedBox(height:16),
          Row(children:[
            Expanded(child:ElevatedButton(
              style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFE94560)),
              onPressed:()=>Navigator.pop(ctx),
              child:const Text('纭畾'))),
            const SizedBox(width:12),
            Expanded(child:OutlinedButton(
              style:OutlinedButton.styleFrom(side:const BorderSide(color:Color(0xFFE94560))),
              onPressed:()async{Navigator.pop(ctx);await car.disconnect();if(ctx.mounted)Navigator.pop(context);},
              child:const Text('鏂紑杩炴帴',style:TextStyle(color:Color(0xFFE94560))))),
          ]),
        ])));
  }

  Widget _settingRow(String label, String value, {Color? valueColor}) =>
    Padding(padding:const EdgeInsets.only(bottom:12),
      child:Row(children:[
        Text(label,style:const TextStyle(color:Colors.grey)),
        const Spacer(),
        Flexible(child:Text(value,style:TextStyle(color:valueColor??Colors.white),
          textAlign:TextAlign.right,overflow:TextOverflow.ellipsis)),
      ]));
}
