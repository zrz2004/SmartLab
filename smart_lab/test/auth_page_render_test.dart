import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_lab/core/localization/app_localizations.dart';
import 'package:smart_lab/core/services/api_service.dart';
import 'package:smart_lab/core/services/local_storage_service.dart';
import 'package:smart_lab/core/theme/app_theme.dart';
import 'package:smart_lab/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_lab/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage render', () {
    testWidgets('renders in Chinese without build exceptions', (tester) async {
      await tester.pumpWidget(_buildApp(const Locale('zh')));
      await tester.pumpAndSettle();

      expect(find.text('登录'), findsWidgets);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in English without build exceptions', (tester) async {
      await tester.pumpWidget(_buildApp(const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsWidgets);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _buildApp(Locale locale) {
  return BlocProvider(
    create: (_) => AuthBloc(
      apiService: ApiService(),
      storageService: LocalStorageService(),
    ),
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    ),
  );
}
