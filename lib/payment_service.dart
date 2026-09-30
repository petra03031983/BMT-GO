import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  static Future<bool> startCardPayment(String orderId) async {
    final result = await Supabase.instance.client.functions.invoke(
      'freedompay-create-payment',
      body: {'order_id': orderId},
    );
    final data = result.data;
    if (data is Map && data['redirect_url'] is String) {
      return launchUrl(Uri.parse(data['redirect_url'] as String), mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
