import 'package:azonline/fournisseurs/fournisseurs.dart';
import 'package:azonline/modeles/cours.dart';
import 'package:azonline/modeles/enfant.dart';
import 'package:azonline/outils/peupler_base.dart';
import 'package:azonline/pages/page_emploi_du_temps.dart';
import 'package:azonline/services/service_stockage_local.dart';
import 'package:azonline/theme/theme_nature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vérifie l'emploi du temps.
///
/// L'instant de référence est fixé par les tests : la mise en évidence du cours
/// en train de se dérouler ne dépend donc pas de l'heure à laquelle ils
/// tournent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
  });

  Cours cours(
    String matiere,
    int jour,
    String heureDebut, {
    String salle = 'B12',
    String professeur = 'M. Renard',
  }) {
    return Cours.depuisFirestore('cours-$matiere-$jour-$heureDebut', {
      'idEnfant': 'e1',
      'matiere': matiere,
      'jour': jour,
      'heureDebut': heureDebut,
      // Réutilise le calcul du peuplement plutôt que d'en réécrire un ici.
      'heureFin': heureDeFin(heureDebut),
      'salle': salle,
      'professeur': professeur,
    });
  }

  /// 5 janvier 2026 est un lundi.
  final DateTime lundi = DateTime(2026, 1, 5, 8, 30);

  Future<void> monter(
    WidgetTester tester,
    List<Cours> creneaux, {
    DateTime? maintenant,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceStockageLocalProvider.overrideWithValue(
            ServiceStockageLocal(preferences),
          ),
          enfantsProvider.overrideWith(
            (ref) => Stream.value([
              Enfant.depuisFirestore('e1', {
                'idParent': 'p1',
                'prenom': 'Lina',
                'nom': 'Moreau',
              }),
            ]),
          ),
          coursProvider.overrideWith((ref) => Stream.value(creneaux)),
          // Le jour affiché est fixé, sans quoi le test dépendrait du jour
          // de la semaine où il est lancé.
          jourSelectionneProvider.overrideWith(JourSelectionne.new),
        ],
        child: MaterialApp(
          theme: ThemeNature.construire(),
          home: Scaffold(body: PageEmploiDuTemps(maintenant: maintenant)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la barre propose les cinq jours ouvrés', (tester) async {
    await monter(tester, []);

    expect(find.text('Lu'), findsOneWidget);
    expect(find.text('Ma'), findsOneWidget);
    // Deux lettres distinguent mardi de mercredi.
    expect(find.text('Me'), findsOneWidget);
    expect(find.text('Je'), findsOneWidget);
    expect(find.text('Ve'), findsOneWidget);
  });

  testWidgets('changer de jour change la liste des cours', (tester) async {
    await monter(tester, [
      cours('Mathématiques', 1, '08:00'),
      cours('Histoire-Géographie', 4, '09:00'),
    ]);

    await tester.tap(find.text('Lu'));
    await tester.pumpAndSettle();
    expect(find.text('Mathématiques'), findsOneWidget);
    expect(find.text('Histoire-Géographie'), findsNothing);

    await tester.tap(find.text('Je'));
    await tester.pumpAndSettle();
    expect(find.text('Histoire-Géographie'), findsOneWidget);
    expect(find.text('Mathématiques'), findsNothing);
  });

  testWidgets('un jour sans cours affiche un état vide', (tester) async {
    await monter(tester, [cours('Mathématiques', 1, '08:00')]);

    await tester.tap(find.text('Ve'));
    await tester.pumpAndSettle();

    expect(find.text('Aucun cours ce jour'), findsOneWidget);
  });

  testWidgets('affiche la salle et le professeur', (tester) async {
    await monter(tester, [
      cours('Mathématiques', 1, '08:00', salle: 'B12', professeur: 'M. Renard'),
    ]);

    await tester.tap(find.text('Lu'));
    await tester.pumpAndSettle();

    expect(find.text('B12'), findsOneWidget);
    expect(find.text('M. Renard'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
  });

  testWidgets('le cours en train de se dérouler est signalé', (tester) async {
    await monter(
      tester,
      [cours('Mathématiques', 1, '08:00'), cours('Français', 1, '09:00')],
      // Lundi 8h30 : le cours de mathématiques est en cours.
      maintenant: lundi,
    );

    await tester.tap(find.text('Lu'));
    await tester.pumpAndSettle();

    expect(find.text('en cours'), findsOneWidget);
  });

  testWidgets('une lecture en échec affiche un message et non un écran vide', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceStockageLocalProvider.overrideWithValue(
            ServiceStockageLocal(preferences),
          ),
          enfantsProvider.overrideWith(
            (ref) => Stream.value([
              Enfant.depuisFirestore('e1', {
                'idParent': 'p1',
                'prenom': 'Lina',
                'nom': 'Moreau',
              }),
            ]),
          ),
          coursProvider.overrideWith(
            (ref) => Stream<List<Cours>>.error(Exception('réseau injoignable')),
          ),
        ],
        child: MaterialApp(
          theme: ThemeNature.construire(),
          home: const Scaffold(body: PageEmploiDuTemps()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Impossible de lire l\'emploi du temps'),
      findsOneWidget,
    );
    expect(find.textContaining('réseau injoignable'), findsOneWidget);
    // La barre des jours reste utilisable malgré l'erreur.
    expect(find.text('Lu'), findsOneWidget);
  });

  testWidgets('consulter un autre jour n\'allume aucun créneau', (
    tester,
  ) async {
    await monter(
      tester,
      [cours('Mathématiques', 1, '08:00'), cours('Anglais', 2, '08:00')],
      maintenant: lundi,
    );

    // On regarde le mardi alors qu'on est lundi 8h30 : le créneau de mardi
    // 8h ne doit pas être signalé comme en cours.
    await tester.tap(find.text('Ma'));
    await tester.pumpAndSettle();

    expect(find.text('Anglais'), findsOneWidget);
    expect(find.text('en cours'), findsNothing);
  });
}
