import 'package:azonline/fournisseurs/fournisseurs.dart';
import 'package:azonline/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie l'aiguillage de démarrage de l'application.
///
/// Aucun de ces tests ne contacte Firebase : le résultat de l'initialisation
/// est injecté par le constructeur, et l'état de connexion est remplacé par un
/// flux fixe grâce aux `overrides` de Riverpod.
void main() {
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

  testWidgets('sans session ouverte, le portail affiche la connexion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [compteProvider.overrideWith((ref) => Stream.value(null))],
        child: const ApplicationAZOnline(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AZOnline'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Pas encore de compte ? En créer un'), findsOneWidget);
  });

  testWidgets('le lien de bascule fait apparaître les champs d\'inscription', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [compteProvider.overrideWith((ref) => Stream.value(null))],
        child: const ApplicationAZOnline(),
      ),
    );
    await tester.pumpAndSettle();

    // En mode connexion, le prénom et le nom ne sont pas demandés.
    expect(find.text('Prénom'), findsNothing);

    await tester.tap(find.text('Pas encore de compte ? En créer un'));
    await tester.pumpAndSettle();

    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('Créer mon compte'), findsOneWidget);
  });

  testWidgets('un formulaire vide affiche les messages de validation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [compteProvider.overrideWith((ref) => Stream.value(null))],
        child: const ApplicationAZOnline(),
      ),
    );
    await tester.pumpAndSettle();

    // La validation doit bloquer l'envoi avant tout appel réseau : si elle
    // laissait passer, ce test tenterait de joindre Firebase et échouerait.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Renseignez votre adresse électronique.'), findsOneWidget);
    expect(find.text('Renseignez un mot de passe.'), findsOneWidget);
  });
}
