import 'package:azonline/fournisseurs/fournisseurs.dart';
import 'package:azonline/modeles/enfant.dart';
import 'package:azonline/services/service_stockage_local.dart';
import 'package:azonline/theme/theme_nature.dart';
import 'package:azonline/widgets/selecteur_enfant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vérifie le sélecteur d'enfant.
///
/// Le flux des enfants et les préférences sont simulés : le widget est monté
/// seul, sans Firebase ni application complète.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
  });

  Enfant enfant(String id, String prenom, String classe) {
    return Enfant.depuisFirestore(id, {
      'idParent': 'parent-1',
      'prenom': prenom,
      'nom': 'Moreau',
      'classe': classe,
      'etablissement': 'Collège Jean Moulin',
    });
  }

  /// Monte le sélecteur dans une barre supérieure, comme dans l'application.
  Future<void> monter(WidgetTester tester, List<Enfant> enfants) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceStockageLocalProvider.overrideWithValue(
            ServiceStockageLocal(preferences),
          ),
          enfantsProvider.overrideWith((ref) => Stream.value(enfants)),
        ],
        child: MaterialApp(
          theme: ThemeNature.construire(),
          home: Scaffold(appBar: AppBar(title: const SelecteurEnfant())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sans enfant, le nom de l\'application est affiché', (
    tester,
  ) async {
    await monter(tester, []);

    expect(find.text('AZOnline'), findsOneWidget);
  });

  testWidgets('avec un seul enfant, aucun menu n\'est proposé', (tester) async {
    await monter(tester, [enfant('e1', 'Lina', '5e B')]);

    expect(find.text('Lina Moreau'), findsOneWidget);
    expect(find.text('5e B'), findsOneWidget);
    // Rien à choisir : la flèche du menu n'a pas lieu d'être.
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
  });

  testWidgets('avec plusieurs enfants, le premier est affiché par défaut', (
    tester,
  ) async {
    await monter(tester, [
      enfant('e1', 'Lina', '5e B'),
      enfant('e2', 'Noah', '3e A'),
    ]);

    expect(find.text('Lina Moreau'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
  });

  testWidgets('choisir un autre enfant met la barre à jour', (tester) async {
    await monter(tester, [
      enfant('e1', 'Lina', '5e B'),
      enfant('e2', 'Noah', '3e A'),
    ]);

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    // Le menu ouvert liste les deux enfants.
    expect(find.text('Noah Moreau'), findsOneWidget);

    await tester.tap(find.text('Noah Moreau'));
    await tester.pumpAndSettle();

    expect(find.text('Noah Moreau'), findsOneWidget);
    expect(find.text('3e A'), findsOneWidget);
    expect(find.text('Lina Moreau'), findsNothing);
  });

  testWidgets('le choix est mémorisé sur l\'appareil', (tester) async {
    await monter(tester, [
      enfant('e1', 'Lina', '5e B'),
      enfant('e2', 'Noah', '3e A'),
    ]);

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noah Moreau'));
    await tester.pumpAndSettle();

    // Sans cette écriture, l'application repartirait sur Lina au prochain
    // lancement.
    expect(
      ServiceStockageLocal(preferences).lireEnfantSelectionne(),
      'e2',
    );
  });
}
