import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/duo_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: DuoConfig.supabaseUrl,
    publishableKey: DuoConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: DuoApp(),
    ),
  );
}
