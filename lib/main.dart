import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/widgets.dart';
import 'package:labelwise/app/app.dart';
import 'package:labelwise/core/config/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  debugPrint(
    'Env check: '
    'SUPABASE_URL=${dotenv.env['SUPABASE_URL']?.isNotEmpty ?? false}, '
    'SUPABASE_ANON_KEY=${dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty ?? false}',
  );
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  runApp(const LabelWiseApp());
}
