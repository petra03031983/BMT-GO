import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'notification_service.dart';
import 'payment_service.dart';

const yellow = Color(0xFFFFD400);


class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMin;
  RouteResult({required this.points, required this.distanceKm, required this.durationMin});
}

class RouteService {
  static Future<RouteResult?> getRoute({required LatLng origin, required LatLng destination}) async {
    const key = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (key.isEmpty) return null;
    final uri = Uri.parse('https://maps.googleapis.com/maps/api/directions/json').replace(queryParameters: {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'language': 'ru',
      'key': key,
    });
    try {
      final r = await http.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      if (j['status'] != 'OK') return null;
      final route = (j['routes'] as List).first as Map<String, dynamic>;
      final leg = ((route['legs'] as List).first) as Map<String, dynamic>;
      final meters = ((leg['distance'] as Map)['value'] as num).toDouble();
      final seconds = ((leg['duration'] as Map)['value'] as num).toInt();
      final encoded = route['overview_polyline']?['points'] as String?;
      final pts = encoded == null ? <LatLng>[origin, destination] : _decodePolyline(encoded);
      return RouteResult(points: pts, distanceKm: meters / 1000, durationMin: (seconds / 60).ceil());
    } catch (_) { return null; }
  }
  static List<LatLng> _decodePolyline(String encoded) {
    final result=<LatLng>[]; int index=0, lat=0, lng=0;
    while(index<encoded.length){
      int shift=0,resultValue=0;
      while(true){final b=encoded.codeUnitAt(index++)-63;resultValue|=(b&31)<<shift;shift+=5;if(b<32)break;}
      lat += (resultValue&1)!=0 ? ~(resultValue>>1) : (resultValue>>1);
      shift=0;resultValue=0;
      while(true){final b=encoded.codeUnitAt(index++)-63;resultValue|=(b&31)<<shift;shift+=5;if(b<32)break;}
      lng += (resultValue&1)!=0 ? ~(resultValue>>1) : (resultValue>>1);
      result.add(LatLng(lat/1e5,lng/1e5));
    }
    return result;
  }
}

int calculateDeliveryPrice(double km) => 1500 + (km.ceil() * 300);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: key);
    await BmtNotifications.init(Supabase.instance.client);
  }
  runApp(const BmtGo());
}

class BmtGo extends StatelessWidget {
  const BmtGo({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'BMT GO',
    theme:ThemeData(
      useMaterial3:true,
      scaffoldBackgroundColor:const Color(0xFFF6F6F6),
      colorScheme:ColorScheme.fromSeed(seedColor:yellow,brightness:Brightness.light),
      appBarTheme:const AppBarTheme(backgroundColor:Colors.black,foregroundColor:Colors.white,elevation:0),
      cardTheme:const CardThemeData(margin:EdgeInsets.zero,elevation:1,borderOnForeground:false),
      inputDecorationTheme:InputDecorationTheme(
        filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(14)),borderSide:BorderSide.none),
        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(14)),borderSide:BorderSide.none),
        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(14)),borderSide:BorderSide(color:yellow,width:2)),
      ),
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:Colors.black,foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(vertical:15,horizontal:18),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)))),
    ),
    home:Supabase.instance.isInitialized ? const AuthGate() : const Setup(),
  );
}

class Setup extends StatelessWidget { const Setup({super.key}); @override Widget build(BuildContext c)=>Scaffold(backgroundColor:Colors.black,body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
  Container(width:96,height:96,decoration:BoxDecoration(color:yellow,borderRadius:BorderRadius.circular(28)),child:const Icon(Icons.local_shipping_rounded,size:56,color:Colors.black)),
  const SizedBox(height:18),const Text('BMT GO',style:TextStyle(fontSize:38,fontWeight:FontWeight.w900,color:Colors.white)),
  const Text('Доставка, которая ближе.',style:TextStyle(color:yellow,fontSize:16,fontWeight:FontWeight.w700)),
  const SizedBox(height:24),const Text('Для запуска подключите Supabase через SUPABASE_URL и SUPABASE_ANON_KEY.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white70)),
])))); }

class AuthGate extends StatelessWidget { const AuthGate({super.key}); @override Widget build(BuildContext c)=>StreamBuilder<AuthState>(stream:Supabase.instance.client.auth.onAuthStateChange,builder:(c,s)=>Supabase.instance.client.auth.currentSession==null?const AuthPage():const Dashboard()); }

class AuthPage extends StatefulWidget { const AuthPage({super.key}); @override State<AuthPage> createState()=>_AuthPageState(); }
class _AuthPageState extends State<AuthPage> {
  final phone=TextEditingController(); final name=TextEditingController(); final code=TextEditingController();
  bool register=false,sent=false,busy=false; String role='client';
  final db=Supabase.instance.client;
  void msg(String x)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(x)));
  Future<void> send() async { if(phone.text.trim().isEmpty){msg('Введите номер телефона');return;} setState(()=>busy=true); try{await db.auth.signInWithOtp(phone:phone.text.trim());setState(()=>sent=true);msg('SMS с кодом отправлено');}catch(e){msg('Не удалось отправить SMS. Проверьте номер и настройки Supabase.');}finally{if(mounted)setState(()=>busy=false);} }
  Future<void> verify() async { if(code.text.trim().length<4){msg('Введите код из SMS');return;} setState(()=>busy=true); try{await db.auth.verifyOTP(phone:phone.text.trim(),token:code.text.trim(),type:OtpType.sms); final u=db.auth.currentUser; if(u!=null){await db.from('profiles').upsert({'id':u.id,'phone':phone.text.trim(),'full_name':name.text.trim(),'role':role});} msg('Вход выполнен');}catch(e){msg('Неверный код или срок действия SMS истёк');}finally{if(mounted)setState(()=>busy=false);} }
  @override Widget build(BuildContext c)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(22),child:Column(children:[
    Container(width:88,height:88,decoration:BoxDecoration(color:yellow,borderRadius:BorderRadius.circular(26)),child:const Icon(Icons.local_shipping_rounded,size:52,color:Colors.black)),const SizedBox(height:12),const Text('BMT GO',style:TextStyle(fontSize:36,fontWeight:FontWeight.w900)),const Text('Доставка, которая ближе.',style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:26),
    SegmentedButton<bool>(segments:const[ButtonSegment(value:false,label:Text('Вход')),ButtonSegment(value:true,label:Text('Регистрация'))],selected:{register},onSelectionChanged:(v)=>setState(()=>register=v.first)),const SizedBox(height:18),
    if(register)TextField(controller:name,decoration:const InputDecoration(labelText:'Имя',prefixIcon:Icon(Icons.person))),if(register)const SizedBox(height:10),
    if(register)DropdownButtonFormField<String>(value:role,decoration:const InputDecoration(labelText:'Тип аккаунта'),items:const[DropdownMenuItem(value:'client',child:Text('Клиент')),DropdownMenuItem(value:'courier',child:Text('Курьер'))],onChanged:(v)=>setState(()=>role=v??'client')),if(register)const SizedBox(height:10),
    TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Номер телефона',hintText:'+7 700 000 00 00',prefixIcon:Icon(Icons.phone))),const SizedBox(height:14),
    if(sent)TextField(controller:code,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Код из SMS',prefixIcon:Icon(Icons.sms))),if(sent)const SizedBox(height:14),
    SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:(sent?verify:send),child:Text(busy?'Подождите...':(sent?'Подтвердить код':'Получить SMS')))),
    if(sent)TextButton(onPressed:busy?null:send,child:const Text('Отправить код ещё раз')),
  ]))));
}

