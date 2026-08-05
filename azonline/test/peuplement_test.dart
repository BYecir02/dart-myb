import 'package:azonline/outils/peupler_base.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie la cohérence du jeu de données de démonstration.
///
/// Ces tests n'écrivent rien dans Firestore : ils contrôlent les tables
/// déclarées dans `peupler_base.dart`. Une faute de frappe sur un nom de
/// matière ne provoquerait aucune erreur à l'exécution, elle produirait
/// simplement des cours sans salle ni professeur. Mieux vaut la détecter ici.
void main() {
  /// Toutes les matières apparaissant dans les deux emplois du temps.
  Set<String> matieresDesGrilles() {
    return [...grilleCinquieme, ...grilleTroisieme]
        .expand((journee) => journee)
        .where((matiere) => matiere.isNotEmpty)
        .toSet();
  }

  /// Toutes les matières apparaissant dans les évaluations.
  Set<String> matieresDesNotes() {
    return enfantsDeDemonstration
        .expand((enfant) => enfant['notes']! as List<Object>)
        .map((ligne) => (ligne as List<Object>)[0] as String)
        .toSet();
  }

  group('heureDeFin', () {
    test('ajoute la durée d\'un cours à l\'heure de début', () {
      expect(heureDeFin('08:00'), '09:00');
      expect(heureDeFin('10:15'), '11:15');
      expect(heureDeFin('13:30'), '14:30');
    });

    test('complète les chiffres manquants', () {
      expect(heureDeFin('08:05'), '09:05');
      expect(heureDeFin('09:30', duree: 30), '10:00');
    });
  });

  group('cohérence des données', () {
    test('chaque matière enseignée a une salle et un professeur', () {
      for (final String matiere in matieresDesGrilles()) {
        expect(
          salleEtProfesseurParMatiere.containsKey(matiere),
          isTrue,
          reason: 'La matière "$matiere" apparaît dans un emploi du temps '
              'mais n\'a ni salle ni professeur.',
        );
      }
    });

    test('chaque matière notée est bien enseignée', () {
      for (final String matiere in matieresDesNotes()) {
        expect(
          salleEtProfesseurParMatiere.containsKey(matiere),
          isTrue,
          reason: 'La matière "$matiere" porte des notes mais n\'existe pas '
              'dans la table des professeurs.',
        );
      }
    });

    test('chaque journée compte autant de créneaux que la grille horaire', () {
      for (final List<String> journee in [
        ...grilleCinquieme,
        ...grilleTroisieme,
      ]) {
        expect(journee.length, creneauxDeLaJournee.length);
      }
    });

    test('chaque note porte ses sept champs', () {
      for (final Map<String, Object> enfant in enfantsDeDemonstration) {
        for (final Object ligne in enfant['notes']! as List<Object>) {
          expect((ligne as List<Object>).length, 7);
        }
      }
    });

    test('le volume annoncé à l\'utilisateur est le bon', () {
      final int nombreDeNotes = enfantsDeDemonstration.fold<int>(
        0,
        (total, enfant) => total + (enfant['notes']! as List<Object>).length,
      );
      final int nombreDeCours = [...grilleCinquieme, ...grilleTroisieme]
          .expand((journee) => journee)
          .where((matiere) => matiere.isNotEmpty)
          .length;

      // Ces trois valeurs sont annoncées sur l'écran de génération.
      expect(enfantsDeDemonstration.length, 2);
      expect(nombreDeNotes, 28);
      expect(nombreDeCours, 44);
    });

    test('les deux profils couvrent tout le code couleur des notes', () {
      final List<double> notesSurVingt = enfantsDeDemonstration
          .expand((enfant) => enfant['notes']! as List<Object>)
          .map((ligne) {
            final List<Object> champs = ligne as List<Object>;
            return (champs[2] as double) / (champs[3] as double) * 20;
          })
          .toList();

      // Une démonstration où toutes les notes seraient vertes ne montrerait
      // qu'un quart de l'interface.
      expect(notesSurVingt.any((note) => note >= 16), isTrue);
      expect(
        notesSurVingt.any((note) => note >= 12 && note < 16),
        isTrue,
      );
      expect(notesSurVingt.any((note) => note >= 10 && note < 12), isTrue);
      expect(notesSurVingt.any((note) => note < 10), isTrue);
    });
  });
}
