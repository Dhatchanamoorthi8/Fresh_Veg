import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegora_core/vegora_core.dart';

import 'delivery_router.dart';

class VegoraDeliveryApp extends ConsumerWidget {
  const VegoraDeliveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Vegora Partner • Delivery Fleet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: deliveryRouter,
    );
  }
}
