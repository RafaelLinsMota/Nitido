import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nitido/core/theme/app_theme.dart';
import 'package:nitido/core/supabase/supabase_config.dart';
import 'package:nitido/features/auth/auth_screen.dart';
import 'package:nitido/features/navigation/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await initializeDateFormatting('pt_BR');

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: NitidoApp(),
    ),
  );
}

class NitidoApp extends StatelessWidget {
  const NitidoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nítido',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('pt', 'BR'),
      home: const AuthGate(),
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const MainShell(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SupabaseConfig.auth.currentSession;

    if (session != null) {
      return const MainShell();
    }

    return const AuthScreen();
  }
}
