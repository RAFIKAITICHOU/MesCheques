import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mescheques/database/database_helper.dart';
import 'package:mescheques/l10n/app_localizations.dart';
import 'package:mescheques/providers/checks_provider.dart';
import 'package:mescheques/providers/locale_provider.dart';
import 'package:mescheques/screens/add_check_screen.dart';
import 'package:mescheques/widgets/drawer_field.dart';
import 'package:mescheques/widgets/image_picker_row.dart';
import 'package:mescheques/widgets/person_autocomplete.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    DatabaseHelper.instance.setDatabaseForTesting(db);
    await DatabaseHelper.instance.createTablesForTesting(db);
  });

  testWidgets('Pump AddCheckScreen and interact with DrawerField and scroll without assertions',
      (WidgetTester tester) async {
    final localeProvider = LocaleProvider();
    final checksProvider = ChecksProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: localeProvider),
          ChangeNotifierProvider.value(value: checksProvider),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('fr')],
          home: AddCheckScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(AddCheckScreen), findsOneWidget);
    expect(find.byType(DrawerField), findsOneWidget);
    expect(find.byType(ImagePickerRow), findsOneWidget);

    // Enter giver name
    final giverFinder = find.byType(PersonAutocomplete).first;
    await tester.enterText(giverFinder, 'Karim Benali');
    await tester.pumpAndSettle();

    // Toggle "Identique au donneur" checkbox in DrawerField
    final checkboxFinder = find.descendant(
      of: find.byType(DrawerField),
      matching: find.byType(Checkbox),
    );
    expect(checkboxFinder, findsOneWidget);
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    // Now custom drawer field is visible, enter drawer name
    final drawerAutocomplete = find.descendant(
      of: find.byType(DrawerField),
      matching: find.byType(PersonAutocomplete),
    );
    expect(drawerAutocomplete, findsOneWidget);
    await tester.enterText(drawerAutocomplete, 'Ahmed Ait Ali');
    await tester.pumpAndSettle();

    // Scroll up and down inside ListView to test viewport updates
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.byType(AddCheckScreen), findsOneWidget);
    expect(find.byType(DrawerField), findsOneWidget);
  });
}
