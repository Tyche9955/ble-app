import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'ble_manager.dart';

class DeviceScreen extends StatefulWidget {
  final String devId;
  const DeviceScreen({super.key, required this.devId});
  @override State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _writeCtrl = TextEditingController();
  final _filterCtrl = TextEditingController();
  String _serviceFilter = '';
  String _charFilter = '';

  @override void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override void dispose() { _tabs.dispose(); _writeCtrl.dispose(); _filterCtrl.dispose(); super.dispose(); }

  Color _logColor(LogType t) {
    switch(t){case LogType.send:return const Color(0xFF00A9CE);case LogType.receive:return const Color(0xFF4CAF50);
      case LogType.notify:return const Color(0xFFFFB74D);case LogType.error:return const Color(0xFFF44336);case LogType.success:return const Color(0xFF4CAF50);default:return const Color(0xFF9E9E9E);}
  }
  String _logPrefix(LogType t) {
    switch(t){case LogType.send:return '→';case LogType.receive:return '←';case LogType.notify:return '⇢';
      case LogType.error:return '✕';case LogType.success:return '✓';default:return '·';}
  }
  String _svcName(String u) {
    final s=u.toLowerCase();
    if(s.contains('1800'))return'通用访问(GAP)';
    if(s.contains('1801'))return'通用属性(GATT)';
    if(s.contains('180a'))return'设备信息';
    if(s.contains('180f'))return'电池服务';
    if(s.contains('180d'))return'心率服务';
    if(s.contains('1810'))return'血压服务';
    if(s.contains('181a'))return'环境感知';
    if(s.contains('181c'))return'用户数据';
    if(s.contains('fff0')||s.contains('ffe0'))return'自定义服务';
    return'未知服务';
  }
  String _charName(String u) {
    final s=u.toLowerCase();
    if(s.contains('2a00'))return'设备名称';
    if(s.contains('2a01'))return'外观';
    if(s.contains('2a19'))return'电池电量';
    if(s.contains('2a24'))return'型号';
    if(s.contains('2a25'))return'序列号';
    if(s.contains('2a26'))return'固件版本';
    if(s.contains('2a27'))return'硬件版本';
    if(s.contains('2a28'))return'软件版本';
    if(s.contains('2a29'))return'制造商';
    if(s.contains('2a37'))return'心率测量';
    if(s.contains('2a38'))return'体位传感器';
    if(s.contains('2a39'))return'心率控制点';
    if(s.contains('2901'))return'描述';
    if(s.contains('2902'))return'客户端配置';
    if(s.contains('2903'))return'服务器配置';
    if(s.contains('fff1')||s.contains('ffe1'))return'自定义特征';
    return'特征值';
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleManager>();
    final cd = ble.connectedDevices[widget.devId];
    if (cd == null) {
      return Scaffold(backgroundColor:const Color(0xFF121212),body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.bluetooth_disabled,size:64,color:Colors.grey),const SizedBox(height:16),const Text('设备已断开',style:TextStyle(color:Colors.grey,fontSize:16)),const SizedBox(height:24),ElevatedButton(onPressed:()=>Navigator.pop(context),child:const Text('返回'))])));
    }

    final services = cd.services;
    final filteredSvcs = services.where((s)=>_serviceFilter.isEmpty||s.uuid.toString().toLowerCase().contains(_serviceFilter.toLowerCase())||_svcName(s.uuid.toString()).contains(_serviceFilter)).toList();

    return Scaffold(
      backgroundColor:const Color(0xFF121212),
      appBar:AppBar(
        backgroundColor:const Color(0xFF1E1E1E),
        leading:IconButton(icon:const Icon(Icons.arrow_back_ios,size:18),onPressed:()=>Navigator.pop(context)),
        title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(cd.name,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600,fontSize:16),overflow:TextOverflow.ellipsis),
          Row(children:[Container(width:6,height:6,decoration:const BoxDecoration(color:Color(0xFF4CAF50),shape:BoxShape.circle)),const SizedBox(width:4),Text('已连接 | MTU=${cd.mtu}',style:const TextStyle(color:Color(0xFF4CAF50),fontSize:11))]),
        ]),
        actions:[
          IconButton(icon:const Icon(Icons.refresh,size:20),onPressed:()async{
            ble.addLog('正在刷新服务...', LogType.info);
            final svcs=await cd.device.discoverServices();
            cd.services=svcs;
            ble.notifyListeners();
          }),
          IconButton(icon:const Icon(Icons.settings,size:20),onPressed:()=>_showDeviceInfo(context,cd)),
          TextButton(onPressed:()async{await ble.disconnect(widget.devId);if(context.mounted)Navigator.pop(context);},
            child:const Text('断开',style:TextStyle(color:const Color(0xFFF44336),fontSize:13))),
        ],
        bottom:TabBar(
          controller:_tabs,
          indicatorColor:const Color(0xFF00A9CE),
          labelColor:const Color(0xFF00A9CE),
          unselectedLabelColor:const Color(0xFF9E9E9E),
          tabs:[
            Tab(text:'服务 (${services.length})'),
            Tab(text:'日志'),
            Tab(text:'信息'),
          ],
        ),
      ),
      body:TabBarView(controller:_tabs,children:[
        // ── Services Tab ──
        Column(children:[
          // Filter bar
          Container(color:const Color(0xFF1E1E1E),padding:const EdgeInsets.all(8),
            child:TextField(controller:_filterCtrl,onChanged:(v)=>setState((){}),style:const TextStyle(color:Colors.white,fontSize:13),
              decoration:const InputDecoration(hintText:'筛选服务/特征值...',hintStyle:TextStyle(color:Colors.grey),
                prefixIcon:Icon(Icons.search,color:Colors.grey,size:18),isDense:true))),
          // Services list
          Expanded(child:filteredSvcs.isEmpty
            ?const Center(child:Text('无匹配服务',style:TextStyle(color:Colors.grey)))
            :ListView.builder(
              itemCount:filteredSvcs.length,
              itemBuilder:(ctx,i){
                final svc=filteredSvcs[i];
                final charFiltered=svc.characteristics.where((c)=>_charFilter.isEmpty||c.uuid.toString().toLowerCase().contains(_charFilter.toLowerCase())||_charName(c.uuid.toString()).contains(_charFilter)).toList();
                if(_charFilter.isNotEmpty&&charFiltered.isEmpty)return const SizedBox.shrink();
                return _buildServiceTile(ble, cd, svc, charFiltered);
              })),
          // Write panel
          if(cd.selectedChar!=null)
            Container(color:const Color(0xFF1E1E1E),
              padding:const EdgeInsets.all(12),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[
                  Expanded(child:Text('写入 ${cd.selectedChar!.uuid}',style:const TextStyle(color:Color(0xFF00A9CE),fontSize:12,fontFamily:'monospace'),overflow:TextOverflow.ellipsis)),
                  // Data type selector
                  ...DataType.values.map((t)=>GestureDetector(
                    onTap:()=>ble.setDataType(t),
                    child:Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
                      decoration:BoxDecoration(color:ble.dataType==t?const Color(0xFF00A9CE):const Color(0xFF2A2A2A),borderRadius:BorderRadius.circular(4)),
                      child:Text({'hex':'HEX','ascii':'ASCII','utf8':'UTF-8','decimal':'DEC'}[t.toString().split('.').last]??t.toString(),style:TextStyle(color:ble.dataType==t?Colors.white:Colors.grey,fontSize:11))),
                  )),
                ]),
                const SizedBox(height:8),
                Row(children:[
                  Expanded(child:TextField(controller:_writeCtrl,style:const TextStyle(color:Colors.white,fontFamily:'monospace',fontSize:14),
                    decoration:const InputDecoration(hintText:'输入 HEX (01 02 FF) 或文本',hintStyle:TextStyle(color:Colors.grey.shade700),isDense:true))),
                  const SizedBox(width:8),
                  _opBtn('写入',const Color(0xFF00A9CE),()=>ble.writeChar(widget.devId,cd.selectedChar!,_writeCtrl.text)),
                  _opBtn('写入NR',const Color(0xFF00A9CE),()=>ble.writeChar(widget.devId,cd.selectedChar!,_writeCtrl.text,withResponse:false)),
                  _opBtn('读取',const Color(0xFF4CAF50),()=>ble.readChar(widget.devId,cd.selectedChar!)),
                  _opBtn(cd.selectedChar!.isNotifying?'取消通知':'通知',cd.selectedChar!.isNotifying?const Color(0xFFFF9800):const Color(0xFF4CAF50),
                    ()=>ble.toggleNotify(widget.devId,cd.selectedChar!)),
                ]),
              ]),
            ),
        ]),

        // ── Log Tab ──
        Column(children:[
          Container(color:const Color(0xFF1E1E1E),padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),
            child:Row(children:[
              Text('${ble.logs.length} 条记录',style:const TextStyle(color:Color(0xFF9E9E9E),fontSize:12)),
              const Spacer(),
              GestureDetector(onTap:ble.exportLogs,child:const Text('导出',style:TextStyle(color:Color(0xFF00A9CE),fontSize:12))),
              const SizedBox(width:16),
              GestureDetector(onTap:ble.clearLogs,child:const Text('清除',style:TextStyle(color:Color(0xFFF44336),fontSize:12))),
            ])),
          Expanded(child:ble.logs.isEmpty?const Center(child:Text('暂无日志',style:TextStyle(color:Colors.grey))):
            ListView.builder(padding:const EdgeInsets.all(8),itemCount:ble.logs.length,itemBuilder:(ctx,i){
              final l=ble.logs[i];
              return Padding(padding:const EdgeInsets.only(bottom:4),
                child:Container(padding:const EdgeInsets.all(8),
                  decoration:BoxDecoration(color:const Color(0xFF1A1A1A),borderRadius:BorderRadius.circular(6)),
                  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Row(children:[
                      Text(l.time.toString().substring(11,23),style:const TextStyle(color:Color(0xFF4A4A4A),fontSize:10,fontFamily:'monospace')),
                      const SizedBox(width:6),
                      Text(_logPrefix(l.type),style:TextStyle(color:_logColor(l.type),fontWeight:FontWeight.bold,fontSize:12)),
                    ]),
                    const SizedBox(height:4),
                    Text(l.message,style:TextStyle(color:_logColor(l.type),fontSize:11,fontFamily:'monospace'),maxLines:10,overflow:TextOverflow.ellipsis),
                  ])));
            })),
        ]),

        // ── Info Tab ──
        ListView(padding:const EdgeInsets.all(16),children:[
          _infoCard('设备名称', cd.name),
          _infoCard('设备地址', cd.device.remoteId.str),
          _infoCard('设备类型', '经典蓝牙 + BLE'),
          _infoCard('MTU大小', '${cd.mtu} 字节'),
          _infoCard('服务数量', '${services.length}'),
          _infoCard('特征值总数', '${services.fold<int>(0, (a,s)=>a+s.characteristics.length)}'),
          const SizedBox(height:16),
          _infoCard('连接状态', '已连接',valueColor:const Color(0xFF4CAF50)),
          _infoCard('发现时间', DateTime.now().toString().substring(0,19)),
        ]),
      ]),
    );
  }

  Widget _buildServiceTile(BleManager ble, ConnectedDevice cd, BluetoothService svc, List<BluetoothCharacteristic> chars) {
    final expanded=cd.isExpanded;
    return Column(children:[
      InkWell(
        onTap:(){cd.isExpanded=!expanded;ble.notifyListeners();},
        child:Container(color:const Color(0xFF2A2A2A),padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
          child:Row(children:[
            Icon(expanded?Icons.expand_more:Icons.chevron_right,color:const Color(0xFF00A9CE),size:18),
            const SizedBox(width:8),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(_svcName(svc.uuid.toString()),style:const TextStyle(color:Color(0xFF00A9CE),fontWeight:FontWeight.w600,fontSize:13)),
              Text(svc.uuid.toString().toUpperCase(),style:const TextStyle(color:Color(0xFF6B7280),fontSize:10,fontFamily:'monospace')),
            ])),
            Text('${chars.length} 特征',style:const TextStyle(color:Color(0xFF6B7280),fontSize:11)),
          ]))),
      if(expanded)
        ...chars.map((c)=>_buildCharTile(ble,cd,svc,c)),
    ]);
  }

  Widget _buildCharTile(BleManager ble, ConnectedDevice cd, BluetoothService svc, BluetoothCharacteristic c) {
    final sel=cd.selectedChar?.uuid==c.uuid;
    final props= <String>[];
    if(c.properties.read)props.add('R');
    if(c.properties.write||c.properties.writeWithoutResponse)props.add('W');
    if(c.properties.notify||c.properties.indicate)props.add('N');
    if(c.properties.broadcast)props.add('B');
    return InkWell(
      onTap:(){cd.selectedChar=c;ble.notifyListeners();},
      child:Container(color:sel?const Color(0xFF0D3D4D):const Color(0xFF1A1A1A),
        child:Column(children:[
          Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
            child:Row(children:[
              if(sel)Container(width:3,height:36,color:const Color(0xFF00A9CE),margin:const EdgeInsets.only(right:10)),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(_charName(c.uuid.toString()),style:TextStyle(color:sel?const Color(0xFF00A9CE):Colors.white,fontWeight:FontWeight.w500,fontSize:13)),
                Text(c.uuid.toString().toUpperCase(),style:const TextStyle(color:Color(0xFF6B7280),fontSize:10,fontFamily:'monospace')),
                const SizedBox(height:4),
                Wrap(spacing:4,children:props.map((p){
                  Color pc; String pp;
                  switch(p){case'R':pc=const Color(0xFF00A9CE);pp='READ';case'W':pc=const Color(0xFFFF9800);pp='WRITE';case'N':pc=const Color(0xFF4CAF50);pp='NOTIFY';default:pc=const Color(0xFF9E9E9E);pp=p;}
                  return Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),
                    decoration:BoxDecoration(color:pc.withOpacity(0.15),borderRadius:BorderRadius.circular(4),border:Border.all(color:pc,width:1)),
                    child:Text(pp,style:TextStyle(color:pc,fontSize:10,fontWeight:FontWeight.bold)));
                }).toList()),
              ])),
              // Quick action buttons
              Row(children:[
                if(c.properties.read)
                  GestureDetector(onTap:()=>ble.readChar(widget.devId,c),
                    child:Container(width:28,height:28,margin:const EdgeInsets.only(left:4),
                      decoration:BoxDecoration(color:const Color(0xFF00A9CE).withOpacity(0.15),borderRadius:BorderRadius.circular(4),border:Border.all(color:const Color(0xFF00A9CE))),
                      child:const Center(child:Text('R',style:TextStyle(color:Color(0xFF00A9CE),fontWeight:FontWeight.bold,fontSize:11))))),
                if(c.properties.notify||c.properties.indicate)
                  GestureDetector(onTap:()=>ble.toggleNotify(widget.devId,c),
                    child:Container(width:28,height:28,margin:const EdgeInsets.only(left:4),
                      decoration:BoxDecoration(color:(c.isNotifying?const Color(0xFFFF9800):const Color(0xFF4CAF50)).withOpacity(0.15),borderRadius:BorderRadius.circular(4),
                        border:Border.all(color:c.isNotifying?const Color(0xFFFF9800):const Color(0xFF4CAF50))),
                      child:Center(child:Text('N',style:TextStyle(color:c.isNotifying?const Color(0xFFFF9800):const Color(0xFF4CAF50),fontWeight:FontWeight.bold,fontSize:11))))),
                if(c.properties.write||c.properties.writeWithoutResponse)
                  GestureDetector(onTap:(){cd.selectedChar=c;ble.notifyListeners();_tabs.animateTo(0);},
                    child:Container(width:28,height:28,margin:const EdgeInsets.only(left:4),
                      decoration:BoxDecoration(color:const Color(0xFFFF9800).withOpacity(0.15),borderRadius:BorderRadius.circular(4),border:Border.all(color:const Color(0xFFFF9800))),
                      child:const Center(child:Text('W',style:TextStyle(color:Color(0xFFFF9800),fontWeight:FontWeight.bold,fontSize:11))))),
              ]),
            ])),
          // Descriptors
          if(c.descriptors.isNotEmpty&&sel)
            ...c.descriptors.map((d)=>InkWell(
              onTap:(){cd.selectedDesc=d;ble.notifyListeners();},
              child:Container(color:const Color(0xFF141414),
                padding:const EdgeInsets.only(left:36,right:16,bottom:6,top:6),
                child:Row(children:[
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(_charName(d.uuid.toString()),style:const TextStyle(color:Color(0xFF9E9E9E),fontSize:12)),
                    Text(d.uuid.toString().toUpperCase(),style:const TextStyle(color:Color(0xFF4A4A4A),fontSize:10,fontFamily:'monospace')),
                  ])),
                  GestureDetector(onTap:()=>ble.readDesc(d),
                    child:Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
                      decoration:BoxDecoration(color:const Color(0xFF2A2A2A),borderRadius:BorderRadius.circular(4)),
                      child:const Text('读取',style:TextStyle(color:Color(0xFF00A9CE),fontSize:11)))),
                ])),
            )),
        ]),
      ),
    );
  }

  Widget _opBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap:onTap,
      child:Container(margin:const EdgeInsets.only(left:4),padding:const EdgeInsets.symmetric(horizontal:10,vertical:8),
        decoration:BoxDecoration(color:color.withOpacity(0.15),borderRadius:BorderRadius.circular(6),border:Border.all(color:color)),
        child:Text(label,style:TextStyle(color:color,fontWeight:FontWeight.bold,fontSize:12))));
  }

  Widget _infoCard(String label, String value, {Color? valueColor}) {
    return Container(margin:const EdgeInsets.only(bottom:8),
      padding:const EdgeInsets.all(12),
      decoration:BoxDecoration(color:const Color(0xFF1E1E1E),borderRadius:BorderRadius.circular(8)),
      child:Row(children:[Text(label,style:const TextStyle(color:Color(0xFF9E9E9E),fontSize:13)),const Spacer(),
        Text(value,style:TextStyle(color:valueColor??Colors.white,fontSize:13,fontWeight:FontWeight.w500))]));
  }

  void _showDeviceInfo(BuildContext context, ConnectedDevice cd) {
    showModalBottomSheet(context:context,backgroundColor:const Color(0xFF1E1E1E),
      builder:(ctx)=>Padding(padding:const EdgeInsets.all(24),
        child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('设备信息',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600,fontSize:18)),
          const SizedBox(height:16),
          _infoRow('名称', cd.name),
          _infoRow('地址', cd.device.remoteId.str),
          _infoRow('类型', 'Bluetooth Low Energy'),
          _infoRow('MTU', '${cd.mtu}'),
          _infoRow('服务数', '${cd.services.length}'),
          const SizedBox(height:24),
          SizedBox(width:double.infinity,
            child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFF44336)),
              onPressed:()async{Navigator.pop(ctx);await cd.device.disconnect();if(ctx.mounted)Navigator.pop(context);},
              child:const Text('断开连接'))),
        ])));
  }

  Widget _infoRow(String k, String v) => Padding(padding:const EdgeInsets.only(bottom:12),
    child:Row(children:[Text(k,style:const TextStyle(color:Color(0xFF9E9E9E))),const Spacer(),Flexible(child:Text(v,style:const TextStyle(color:Colors.white),textAlign:TextAlign.right))]));
}
