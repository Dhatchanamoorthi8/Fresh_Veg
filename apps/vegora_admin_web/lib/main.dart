import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vegora_core/vegora_core.dart';

import 'app/admin_app.dart';
import 'app/admin_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    AdminAuthListenable.instance.initialize();
  }

  runApp(const ProviderScope(child: VegoraAdminApp()));
}