class Dashboard extends StatefulWidget { const Dashboard({super.key}); @override State<Dashboard> createState()=>_DashboardState(); }
class _DashboardState extends State<Dashboard>{
  int tab=0; StreamSubscription<Position>? gps; Position? pos; List<Map<String,dynamic>> orders=[]; List<Map<String,dynamic>> courierApps=[]; List<Map<String,dynamic>> payouts=[]; List<Map<String,dynamic>> notifications=[]; Map<String,dynamic>? selected; String role='client'; Map<String,dynamic>? profile; Map<String,dynamic>? courierProfile; RealtimeChannel? _notificationChannel; final db=Supabase.instance.client;
  @override void initState(){super.initState();_loadRole();_loadProfile();_loadCourierProfile();_listenOrders();_loadNotifications();_listenNotifications();}
  Future<void> _loadNotifications() async {
    try {
      final rows=await db.from('notifications').select().order('created_at',ascending:false).limit(30);
      if(mounted)setState(()=>notifications=List<Map<String,dynamic>>.from(rows));
    } catch(_) {}
  }
  void _listenNotifications(){
    final uid=db.auth.currentUser?.id; if(uid==null)return;
    _notificationChannel=db.channel('bmt_notifications_$uid')
      .onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'notifications',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'user_id',value:uid),callback:(payload){
        final n=Map<String,dynamic>.from(payload.newRecord);
        if(!mounted)return;
        setState(()=>notifications=[n,...notifications.where((x)=>x['id']!=n['id']).take(29)]);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${n['title']??'BMT GO'}: ${n['body']??''}')));
      }).subscribe();
  }
  int get _unreadNotifications=>notifications.where((n)=>n['read_at']==null).length;
  Future<void> _markNotificationsRead() async {
    try { await db.from('notifications').update({'read_at':DateTime.now().toIso8601String()}).eq('user_id',db.auth.currentUser!.id).isFilter('read_at',null); } catch(_) {}
    if(mounted)setState(()=>notifications=[for(final n in notifications){...n,'read_at':n['read_at']??DateTime.now().toIso8601String()}]);
  }
  Future<void> _showNotifications() async {
    await _markNotificationsRead();
    if(!mounted)return;
    showModalBottomSheet(context:context,isScrollControlled:true,builder:(ctx)=>SizedBox(height:MediaQuery.of(ctx).size.height*0.7,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text('Уведомления',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>Navigator.pop(ctx),icon:const Icon(Icons.close))]),
      const Divider(),
      Expanded(child:notifications.isEmpty?const Center(child:Text('Пока уведомлений нет.')):ListView(children:notifications.map((n)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.notifications)),title:Text('${n['title']??'BMT GO'}',style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${n['body']??''}\n${n['created_at']??''}'))).toList()))
    ]))));
  }
  Future<void> _loadRole() async { try{final u=db.auth.currentUser;if(u==null)return;final p=await db.from('profiles').select('role').eq('id',u.id).maybeSingle();if(mounted)setState(()=>role=(p?['role']??'client') as String); if((p?['role']??'client')=='admin'){ await _loadCourierApps(); await _loadPayouts(); }}catch(_){} }
  Future<void> _loadProfile() async {
    final u=db.auth.currentUser; if(u==null)return;
    try { final p=await db.from('profiles').select().eq('id',u.id).maybeSingle(); if(mounted)setState(()=>profile=p); } catch(_) {}
  }
  Future<void> _saveProfile(String name) async {
    final u=db.auth.currentUser; if(u==null)return;
    try { await db.from('profiles').update({'full_name':name.trim(),'updated_at':DateTime.now().toIso8601String()}).eq('id',u.id); await _loadProfile(); msg('Профиль сохранён'); } catch(_) { msg('Не удалось сохранить профиль'); }
  }
  Future<void> _showProfile() async {
    final name=TextEditingController(text:'${profile?['full_name']??''}');
    final phone='${profile?['phone']??db.auth.currentUser?.phone??'—'}';
    await showDialog(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Мой профиль'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        CircleAvatar(radius:32,child:Text((name.text.trim().isEmpty?'B':name.text.trim()[0]).toUpperCase(),style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold))),
        const SizedBox(height:14), TextField(controller:name,decoration:const InputDecoration(labelText:'Имя / ФИО')),
        const SizedBox(height:8), Align(alignment:Alignment.centerLeft,child:Text('Телефон: $phone')),
        const SizedBox(height:4), Align(alignment:Alignment.centerLeft,child:Text('Роль: ${role=='client'?'Клиент':role=='courier'?'Курьер':'Администратор'}')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Закрыть')),FilledButton(onPressed:()async{await _saveProfile(name.text);if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Сохранить'))]
    ));
  }
  Future<void> _showOrderHistory() async {
    final uid=db.auth.currentUser?.id; if(uid==null)return;
    final mine=orders.where((o)=>role=='client'?o['client_id']==uid:o['courier_id']==uid).toList();
    final done=mine.where((o)=>o['status']=='delivered'||o['status']=='cancelled').toList();
    await showModalBottomSheet(context:context,isScrollControlled:true,builder:(ctx)=>SizedBox(height:MediaQuery.of(ctx).size.height*.82,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text('История заказов',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>Navigator.pop(ctx),icon:const Icon(Icons.close))]),
      Text('${done.length} завершённых заказов'),const SizedBox(height:10),
      Expanded(child:done.isEmpty?const Center(child:Text('История пока пустая.')):ListView.separated(itemCount:done.length,itemBuilder:(c,i){final o=done[i];return ListTile(onTap:(){Navigator.pop(ctx);setState(()=>selected=o);},leading:CircleAvatar(child:Icon(o['status']=='delivered'?Icons.check:Icons.close)),title:Text('${o['code']??'Заказ'} • ${o['price']??0} ₸'),subtitle:Text('${o['from_address']??''} → ${o['to_address']??''}'),trailing:_status('${o['status']}'));},separatorBuilder:(_,__)=>const Divider()))
    ]))));
  }
  Future<void> _requestAccountDeletion() async {
    final u=db.auth.currentUser; if(u==null)return;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Удалить аккаунт?'),
      content:const Text('Мы создадим запрос на удаление аккаунта и связанных данных. После обработки вы не сможете войти в этот аккаунт.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Отмена')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Отправить запрос'))],
    ));
    if(ok!=true)return;
    try {
      await db.rpc('request_account_deletion');
      msg('Запрос на удаление отправлен');
    } catch(_) { msg('Не удалось отправить запрос. Проверьте SQL v33.'); }
  }
  Future<void> _showSettings() async {
    bool notificationsOn=true;
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:const Text('Настройки'),content:Column(mainAxisSize:MainAxisSize.min,children:[SwitchListTile(value:notificationsOn,onChanged:(v)=>setD(()=>notificationsOn=v),title:const Text('Уведомления'),subtitle:const Text('Новые заказы и статусы доставки')),ListTile(leading:const Icon(Icons.person),title:const Text('Мой профиль'),onTap:(){Navigator.pop(ctx);_showProfile();}),ListTile(leading:const Icon(Icons.history),title:const Text('История заказов'),onTap:(){Navigator.pop(ctx);_showOrderHistory();}),ListTile(leading:const Icon(Icons.delete_outline,color:Colors.red),title:const Text('Удалить аккаунт',style:TextStyle(color:Colors.red)),onTap:(){Navigator.pop(ctx);_requestAccountDeletion();})]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Готово'))])));
  }
  Future<void> _loadCourierProfile() async { if(db.auth.currentUser==null)return; try{final p=await db.from('courier_profiles').select().eq('id',db.auth.currentUser!.id).maybeSingle();if(mounted)setState(()=>courierProfile=p);}catch(_){} }
  Future<void> _loadCourierApps() async { try { final rows=await db.from('courier_profiles').select().order('created_at',ascending:false); if(mounted)setState(()=>courierApps=List<Map<String,dynamic>>.from(rows)); } catch(_) {} }
  Future<void> _loadPayouts() async { try { final rows=await db.from('courier_payouts').select().order('created_at',ascending:false); if(mounted)setState(()=>payouts=List<Map<String,dynamic>>.from(rows)); } catch(_) {} }
  Future<void> _processPayout(String id,String action,{String? reason}) async { try { await db.rpc('admin_process_courier_payout',params:{'p_payout_id':id,'p_action':action,'p_reason':reason}); await _loadPayouts(); msg(action=='paid'?'Выплата отмечена как оплаченная':'Выплата отклонена'); } catch(_) { msg('Не удалось обработать выплату. Проверьте SQL v25.'); } }
  Future<void> _rejectPayoutDialog(Map<String,dynamic> p) async { final reason=TextEditingController(); await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Отклонить выплату'),content:TextField(controller:reason,maxLines:3,decoration:const InputDecoration(hintText:'Причина отказа')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:(){Navigator.pop(ctx);_processPayout(p['id'],'rejected',reason:reason.text.trim().isEmpty?'Выплата отклонена администратором':reason.text.trim());},child:const Text('Отклонить'))])); }
  Future<void> _reviewCourier(String id,String status,{String? reason}) async { try { await db.rpc('review_courier',params:{'p_courier_id':id,'p_status':status,'p_reason':reason}); await _loadCourierApps(); msg(status=='approved'?'Курьер одобрен':'Заявка отклонена'); } catch(_) { msg('Не удалось изменить статус заявки'); } }
  Future<String?> _uploadCourierPhoto(XFile file,String kind) async { try { final u=db.auth.currentUser; if(u==null)return null; final bytes=await file.readAsBytes(); final path='${u.id}/$kind-${DateTime.now().millisecondsSinceEpoch}.jpg'; await db.storage.from('courier-documents').uploadBinary(path,bytes,fileOptions:const FileOptions(contentType:'image/jpeg',upsert:true)); return path; } catch(e){ msg('Не удалось загрузить фото'); return null; } }
  Future<void> _courierApplication() async { final u=db.auth.currentUser; if(u==null)return; final name=TextEditingController(text:(courierProfile?['full_name']??'') as String); final vehicle=TextEditingController(text:(courierProfile?['vehicle_brand']??'') as String); final number=TextEditingController(text:(courierProfile?['vehicle_number']??'') as String); final license=TextEditingController(text:(courierProfile?['license_number']??'') as String); final doc=TextEditingController(text:(courierProfile?['id_document_number']??'') as String); String transport=(courierProfile?['transport_type']??'car') as String; XFile? docPhoto; XFile? vehiclePhoto; await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:const Text('Заявка курьера'),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(children:[TextField(controller:name,decoration:const InputDecoration(labelText:'ФИО')),DropdownButtonFormField<String>(value:transport,decoration:const InputDecoration(labelText:'Транспорт'),items:const[DropdownMenuItem(value:'car',child:Text('Автомобиль')),DropdownMenuItem(value:'motorbike',child:Text('Мото/скутер')),DropdownMenuItem(value:'bicycle',child:Text('Велосипед')),DropdownMenuItem(value:'foot',child:Text('Пешком'))],onChanged:(v)=>setD(()=>transport=v??'car')),TextField(controller:vehicle,decoration:const InputDecoration(labelText:'Марка/модель')),TextField(controller:number,decoration:const InputDecoration(labelText:'Госномер')),TextField(controller:license,decoration:const InputDecoration(labelText:'Номер водительских прав')),TextField(controller:doc,decoration:const InputDecoration(labelText:'Номер документа')),const SizedBox(height:10),OutlinedButton.icon(onPressed:()async{final f=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:70);if(f!=null)setD(()=>docPhoto=f);},icon:const Icon(Icons.badge),label:Text(docPhoto==null?'Фото документа':'Документ выбран')),OutlinedButton.icon(onPressed:()async{final f=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:70);if(f!=null)setD(()=>vehiclePhoto=f);},icon:const Icon(Icons.directions_car),label:Text(vehiclePhoto==null?'Фото транспорта':'Транспорт выбран'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:()async{try{String? dp=courierProfile?['document_photo_path'];String? vp=courierProfile?['vehicle_photo_path'];if(docPhoto!=null)dp=await _uploadCourierPhoto(docPhoto!,'document');if(vehiclePhoto!=null)vp=await _uploadCourierPhoto(vehiclePhoto!,'vehicle');await db.from('courier_profiles').upsert({'id':u.id,'full_name':name.text.trim(),'transport_type':transport,'vehicle_brand':vehicle.text.trim(),'vehicle_number':number.text.trim(),'license_number':license.text.trim(),'id_document_number':doc.text.trim(),'document_photo_path':dp,'vehicle_photo_path':vp,'status':'pending'});await _loadCourierProfile();if(ctx.mounted)Navigator.pop(ctx);msg('Заявка отправлена на проверку');}catch(_){msg('Не удалось сохранить заявку');}},child:const Text('Отправить'))]))); }
  void _listenOrders(){db.from('orders').stream(primaryKey:['id']).order('created_at').listen((x){if(mounted)setState(()=>orders=x.reversed.toList());});}
  void msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  Future<void> logout()async{await db.auth.signOut();}
  Future<void> startGps()async{if(!await Geolocator.isLocationServiceEnabled()){msg('Включите геолокацию');return;}var p=await Geolocator.checkPermission();if(p==LocationPermission.denied)p=await Geolocator.requestPermission();if(p==LocationPermission.denied||p==LocationPermission.deniedForever){msg('Нет разрешения на геолокацию');return;}await gps?.cancel();gps=Geolocator.getPositionStream(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high,distanceFilter:15)).listen((p){if(mounted)setState(()=>pos=p);_saveLocation(p);});msg('GPS курьера включён');}
  Future<void> _saveLocation(Position p)async{final u=db.auth.currentUser;if(u==null)return;try{await db.from('courier_locations').upsert({'courier_id':u.id,'lat':p.latitude,'lng':p.longitude,'updated_at':DateTime.now().toIso8601String()});}catch(_){} }
  Future<void> accept(String id)async{try{await db.rpc('accept_order',params:{'p_order_id':id});msg('Заказ принят');}catch(_){msg('Заказ уже занят или произошла ошибка');}}
  Future<String?> assignNearest(String id)async{try{final r=await db.rpc('assign_nearest_courier',params:{'p_order_id':id,'p_max_distance_km':15});if(r==null)return null;return r.toString();}catch(_){return null;}}
  Future<void> advance(String id,String status)async{try{await db.rpc('advance_order_status',params:{'p_order_id':id,'p_status':status});}catch(_){msg('Не удалось изменить статус');}}
  Future<void> markCashPaid(String id)async{try{await db.rpc('mark_order_paid',params:{'p_order_id':id,'p_payment_method':'cash'});msg('Наличные отмечены как полученные');}catch(_){msg('Не удалось отметить оплату');}}
  Future<void> rateOrder(Map<String,dynamic> o) async {
    if(o['status']!='delivered' || o['courier_id']==null || o['client_id']!=db.auth.currentUser?.id) return;
    int rating=5; final comment=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
      title:const Text('Оцените курьера'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('Как прошла доставка?'),
        const SizedBox(height:12),
        Wrap(spacing:6,children:List.generate(5,(i)=>IconButton(onPressed:()=>setD(()=>rating=i+1),icon:Icon(i<rating?Icons.star:Icons.star_border),iconSize:34))),
        TextField(controller:comment,maxLines:3,decoration:const InputDecoration(labelText:'Комментарий (необязательно)')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:()async{
        try{await db.rpc('submit_order_rating',params:{'p_order_id':o['id'],'p_rating':rating,'p_comment':comment.text.trim().isEmpty?null:comment.text.trim()});if(ctx.mounted)Navigator.pop(ctx);msg('Спасибо! Оценка сохранена.');}
        catch(_){msg('Не удалось сохранить оценку');}
      },child:const Text('Оценить'))]
    )));
  }
  String paymentLabel(dynamic m)=>m=='cash'?'Наличные':'Карта';
  String paymentStatusLabel(dynamic s)=>s=='paid'?'Оплачено':s=='failed'?'Ошибка оплаты':'Ожидает оплаты';
  int _courierEarning(Map<String,dynamic> o){
    final price=(o['price'] as num?)?.toInt() ?? 0;
    return (price*0.80).round();
  }
  List<Map<String,dynamic>> _courierDelivered(){
    final uid=db.auth.currentUser?.id;
    return orders.where((o)=>o['courier_id']==uid && o['status']=='delivered').toList();
  }
  int _sumEarnings(Iterable<Map<String,dynamic>> rows)=>rows.fold<int>(0,(sum,o)=>sum+_courierEarning(o));
  Future<void> _loadMyPayouts() async { try { final rows=await db.from('courier_payouts').select().eq('courier_id',db.auth.currentUser!.id).order('created_at',ascending:false); if(mounted)setState(()=>payouts=List<Map<String,dynamic>>.from(rows)); } catch(_) {} }
  int _reservedPayouts(){ return payouts.where((p)=>p['status']=='pending'||p['status']=='paid').fold<int>(0,(s,p)=>s+((p['amount'] as num?)?.toInt()??0)); }
  Widget _earningsCard(){
    final done=_courierDelivered();
    final now=DateTime.now();
    final day=done.where((o){final d=DateTime.tryParse('${o['updated_at']??o['created_at']}');return d!=null&&d.year==now.year&&d.month==now.month&&d.day==now.day;});
    final weekStart=now.subtract(Duration(days:now.weekday-1));
    final week=done.where((o){final d=DateTime.tryParse('${o['updated_at']??o['created_at']}');return d!=null&&!d.isBefore(DateTime(weekStart.year,weekStart.month,weekStart.day));});
    final month=done.where((o){final d=DateTime.tryParse('${o['updated_at']??o['created_at']}');return d!=null&&d.year==now.year&&d.month==now.month;});
    return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text('Мой заработок',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>setState((){}),icon:const Icon(Icons.refresh))]),
      const Text('Расчёт для демонстрации: 80% стоимости заказа'),const SizedBox(height:12),
      Row(children:[Expanded(child:_stat('Сегодня','${_sumEarnings(day)} ₸')),const SizedBox(width:8),Expanded(child:_stat('Неделя','${_sumEarnings(week)} ₸')),const SizedBox(width:8),Expanded(child:_stat('Месяц','${_sumEarnings(month)} ₸'))]),
      const SizedBox(height:8),Text('Выполнено за месяц: ${month.length} доставок'),
    ])));
  }
  Widget _courierHistory(){
    final done=_courierDelivered();
    return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('История доставок',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),const SizedBox(height:8),
      if(done.isEmpty) const Text('Пока нет завершённых доставок.'),
      ...done.take(20).map((o)=>ListTile(contentPadding:EdgeInsets.zero,leading:const CircleAvatar(child:Icon(Icons.check)),title:Text(o['code']??'Заказ'),subtitle:Text('${o['to_address']??'Доставка'} • ${o['price']??0} ₸'),trailing:Text('+${_courierEarning(o)} ₸',style:const TextStyle(fontWeight:FontWeight.w800)))),
    ])));
  }
  Future<void> _requestPayout() async {
    await _loadMyPayouts();
    final earned=_sumEarnings(_courierDelivered()); final available=earned-_reservedPayouts();
    if(available<=0){msg('Нет доступного остатка для выплаты');return;}
    final account=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Запрос выплаты'),content:Column(mainAxisSize:MainAxisSize.min,children:[Text('Доступно: $available ₸'),const SizedBox(height:10),TextField(controller:account,decoration:const InputDecoration(labelText:'Карта / счёт для выплаты'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:()async{try{await db.rpc('request_courier_payout',params:{'p_amount':available,'p_destination':account.text.trim()});await _loadMyPayouts();if(ctx.mounted)Navigator.pop(ctx);msg('Запрос выплаты отправлен');}catch(_){msg('Не удалось отправить запрос выплаты');}},child:const Text('Запросить'))]));
  }
  Widget _payoutHistory(){ return Card(child:Padding(padding:EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('История выплат',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800))),IconButton(onPressed:_loadMyPayouts,icon:Icon(Icons.refresh))]),if(payouts.isEmpty)Text('Выплат пока нет.'),...payouts.take(20).map((p)=>ListTile(contentPadding:EdgeInsets.zero,leading:Icon(p['status']=='paid'?Icons.check_circle:p['status']=='rejected'?Icons.cancel:Icons.hourglass_top),title:Text('${p['amount']??0} ₸'),subtitle:Text('${p['destination']??'-'}${p['rejection_reason']!=null?' • ${p['rejection_reason']}':''}'),trailing:_status('${p['status']??'pending'}')))]))); }

  @override void dispose(){gps?.cancel();_notificationChannel?.unsubscribe();super.dispose();}
  @override Widget build(BuildContext c){final isCourier=role=='courier';final isAdmin=role=='admin';return Scaffold(appBar:AppBar(backgroundColor:Colors.black,foregroundColor:Colors.white,title:const Text('BMT GO',style:TextStyle(fontWeight:FontWeight.w900)),actions:[Stack(children:[IconButton(onPressed:_showNotifications,icon:const Icon(Icons.notifications)),if(_unreadNotifications>0)Positioned(right:6,top:6,child:Container(padding:const EdgeInsets.all(3),decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle),child:Text('${_unreadNotifications>9?'9+':_unreadNotifications}',style:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.bold))))]),IconButton(onPressed:_showSettings,icon:const Icon(Icons.settings)),IconButton(onPressed:logout,icon:const Icon(Icons.logout))]),body:selected==null?(isAdmin?_admin():isCourier?_courier():_client()):_orderDetails(selected!),bottomNavigationBar:null);}
  Widget _client()=>ListView(padding:const EdgeInsets.all(14),children:[_brandHero('Доставка','Быстро. Просто. Рядом.'),const SizedBox(height:14),_actionCard(Icons.person,'Мой профиль','Имя, телефон и роль аккаунта',_showProfile),const SizedBox(height:10),_actionCard(Icons.history,'История заказов','Ваши завершённые доставки',_showOrderHistory),const SizedBox(height:10),_actionCard(Icons.add_location_alt,'Создать заказ','Укажите откуда и куда доставить',_createOrderDialog),const SizedBox(height:12),SizedBox(height:250,child:BmtMap(position:pos)),const SizedBox(height:12),...orders.where((o)=>o['client_id']==db.auth.currentUser?.id).map((o)=>_orderCard(o,'client'))]);
  Widget _courier(){ final st=(courierProfile?['status']??'none') as String; if(st!='approved') return ListView(padding:EdgeInsets.all(18),children:[_brandHero('Стать курьером','Зарабатывайте с BMT GO.'),SizedBox(height:8),Text(st=='pending'?'Заявка отправлена. Дождитесь проверки документов.':st=='rejected'?'Заявка отклонена. Исправьте данные и отправьте её снова.':'Заполните анкету и отправьте документы на проверку.'),SizedBox(height:18),Card(child:Padding(padding:EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Статус: ${st=='none'?'не подана':st}',style:TextStyle(fontWeight:FontWeight.bold)),SizedBox(height:12),FilledButton.icon(onPressed:_courierApplication,icon:Icon(Icons.edit_document),label:Text(st=='none'?'Заполнить заявку':'Изменить заявку'))])))]); return ListView(padding:EdgeInsets.all(14),children:[_brandHero('Работа курьера','Заказы рядом. Заработок под контролем.'),Row(children:[Expanded(child:Text('Статус работы',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:startGps,icon:Icon(Icons.gps_fixed),label:Text('GPS'))]),SizedBox(height:12),_actionCard(Icons.person,'Мой профиль','Данные аккаунта курьера',_showProfile),SizedBox(height:8),_actionCard(Icons.history,'История заказов','Все завершённые доставки',_showOrderHistory),SizedBox(height:12),_earningsCard(),SizedBox(height:8),FilledButton.icon(onPressed:_requestPayout,icon:Icon(Icons.account_balance_wallet),label:Text('Запросить выплату')),SizedBox(height:12),_courierHistory(),SizedBox(height:12),_payoutHistory(),SizedBox(height:12),SizedBox(height:250,child:BmtMap(position:pos)),SizedBox(height:12),...orders.where((o){final uid=db.auth.currentUser?.id; return o['status']!='cancelled'&&o['status']!='delivered'&&(o['courier_id']==uid||o['status']=='searching');}).map((o)=>_orderCard(o,'courier'))]); }
  Widget _admin()=>ListView(padding:EdgeInsets.all(14),children:[_brandHero('Панель BMT GO','Управление заказами и курьерами.'),SizedBox(height:12),Row(children:[Expanded(child:_stat('Заказы','${orders.length}')),SizedBox(width:8),Expanded(child:_stat('Выручка','${orders.fold<num>(0,(s,o)=>s+(o['price']??0))} ₸'))]),SizedBox(height:18),Row(children:[Expanded(child:Text('Заявки курьеров',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800))),IconButton(onPressed:_loadCourierApps,icon:Icon(Icons.refresh))]),SizedBox(height:8),...courierApps.map(_courierReviewCard),SizedBox(height:18),Row(children:[Expanded(child:Text('Выплаты курьерам',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800))),IconButton(onPressed:_loadPayouts,icon:Icon(Icons.refresh))]),SizedBox(height:8),...payouts.where((p)=>p['status']=='pending').map(_payoutAdminCard),SizedBox(height:18),Text('Заказы',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),SizedBox(height:8),...orders.map((o)=>_orderCard(o,'admin'))]);
  Widget _payoutAdminCard(Map<String,dynamic> p){return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${p['amount']??0} ₸',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),Text('Курьер: ${p['courier_id']??'-'}'),Text('Куда: ${p['destination']??'-'}'),Text('Создано: ${p['created_at']??'-'}'),const SizedBox(height:10),Row(children:[Expanded(child:FilledButton.icon(onPressed:()=>_processPayout(p['id'],'paid'),icon:const Icon(Icons.check),label:const Text('Выплачено'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:()=>_rejectPayoutDialog(p),icon:const Icon(Icons.close),label:const Text('Отклонить')))])] ))); }
  Widget _courierReviewCard(Map<String,dynamic> c){final status=(c['status']??'pending') as String; final name=(c['full_name']??'Без имени') as String; return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(name,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800))),_status(status)]),const SizedBox(height:7),Text('Транспорт: ${c['transport_type']??'-'}'),Text('Авто: ${c['vehicle_brand']??'-'}  ${c['vehicle_number']??''}'),Text('Документ: ${c['id_document_number']??'-'}'),if(c['document_photo_path']!=null)const Text('Фото документа: загружено'),if(c['vehicle_photo_path']!=null)const Text('Фото транспорта: загружено'),if(c['rejection_reason']!=null&&('${c['rejection_reason']}'.isNotEmpty))Text('Причина: ${c['rejection_reason']}'),if(status=='pending')Padding(padding:const EdgeInsets.only(top:10),child:Row(children:[Expanded(child:FilledButton.icon(onPressed:()=>_reviewCourier(c['id'],'approved'),icon:const Icon(Icons.check),label:const Text('Одобрить'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:()=>_rejectCourierDialog(c),icon:const Icon(Icons.close),label:const Text('Отклонить')))]))])));}
  Future<void> _rejectCourierDialog(Map<String,dynamic> c) async { final reason=TextEditingController(); await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Причина отказа'),content:TextField(controller:reason,maxLines:3,decoration:const InputDecoration(hintText:'Например: нечёткое фото документа')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:(){Navigator.pop(ctx);_reviewCourier(c['id'],'rejected',reason:reason.text.trim().isEmpty?'Требуется исправить данные':reason.text.trim());},child:const Text('Отклонить'))])); }
  Widget _stat(String a,String b)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a),Text(b,style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold))])));
  Widget _brandHero(String title,String subtitle)=>Container(
    margin:const EdgeInsets.only(bottom:14),padding:const EdgeInsets.all(18),
    decoration:BoxDecoration(color:Colors.black,borderRadius:BorderRadius.circular(22)),
    child:Row(children:[Container(width:52,height:52,decoration:BoxDecoration(color:yellow,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.local_shipping_rounded,color:Colors.black,size:30)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:Colors.white70,fontSize:14))]))]);

  Widget _actionCard(IconData icon,String title,String sub,VoidCallback onTap)=>Card(child:ListTile(leading:CircleAvatar(backgroundColor:yellow,child:Icon(icon,color:Colors.black)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(sub),trailing:const Icon(Icons.chevron_right),onTap:onTap));
  Widget _orderCard(Map<String,dynamic> o,String r){final s=o['status']??'searching';final pm=o['payment_method']??'cash';final ps=o['payment_status']??'pending';Widget? a;if(r=='courier'&&s=='searching'&&o['courier_id']==null)a=FilledButton(onPressed:()=>accept(o['id']),child:const Text('Принять'));if(r=='courier'&&s=='assigned'&&o['courier_id']==db.auth.currentUser?.id)a=FilledButton(onPressed:()=>advance(o['id'],'picked'),child:const Text('Забрал'));
    if(r=='courier'&&s=='assigned'&&o['courier_id']!=db.auth.currentUser?.id)a=null;if(r=='courier'&&s=='picked')a=FilledButton(onPressed:()=>advance(o['id'],'delivering'),child:const Text('В пути'));if(r=='courier'&&s=='delivering')a=FilledButton(onPressed:()=>advance(o['id'],'delivered'),child:const Text('Доставлено'));if(r=='courier'&&s=='delivered'&&pm=='cash'&&ps!='paid')a=FilledButton.icon(onPressed:()=>markCashPaid(o['id']),icon:const Icon(Icons.payments),label:const Text('Оплата получена'));return Card(child:InkWell(onTap:()=>setState(()=>selected=o),child:Padding(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(o['code']??'BMT GO',style:const TextStyle(fontWeight:FontWeight.w900))),_status(s)]),const SizedBox(height:7),Text('${o['from_address']??'Откуда'} → ${o['to_address']??'Куда'}'),const SizedBox(height:5),Text('${o['price']??0} ₸'),Text('Оплата: ${paymentLabel(pm)} • ${paymentStatusLabel(ps)}'),if(a!=null)Align(alignment:Alignment.centerRight,child:a)]))));}
  Widget _status(String s)=>Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:Colors.black,borderRadius:BorderRadius.circular(20)),child:Text(s,style:const TextStyle(color:Colors.white,fontSize:12)));
  Widget _orderDetails(Map<String,dynamic> o)=>Scaffold(
  appBar:AppBar(title:Text(o['code']??'Заказ'),leading:IconButton(icon:const Icon(Icons.arrow_back),onPressed:()=>setState(()=>selected=null))),
  body:ListView(padding:const EdgeInsets.all(16),children:[
    SizedBox(height:300,child:LiveOrderMap(order:o, fallbackPosition:pos)),
    const SizedBox(height:16),
    _OrderProgress(status:(o['status']??'searching').toString()),
    const SizedBox(height:16),
    Text('${o['from_address']??'Откуда'}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    const Icon(Icons.arrow_downward),
    Text('${o['to_address']??'Куда'}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    const SizedBox(height:16),
    _status(o['status']??''),
    const SizedBox(height:12),
    Text('Стоимость: ${o['price']??0} ₸'),
    Text('Способ оплаты: ${paymentLabel(o['payment_method'])}'),
    Text('Статус оплаты: ${paymentStatusLabel(o['payment_status'])}'),
    if(o['rating']!=null)Text('Оценка курьера: ${o['rating']} ⭐'),
    if(o['client_id']==db.auth.currentUser?.id && o['status']=='delivered' && o['rating']==null)Padding(padding:const EdgeInsets.only(top:12),child:FilledButton.icon(onPressed:()=>rateOrder(o),icon:const Icon(Icons.star),label:const Text('Оценить курьера'))),
    if(o['route_distance_km']!=null)Text('Маршрут: ${((o['route_distance_km'] as num).toDouble()).toStringAsFixed(1)} км'),
    if(o['route_duration_min']!=null)Text('Время в пути: около ${o['route_duration_min']} мин'),
  ]));
  Future<LatLng?> _pickMapPoint({LatLng? initial}) async {
  return Navigator.push<LatLng>(context, MaterialPageRoute(builder: (_) => MapPointPicker(initial: initial ?? LatLng(pos?.latitude ?? 51.1694, pos?.longitude ?? 71.4491))));
}

Future<void> _createOrderDialog() async {
  final from=TextEditingController(text: 'Текущее местоположение');
  final to=TextEditingController();
  LatLng? pickup = pos == null ? null : LatLng(pos!.latitude,pos!.longitude);
  LatLng? dropoff;
  double? distance;
  int price=1500;
  int? durationMin;
  List<LatLng> routePoints=[];
  String paymentMethod='cash';
  bool routing=false;
  await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
    title:const Text('Новый заказ'),
    content:SizedBox(width:430,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      TextField(controller:from,decoration:const InputDecoration(labelText:'Откуда',prefixIcon:Icon(Icons.trip_origin))),
      const SizedBox(height:8),
      TextField(controller:to,decoration:const InputDecoration(labelText:'Куда / адрес получателя',prefixIcon:Icon(Icons.location_on))),
      const SizedBox(height:10),
      OutlinedButton.icon(onPressed:()async{final p=await _pickMapPoint(initial:dropoff ?? pickup);if(p!=null){setD((){dropoff=p;routing=true;});if(pickup!=null){final rr=await RouteService.getRoute(origin:pickup!,destination:p);if(ctx.mounted)setD((){if(rr!=null){distance=rr.distanceKm;durationMin=rr.durationMin;routePoints=rr.points;}else{distance=Geolocator.distanceBetween(pickup!.latitude,pickup!.longitude,p.latitude,p.longitude)/1000;durationMin=null;routePoints=[pickup!,p];}price=calculateDeliveryPrice(distance!);routing=false;});}}}},icon:const Icon(Icons.map),label:Text(dropoff==null?'Указать точку доставки на карте':'Точка доставки выбрана')),
      double? durationMin;
if(routing) const Padding(padding:EdgeInsets.only(top:8),child:LinearProgressIndicator()),
      , 
      const SizedBox(height:8),
      Card(child:ListTile(title:const Text('Ориентировочная стоимость'),trailing:Text('$price ₸',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)))),
      const SizedBox(height:8),
      DropdownButtonFormField<String>(value:paymentMethod,decoration:const InputDecoration(labelText:'Способ оплаты',prefixIcon:Icon(Icons.payment)),items:const[DropdownMenuItem(value:'cash',child:Text('Наличные курьеру')),DropdownMenuItem(value:'card',child:Text('Банковская карта'))],onChanged:(v)=>setD(()=>paymentMethod=v??'cash')),
      const SizedBox(height:6),
      const Text('При оплате картой откроется защищённая страница платёжного шлюза. Данные карты приложение BMT GO не хранит.',style:TextStyle(fontSize:12)),
      const Text('Цена рассчитывается по дорожному маршруту, если подключён Google Directions API. Без API используется расстояние по прямой.',style:TextStyle(fontSize:12)),
    ]))),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Отмена')),FilledButton(onPressed:()async{
      if(dropoff==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Укажите точку доставки на карте')));return;}
      try{final u=db.auth.currentUser;if(u==null)return;
        final inserted=await db.from('orders').insert({'client_id':u.id,'from_address':from.text.trim(),'to_address':to.text.trim().isEmpty?'Точка на карте':'${to.text.trim()}','price':price,'status':'searching','pickup_lat':pickup?.latitude,'pickup_lng':pickup?.longitude,'dropoff_lat':dropoff!.latitude,'dropoff_lng':dropoff!.longitude,'distance_km':distance,'route_distance_km':distance,'route_duration_min':durationMin,'payment_method':paymentMethod,'payment_status':'pending'}).select('id').single();
        final orderId=inserted['id'].toString(); final assigned=await assignNearest(orderId); if(ctx.mounted)Navigator.pop(ctx); if(paymentMethod=='card'){ try{final opened=await PaymentService.startCardPayment(orderId); msg(opened?'Открываем защищённую страницу оплаты карты...':'Не удалось открыть оплату картой. Попробуйте ещё раз.');}catch(_){msg('Платёжный шлюз ещё не настроен.');} } else { msg(assigned==null?'Заказ создан. Ищем ближайшего курьера...':'Заказ создан и назначен ближайшему курьеру.'); }
      }catch(_){msg('Не удалось создать заказ');}
    },child:const Text('Создать заказ'))]));
}
}


