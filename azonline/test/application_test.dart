import 'package:azonline/main.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test de fumée : l'application se construit et affiche son premier écran.
///
/// Il ne valide aucune fonctionnalité métier, mais il garantit que le socle
/// (ProviderScope, thème, première page) reste assemblable après chaque
/// modification.
void main() {
  testWidgets('l\'application démarre sur l\'écran de configuration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ApplicationAZOnline());

    expect(find.text('Configuration Firebase requise'), findsOneWidget);
    expect(find.textContaining('flutterfire configure'), findsOneWidget);
  });
}
