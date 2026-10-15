import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegora_core/vegora_core.dart';

import 'customer_router.dart';

class VegoraCustomerApp extends ConsumerWidget {
  const VegoraCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Vegora • Freshness at Your Doorstep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: customerRouter,
    );
  }
}
