import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/services/auth_service.dart';
import 'data/services/task_service.dart';
import 'data/services/calendar_service.dart';
import 'presentation/screens/home_page.dart';
import 'presentation/screens/login_page.dart';
import 'presentation/viewmodels/auth_cubit.dart';
import 'presentation/viewmodels/auth_state.dart';
import 'presentation/viewmodels/task_cubit.dart';
import 'presentation/viewmodels/calendar_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza i formattatori di data per la lingua italiana (per TableCalendar e Intl)
  await initializeDateFormatting('it_IT', null);

  bool isFirebaseSupported = kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  if (isFirebaseSupported) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint("Firebase non inizializzato: $e");
    }
  } else {
    debugPrint("Ambiente di test desktop rilevato: Firebase core disabilitato.");
  }

  runApp(const AgendaSyncApp());
}

class AgendaSyncApp extends StatelessWidget {
  const AgendaSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(AuthService())..checkAuthStatus(),
        ),
        BlocProvider(
          create: (context) => TaskCubit(TaskService()),
        ),
        BlocProvider(
          create: (context) => CalendarCubit(CalendarService()),
        ),
      ],
      child: MaterialApp(
        title: 'Agenda Sync',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        // Aggiunti i delegati di localizzazione per forzare la lingua italiana
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('it', 'IT'),
        ],
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading || state is AuthInitial) {
              return const Scaffold(
                backgroundColor: Color(0xFF1E1B4B),
                body: Center(child: CircularProgressIndicator(color: Colors.white)),
              );
            }
            if (state is AuthAuthenticated) {
              return const HomePage();
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}