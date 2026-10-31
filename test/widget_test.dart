import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mescheques/main.dart';
import 'package:mescheques/providers/auth_provider.dart';
import 'package:mescheques/providers/checks_provider.dart';
import 'package:mescheques/providers/locale_provider.dart';
import 'package:mescheques/services/auth_service.dart';
import 'auth_service_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.mescheques/security'),
      (MethodCall methodCall) async => null,
    );

    final localeProvider = LocaleProvider();
    final checksProvider = ChecksProvider();
    final authProvider = AuthProvider(
      authService: AuthService(storage: FakeSecureStorage()),
      biometricService: FakeBiometricService(),
    );
    await authProvider.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: localeProvider),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: checksProvider),
        ],
        child: const MesChequesApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('MesCheques'), findsWidgets);
  });
}
