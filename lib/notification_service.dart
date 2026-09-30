import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class BmtNotifications {
  static Future<void> init(SupabaseClient db) async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null) await _saveToken(db, token);
      messaging.onTokenRefresh.listen((t) => _saveToken(db, t));
      FirebaseMessaging.onMessage.listen((message) {});
    } catch (_) {
      // Firebase configuration is supplied by the app owner.
      // The app continues to work without push until Firebase is configured.
    }
  }

  static Future<void> _saveToken(SupabaseClient db, String token) async {
    final user = db.auth.currentUser;
    if (user == null) return;
    await db.from('push_tokens').upsert({
      'user_id': user.id,
      'token': token,
      'platform': 'mobile',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
