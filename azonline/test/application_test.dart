import 'package:azonline/main.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de fumée : l'application se construit et choisit le bon écran selon
/// que Firebase a démarré ou non.
///
/// Ils ne valident aucune fonctionnalité métier, mais ils garantissent que le
/// socle (thème, aiguillage de démarrage, premières pages) reste assemblable
/// après chaque modification. Aucun appel réseau n'est nécessaire : le résultat
/// de l'initialisation est injecté par le constructeur.
void main() {
  testWidgets('un démarrage réussi mène à l\'écran de socle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ApplicationAZOnline());

    expect(find.text('Firebase est connecté'), findsOneWidget);
  });

  testWidgets('un démarrage en échec mène à l\'écran de configuration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ApplicationAZOnline(messageDemarrage: 'Clé introuvable'),
    );

    expect(find.text('Configuration Firebase requise'), findsOneWidget);
    expect(find.textContaining('flutterfire configure'), findsOneWidget);
    expect(find.text('Clé introuvable'), findsOneWidget);
  });
}
