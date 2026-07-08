import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/monetization_service.dart';
import 'core/services/revenuecat_service.dart';
import 'data/supabase/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  if (SupabaseService.isInitialized) {
    await RevenueCatService.instance.initialize();
    await MonetizationService.instance.initializePremiumWatcher();
  }
  runApp(const FreedomCircleApp());
}
