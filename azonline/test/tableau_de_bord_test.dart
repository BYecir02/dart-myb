import 'package:azonline/fournisseurs/fournisseurs.dart';
import 'package:azonline/modeles/enfant.dart';
import 'package:azonline/modeles/note.dart';
import 'package:azonline/outils/formats.dart';
import 'package:azonline/pages/page_tableau_de_bord.dart';
import 'package:azonline/services/service_stockage_local.dart';
import 'package:azonline/theme/theme_nature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vérifie la mise en forme des dates et le tableau de bord.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
  });

  group('formats de date', () {
    test('dateCourte donne le jour et le mois', () {
      expect(dateCourte(DateTime(2026, 3, 14)), '14 mars');
      expect(dateCourte(DateTime(2026, 8, 1)), '1 août');
    });

    test('dateComplete ajoute l\'année', () {
      expect(dateComplete(DateTime(2026, 12, 25)), '25 décembre 2026');
    });

    test('depuisQuand accorde le singulier et le pluriel', () {
      final DateTime maintenant = DateTime(2026, 3, 14, 12, 0);

      expect(
        depuisQuand(maintenant.subtract(const Duration(minutes: 1)),
            maintenant: maintenant),
        'il y a 1 minute',
      );
      expect(
        depuisQuand(maintenant.subtract(const Duration(minutes: 30)),
            maintenant: maintenant),
        'il y a 30 minutes',
      );
      expect(
        depuisQuand(maintenant.subtract(const Duration(hours: 1)),
            maintenant: maintenant),
        'il y a 1 heure',
      );
      expect(
        depuisQuand(maintenant.subtract(const Duration(days: 3)),
            maintenant: maintenant),
        'il y a 3 jours',
      );
    });

    test('depuisQuand bascule sur la date au delà d\'un mois', () {
      final DateTime maintenant = DateTime(2026, 3, 14);

      expect(
        depuisQuand(DateTime(2026, 1, 5), maintenant: maintenant),
        'le 5 janvier 2026',
      );
    });

    test('une date à venir est traitée comme instantanée', () {
      final DateTime maintenant = DateTime(2026, 3, 14);

      // Peut arriver si l'horloge de l'appareil est légèrement en avance.
      expect(
        depuisQuand(maintenant.add(const Duration(minutes: 5)),
            maintenant: maintenant),
        'à l\'instant',
      );
    });
  });

  group('PageTableauDeBord', () {
    Note note(String matiere, double valeur, double coefficient) {
      return Note.depuisFirestore('note-$matiere-$valeur', {
        'idEnfant': 'e1',
        'matiere': matiere,
        'intitule': 'Contrôle de $matiere',
        'valeur': valeur,
        'bareme': 20,
        'coefficient': coefficient,
        'date': DateTime(2026, 3, 14),
      });
    }

    Future<void> monter(WidgetTester tester, List<Note> notes) async {
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
                  'classe': '5e B',
                }),
              ]),
            ),
            fluxDesNotesProvider.overrideWith((ref) => Stream.value(notes)),
          ],
          child: MaterialApp(
            theme: ThemeNature.construire(),
            home: const Scaffold(body: PageTableauDeBord()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('affiche la moyenne générale et les moyennes par matière', (
      tester,
    ) async {
      await monter(tester, [
        note('Mathématiques', 16, 2),
        note('Mathématiques', 10, 1),
        note('Français', 12, 1),
      ]);

      // Maths : (16 x 2 + 10 x 1) / 3 = 14,0. Français : 12,0.
      // Générale : moyenne simple des deux matières, soit 13,0.
      expect(find.text('13.0'), findsOneWidget);
      expect(find.text('14.0'), findsOneWidget);
      expect(find.text('12.0'), findsOneWidget);

      expect(find.text('Mathématiques'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('sur 2 matières'), findsOneWidget);
    });

    testWidgets('liste les dernières notes', (tester) async {
      await monter(tester, [
        note('Mathématiques', 16, 2),
        note('Français', 12, 1),
      ]);

      expect(find.text('Dernières notes'), findsOneWidget);
      expect(find.text('Contrôle de Mathématiques'), findsOneWidget);
      expect(find.text('Contrôle de Français'), findsOneWidget);
    });

    testWidgets('sans note, affiche un état vide et non un zéro', (
      tester,
    ) async {
      await monter(tester, []);

      // Un zéro laisserait croire à un échec ; le tiret dit qu'il n'y a
      // simplement rien à calculer.
      expect(find.text('--'), findsOneWidget);
      expect(find.text('Aucune note pour le moment'), findsOneWidget);
      expect(find.text('Moyennes par matière'), findsNothing);
    });
  });
}
