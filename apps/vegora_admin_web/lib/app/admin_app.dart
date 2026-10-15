import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegora_core/vegora_core.dart';

import 'admin_router.dart';

class VegoraAdminApp extends ConsumerWidget {
  const VegoraAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Vegora • Operations Command Center',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: adminRouter,
    );
  }
}
