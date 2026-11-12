import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/save_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/cubit/language_cubit.dart';
import 'presentation/cubit/theme_cubit.dart';
import 'presentation/cubit/save_cubit.dart';
import 'presentation/cubit/story_cubit.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/cubit/auth/auth_cubit.dart';
import 'presentation/cubit/auth/auth_state.dart';
import 'presentation/widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final saveService = SaveService(prefs: prefs);
  final authRepository = AuthRepositoryImpl();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authRepository: authRepository)..checkAuthStatus(),
        ),
        BlocProvider<LanguageCubit>(
          create: (context) => LanguageCubit(prefs: prefs),
        ),
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
        BlocProvider<SaveCubit>(
          create: (context) => SaveCubit(
            saveService: saveService,
            authRepository: authRepository,
          )..loadGlobalAndSlots(),
        ),
        BlocProvider<StoryCubit>(
          create: (context) => StoryCubit(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageCubit>().state;
    final themeName = context.watch<ThemeCubit>().state;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.read<SaveCubit>().syncWithCloudProfile(state.userProfile);
        }
      },
      child: MaterialApp(
        title: 'Nexus 3D: Interactive Storyscapes',
        debugShowCheckedModeBanner: false,
        
        // Dynamic Theme configuration
        theme: AppTheme.getTheme(themeName),
        
        // Dynamic Locale configuration
        locale: Locale(language),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        
        // Adaptive RTL / LTR layout
        builder: (context, child) {
          return Directionality(
            textDirection: language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          );
        },
        
        home: const AuthGate(),
      ),
    );
  }
}
