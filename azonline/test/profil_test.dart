import 'package:azonline/fournisseurs/fournisseurs.dart';
import 'package:azonline/modeles/enfant.dart';
import 'package:azonline/modeles/utilisateur.dart';
import 'package:azonline/pages/page_profil.dart';
import 'package:azonline/services/service_stockage_local.dart';
import 'package:azonline/theme/theme_nature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vérifie l'écran de profil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
  });

  Enfant enfant(String id, String prenom, String classe) {
    return Enfant.depuisFirestore(id, {
      'idParent': 'p1',
      'prenom': prenom,
      'nom': 'Moreau',
      'classe': classe,
      'etablissement': 'Collège Jean Moulin',
    });
  }

  final Utilisateur parent = Utilisateur.depuisFirestore('p1', {
    'email': 'claire.moreau@exemple.fr',
    'nom': 'Moreau',
    'prenom': 'Claire',
    'dateInscription': DateTime(2026, 1, 10),
    'enfants': ['e1', 'e2'],
  });

  Future<void> monter(
    WidgetTester tester, {
    Utilisateur? profil,
    List<Enfant> enfants = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceStockageLocalProvider.overrideWithValue(
            ServiceStockageLocal(preferences),
          ),
          profilProvider.overrideWith((ref) => Stream.value(profil)),
          enfantsProvider.overrideWith((ref) => Stream.value(enfants)),
        ],
        child: MaterialApp(
          theme: ThemeNature.construire(),
          home: const Scaffold(body: PageProfil()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('affiche les informations du parent', (tester) async {
    await monter(tester, profil: parent, enfants: [enfant('e1', 'Lina', '5e B')]);

    expect(find.text('Claire Moreau'), findsOneWidget);
    expect(find.text('claire.moreau@exemple.fr'), findsOneWidget);
    expect(find.text('Compte créé le 10 janvier 2026'), findsOneWidget);
    expect(find.text('CM'), findsOneWidget);
  });

  testWidgets('liste les enfants rattachés', (tester) async {
    await monter(
      tester,
      profil: parent,
      enfants: [enfant('e1', 'Lina', '5e B'), enfant('e2', 'Noah', '3e A')],
    );

    expect(find.text('Mes enfants'), findsOneWidget);
    expect(find.text('Lina Moreau'), findsOneWidget);
    expect(find.text('Noah Moreau'), findsOneWidget);
    expect(find.text('5e B, Collège Jean Moulin'), findsOneWidget);
  });

  testWidgets('le titre s\'accorde avec un seul enfant', (tester) async {
    await monter(
      tester,
      profil: parent,
      enfants: [enfant('e1', 'Lina', '5e B')],
    );

    expect(find.text('Mon enfant'), findsOneWidget);
    expect(find.text('Mes enfants'), findsNothing);
  });

  testWidgets('toucher un enfant le rend actif', (tester) async {
    await monter(
      tester,
      profil: parent,
      enfants: [enfant('e1', 'Lina', '5e B'), enfant('e2', 'Noah', '3e A')],
    );

    await tester.tap(find.text('Noah Moreau'));
    await tester.pumpAndSettle();

    // Le profil offre un second chemin vers le changement d'enfant, qui doit
    // être mémorisé comme celui de la barre supérieure.
    expect(
      ServiceStockageLocal(preferences).lireEnfantSelectionne(),
      'e2',
    );
  });

  testWidgets('rappelle que les données sont fictives', (tester) async {
    await monter(tester, profil: parent);

    expect(find.textContaining('sont fictifs'), findsOneWidget);
  });

  testWidgets('la déconnexion demande confirmation', (tester) async {
    await monter(
      tester,
      profil: parent,
      enfants: [enfant('e1', 'Lina', '5e B')],
    );

    // On vise l'icône : `OutlinedButton.icon` construit une sous-classe privée
    // que `find.byType(OutlinedButton)`, qui compare le type exact, ne trouve
    // pas.
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    // Un geste irréversible ne doit pas partir sur une simple pression.
    expect(find.text('Annuler'), findsOneWidget);
    expect(
      find.textContaining('saisir à nouveau votre adresse'),
      findsOneWidget,
    );

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Annuler'), findsNothing);
  });

  testWidgets('sans enfant, invite à générer les données', (tester) async {
    await monter(tester, profil: parent);

    expect(find.textContaining('Aucun enfant rattaché'), findsOneWidget);
  });
}
