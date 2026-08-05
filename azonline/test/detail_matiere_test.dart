import 'package:azonline/fournisseurs/fournisseurs.dart';
import 'package:azonline/modeles/enfant.dart';
import 'package:azonline/modeles/note.dart';
import 'package:azonline/pages/page_detail_matiere.dart';
import 'package:azonline/services/service_stockage_local.dart';
import 'package:azonline/theme/theme_nature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vérifie l'écran de détail d'une matière.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
  });

  Note note(
    String matiere,
    String intitule,
    double valeur, {
    double coefficient = 1,
    String appreciation = '',
  }) {
    return Note.depuisFirestore('note-$intitule', {
      'idEnfant': 'e1',
      'matiere': matiere,
      'intitule': intitule,
      'valeur': valeur,
      'bareme': 20,
      'coefficient': coefficient,
      'date': DateTime(2026, 3, 14),
      'appreciation': appreciation,
    });
  }

  Future<void> monter(
    WidgetTester tester,
    String matiere,
    List<Note> notes,
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
                'classe': '5e B',
              }),
            ]),
          ),
          fluxDesNotesProvider.overrideWith((ref) => Stream.value(notes)),
        ],
        child: MaterialApp(
          theme: ThemeNature.construire(),
          home: PageDetailMatiere(matiere: matiere),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('n\'affiche que les notes de la matière demandée', (
    tester,
  ) async {
    await monter(tester, 'Mathématiques', [
      note('Mathématiques', 'Contrôle sur les fractions', 16),
      note('Mathématiques', 'Interrogation de géométrie', 12),
      note('Français', 'Dictée préparée', 8),
    ]);

    expect(find.text('Contrôle sur les fractions'), findsOneWidget);
    expect(find.text('Interrogation de géométrie'), findsOneWidget);
    // La note de français ne doit pas apparaître.
    expect(find.text('Dictée préparée'), findsNothing);
  });

  testWidgets('calcule la moyenne pondérée de la matière', (tester) async {
    await monter(tester, 'Mathématiques', [
      note('Mathématiques', 'Devoir surveillé', 16, coefficient: 3),
      note('Mathématiques', 'Interrogation', 8, coefficient: 1),
    ]);

    // (16 x 3 + 8 x 1) / 4 = 14,0
    expect(find.text('14.0'), findsOneWidget);
    expect(find.text('2 notes'), findsOneWidget);
  });

  testWidgets('affiche l\'appréciation du professeur quand elle existe', (
    tester,
  ) async {
    await monter(tester, 'Mathématiques', [
      note(
        'Mathématiques',
        'Contrôle',
        16,
        appreciation: 'Raisonnement rigoureux.',
      ),
    ]);

    expect(find.text('Raisonnement rigoureux.'), findsOneWidget);
    expect(find.text('1 note'), findsOneWidget);
  });

  testWidgets('rappelle de quel enfant il s\'agit', (tester) async {
    await monter(tester, 'Mathématiques', [
      note('Mathématiques', 'Contrôle', 16),
    ]);

    // La barre supérieure porte la matière, plus le sélecteur d'enfant : le
    // prénom doit rester visible pour un parent qui suit deux enfants.
    expect(find.text('Lina'), findsOneWidget);
  });

  testWidgets('sans note, affiche un état vide', (tester) async {
    await monter(tester, 'Mathématiques', [note('Français', 'Dictée', 12)]);

    expect(find.text('Aucune note en Mathématiques'), findsOneWidget);
  });
}