class LiveOrderMap extends StatefulWidget {
  final Map<String,dynamic> order;
  final Position? fallbackPosition;
  const LiveOrderMap({super.key,required this.order,this.fallbackPosition});
  @override State<LiveOrderMap> createState()=>_LiveOrderMapState();
}

class _LiveOrderMapState extends State<LiveOrderMap> {
  StreamSubscription<List<Map<String,dynamic>>>? sub;
  LatLng? courier;
  GoogleMapController? controller;

  @override void initState(){super.initState();_start();}
  Future<void> _start() async {
    final courierId=widget.order['courier_id']?.toString();
    if(courierId==null || courierId.isEmpty) return;
    try {
      final db=Supabase.instance.client;
      final first=await db.from('courier_locations').select('lat,lng').eq('courier_id',courierId).maybeSingle();
      if(first!=null && mounted){setState(()=>courier=LatLng((first['lat'] as num).toDouble(),(first['lng'] as num).toDouble()));}
      sub=db.from('courier_locations').stream(primaryKey:['courier_id']).eq('courier_id',courierId).listen((rows){
        if(rows.isEmpty || !mounted)return;
        final r=rows.first; final p=LatLng((r['lat'] as num).toDouble(),(r['lng'] as num).toDouble());
        setState(()=>courier=p);
        controller?.animateCamera(CameraUpdate.newLatLng(p));
      });
    } catch (_) {}
  }
  @override void dispose(){sub?.cancel();super.dispose();}
  @override Widget build(BuildContext context){
    final pickupLat=(widget.order['pickup_lat'] as num?)?.toDouble();
    final pickupLng=(widget.order['pickup_lng'] as num?)?.toDouble();
    final dropLat=(widget.order['dropoff_lat'] as num?)?.toDouble();
    final dropLng=(widget.order['dropoff_lng'] as num?)?.toDouble();
    final fallback=LatLng(widget.fallbackPosition?.latitude??51.1694,widget.fallbackPosition?.longitude??71.4491);
    final center=courier ?? (pickupLat!=null&&pickupLng!=null?LatLng(pickupLat,pickupLng):fallback);
    final markers=<Marker>{};
    if(courier!=null)markers.add(Marker(markerId:const MarkerId('live_courier'),position:courier!,infoWindow:const InfoWindow(title:'Курьер BMT GO')));
    if(pickupLat!=null&&pickupLng!=null)markers.add(Marker(markerId:const MarkerId('pickup'),position:LatLng(pickupLat,pickupLng),infoWindow:const InfoWindow(title:'Забор')));
    if(dropLat!=null&&dropLng!=null)markers.add(Marker(markerId:const MarkerId('dropoff'),position:LatLng(dropLat,dropLng),infoWindow:const InfoWindow(title:'Доставка')));
    final points=<LatLng>[]; if(courier!=null)points.add(courier!); if(pickupLat!=null&&pickupLng!=null)points.add(LatLng(pickupLat,pickupLng)); if(dropLat!=null&&dropLng!=null)points.add(LatLng(dropLat,dropLng));
    return ClipRRect(borderRadius:BorderRadius.circular(16),child:Stack(children:[
      GoogleMap(initialCameraPosition:CameraPosition(target:center,zoom:13),onMapCreated:(c)=>controller=c,markers:markers,polylines:{if(points.length>=2)Polyline(polylineId:const PolylineId('live_route'),points:points,width:5)},myLocationEnabled:false,zoomControlsEnabled:false),
      if(widget.order['courier_id']!=null && courier==null)Positioned(top:10,left:10,right:10,child:Card(child:Padding(padding:const EdgeInsets.all(10),child:Text('Ждём GPS курьера…',textAlign:TextAlign.center)))),
    ]));
  }
}

