import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/core/router/app_router.dart';
import 'package:pgstay/core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PGStayApp(),
    ),
  );
}

class PGStayApp extends ConsumerWidget {
  const PGStayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'StaySync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