class _OrderProgress extends StatelessWidget {
  final String status; const _OrderProgress({required this.status});
  int get step => const {'searching':0,'assigned':1,'picked':2,'delivering':3,'delivered':4}.containsKey(status) ? const {'searching':0,'assigned':1,'picked':2,'delivering':3,'delivered':4}[status]! : 0;
  @override Widget build(BuildContext c)=>Row(children:[for(int i=0;i<5;i++)Expanded(child:Column(children:[CircleAvatar(radius:13,child:Text('${i+1}',style:const TextStyle(fontSize:11))),const SizedBox(height:4),Text(const ['Поиск','Назначен','Забран','В пути','Готово'][i],textAlign:TextAlign.center,style:const TextStyle(fontSize:10))]))]);
}

class MapPointPicker extends StatefulWidget { final LatLng initial; const MapPointPicker({super.key,required this.initial}); @override State<MapPointPicker> createState()=>_MapPointPickerState(); }
class _MapPointPickerState extends State<MapPointPicker>{late LatLng point; GoogleMapController? map; @override void initState(){super.initState();point=widget.initial;} @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Выберите точку доставки'),actions:[TextButton(onPressed:()=>Navigator.pop(context,point),child:const Text('ГОТОВО'))]),body:GoogleMap(initialCameraPosition:CameraPosition(target:point,zoom:14),onMapCreated:(x)=>map=x,onTap:(p)=>setState(()=>point=p),markers:{Marker(markerId:const MarkerId('selected'),position:point,draggable:true,onDragEnd:(p)=>setState(()=>point=p))},myLocationButtonEnabled:true,zoomControlsEnabled:false));}

class BmtMap extends StatelessWidget {
  final Position? position;
  final Map<String,dynamic>? order;
  const BmtMap({super.key,this.position,this.order});
  @override Widget build(BuildContext c) {
    final fallback=LatLng(position?.latitude??51.1694,position?.longitude??71.4491);
    final pickupLat=(order?['pickup_lat'] as num?)?.toDouble();
    final pickupLng=(order?['pickup_lng'] as num?)?.toDouble();
    final dropLat=(order?['dropoff_lat'] as num?)?.toDouble();
    final dropLng=(order?['dropoff_lng'] as num?)?.toDouble();
    final pts=<LatLng>[];
    if(pickupLat!=null&&pickupLng!=null)pts.add(LatLng(pickupLat,pickupLng));
    if(dropLat!=null&&dropLng!=null)pts.add(LatLng(dropLat,dropLng));
    if(position!=null)pts.add(fallback);
    final markers=<Marker>{};
    if(position!=null)markers.add(Marker(markerId:const MarkerId('courier'),position:fallback,infoWindow:const InfoWindow(title:'Курьер BMT GO')));
    if(pickupLat!=null&&pickupLng!=null)markers.add(Marker(markerId:const MarkerId('pickup'),position:LatLng(pickupLat,pickupLng),infoWindow:const InfoWindow(title:'Забор')));
    if(dropLat!=null&&dropLng!=null)markers.add(Marker(markerId:const MarkerId('dropoff'),position:LatLng(dropLat,dropLng),infoWindow:const InfoWindow(title:'Доставка')));
    return ClipRRect(borderRadius:BorderRadius.circular(16),child:GoogleMap(initialCameraPosition:CameraPosition(target:pts.isNotEmpty?pts.first:fallback,zoom:pts.length>1?12:16),markers:markers,polylines:{if(pts.length>=2)Polyline(polylineId:const PolylineId('route_preview'),points:pts,width:5)},myLocationEnabled:position!=null,myLocationButtonEnabled:true,zoomControlsEnabled:false));
  }
}

