import 'package:azonline/modeles/conversions.dart';
import 'package:azonline/modeles/cours.dart';
import 'package:azonline/modeles/enfant.dart';
import 'package:azonline/modeles/moyenne_matiere.dart';
import 'package:azonline/modeles/note.dart';
import 'package:azonline/modeles/utilisateur.dart';
import 'package:flutter_test/flutter_test.dart';

/// Imite le `Timestamp` de Firestore, qui expose une méthode `toDate()`.
///
/// Il permet de vérifier que [versDate] sait lire un horodatage Firestore sans
/// que la couche des modèles ait à importer le SDK.
class FauxHorodatage {
  final DateTime date;

  const FauxHorodatage(this.date);

  DateTime toDate() => date;

}

void main() {
  group('conversions', () {
    test('versDecimal accepte les nombres, les textes et la virgule', () {
      expect(versDecimal(15), 15.0);
      expect(versDecimal('15.5'), 15.5);
      expect(versDecimal('15,5'), 15.5);
      expect(versDecimal('abc', defaut: 20), 20.0);
      expect(versDecimal(null), 0.0);
    });

    test('versTexte remplace une valeur absente ou vide par le défaut', () {
      expect(versTexte('Mathématiques'), 'Mathématiques');
      expect(versTexte('   '), '');
      expect(versTexte(null, defaut: 'Inconnu'), 'Inconnu');
    });

    test('versDate lit une date ISO, un horodatage et un Timestamp', () {
      expect(versDate('2026-03-14T10:00:00Z')?.year, 2026);
      expect(versDate(FauxHorodatage(DateTime(2026, 3, 14)))?.month, 3);
      expect(versDate(null), isNull);
      expect(versDate('pas une date'), isNull);
    });

    test('versListeDeTextes renvoie toujours une liste', () {
      expect(versListeDeTextes(['a', 'b']), ['a', 'b']);
      expect(versListeDeTextes(null), isEmpty);
      expect(versListeDeTextes('texte simple'), isEmpty);
    });
  });

  group('Utilisateur', () {
    test('se construit depuis un document complet', () {
      final Utilisateur parent = Utilisateur.depuisFirestore('uid-1', {
        'email': 'parent@exemple.fr',
        'nom': 'Dupont',
        'prenom': 'Claire',
        'dateInscription': FauxHorodatage(DateTime(2026, 1, 10)),
        'enfants': ['enfant-1', 'enfant-2'],
      });

      expect(parent.id, 'uid-1');
      expect(parent.nomComplet, 'Claire Dupont');
      expect(parent.initiales, 'CD');
      expect(parent.possedeDesEnfants, isTrue);
      expect(parent.dateInscription?.year, 2026);
    });

    test('retombe sur l\'email quand le profil est incomplet', () {
      final Utilisateur parent = Utilisateur.depuisFirestore('uid-2', {
        'email': 'parent@exemple.fr',
      });

      expect(parent.nomComplet, 'parent@exemple.fr');
      expect(parent.possedeDesEnfants, isFalse);
      expect(parent.enfants, isEmpty);
    });
  });

  group('Enfant', () {
    test('se construit depuis un document complet', () {
      final Enfant enfant = Enfant.depuisFirestore('enfant-1', {
        'idParent': 'uid-1',
        'prenom': 'Lina',
        'nom': 'Dupont',
        'classe': '5e B',
        'etablissement': 'Collège Jean Moulin',
      });

      expect(enfant.nomComplet, 'Lina Dupont');
      expect(enfant.initiales, 'LD');
      expect(enfant.description, '5e B, Collège Jean Moulin');
    });

    test('fournit des valeurs de repli sur un document vide', () {
      final Enfant enfant = Enfant.depuisFirestore('enfant-2', {});

      expect(enfant.prenom, 'Enfant');
      expect(enfant.classe, 'Classe inconnue');
    });
  });

  group('Note', () {
    test('se construit depuis un document complet', () {
      final Note note = Note.depuisFirestore('note-1', {
        'idEnfant': 'enfant-1',
        'matiere': 'Mathématiques',
        'intitule': 'Contrôle sur les fractions',
        'valeur': 15.5,
        'bareme': 20,
        'coefficient': 2,
        'date': FauxHorodatage(DateTime(2026, 3, 14)),
        'appreciation': 'Bon travail',
      });

      expect(note.valeurSurVingt, 15.5);
      expect(note.affichage, '15.5 / 20');
      expect(note.affichageCoefficient, 'coef. 2');
      expect(note.possedeUneAppreciation, isTrue);
    });

    test('ramène la note sur 20 quel que soit le barème', () {
      final Note note = Note.depuisFirestore('note-2', {
        'valeur': 8,
        'bareme': 10,
      });

      expect(note.valeurSurVingt, 16.0);
      expect(note.affichage, '8 / 10');
    });

    test('corrige un barème ou un coefficient invalide', () {
      final Note note = Note.depuisFirestore('note-3', {
        'valeur': 12,
        'bareme': 0,
        'coefficient': 0,
      });

      // Sans cette correction, valeurSurVingt provoquerait une division par
      // zéro et remonterait jusqu'au calcul des moyennes.
      expect(note.bareme, 20);
      expect(note.coefficient, 1);
      expect(note.valeurSurVingt, 12.0);
    });
  });

  group('Cours', () {
    test('se construit depuis un document complet', () {
      final Cours cours = Cours.depuisFirestore('cours-1', {
        'idEnfant': 'enfant-1',
        'matiere': 'Histoire',
        'jour': 2,
        'heureDebut': '10:00',
        'heureFin': '11:00',
        'salle': 'B12',
        'professeur': 'M. Bernard',
      });

      expect(cours.libelleDuJour, 'Mardi');
      expect(cours.creneau, '10:00 - 11:00');
      expect(cours.debutEnMinutes, 600);
      expect(cours.dureeEnMinutes, 60);
    });

    test('ramène un jour aberrant dans la semaine ouvrée', () {
      expect(Cours.depuisFirestore('c', {'jour': 7}).jour, 5);
      expect(Cours.depuisFirestore('c', {'jour': 0}).jour, 1);
    });

    test('un horaire illisible ne fait pas échouer le tri', () {
      expect(Cours.minutesDepuisTexte('08:30'), 510);
      expect(Cours.minutesDepuisTexte('pas un horaire'), 0);
      expect(Cours.minutesDepuisTexte('08h30'), 0);
    });

    test('estEnCours ne se déclenche que le bon jour à la bonne heure', () {
      final Cours cours = Cours.depuisFirestore('cours-2', {
        'jour': 1,
        'heureDebut': '08:00',
        'heureFin': '09:00',
      });

      final DateTime lundi = DateTime(2026, 1, 5);
      expect(lundi.weekday, DateTime.monday);

      expect(cours.estEnCours(DateTime(2026, 1, 5, 8, 30)), isTrue);
      // La fin du créneau est exclue : à 9h00 le cours suivant commence.
      expect(cours.estEnCours(DateTime(2026, 1, 5, 9, 0)), isFalse);
      expect(cours.estEnCours(DateTime(2026, 1, 5, 7, 59)), isFalse);
      // Même heure, mais le mardi.
      expect(cours.estEnCours(DateTime(2026, 1, 6, 8, 30)), isFalse);
    });
  });

  group('MoyenneMatiere', () {
    /// Raccourci de construction pour alléger les tests.
    Note note(String matiere, double valeur, {double coefficient = 1}) {
      return Note.depuisFirestore('id', {
        'matiere': matiere,
        'valeur': valeur,
        'bareme': 20,
        'coefficient': coefficient,
      });
    }

    test('pondère chaque note par son coefficient', () {
      final MoyenneMatiere moyenne = MoyenneMatiere.depuisNotes('Maths', [
        note('Maths', 10),
        note('Maths', 16, coefficient: 3),
      ]);

      // (10 x 1 + 16 x 3) / 4 = 14.5
      expect(moyenne.valeur, 14.5);
      expect(moyenne.nombreDeNotes, 2);
      expect(moyenne.affichage, '14.5');
    });

    test('compare des notes de barèmes différents', () {
      final Note surDix = Note.depuisFirestore('id', {
        'valeur': 8,
        'bareme': 10,
      });
      final Note surVingt = Note.depuisFirestore('id', {
        'valeur': 12,
        'bareme': 20,
      });

      final MoyenneMatiere moyenne = MoyenneMatiere.depuisNotes('Maths', [
        surDix,
        surVingt,
      ]);

      // 8 sur 10 vaut 16 sur 20 : la moyenne est (16 + 12) / 2 = 14.
      expect(moyenne.valeur, 14.0);
    });

    test('une matière sans note donne une moyenne nulle et non un plantage', () {
      final MoyenneMatiere moyenne = MoyenneMatiere.depuisNotes('Maths', []);

      expect(moyenne.valeur, 0);
      expect(moyenne.nombreDeNotes, 0);
      expect(moyenne.affichageNombreDeNotes, '0 note');
    });

    test('parMatiere regroupe et trie par ordre alphabétique', () {
      final List<MoyenneMatiere> moyennes = MoyenneMatiere.parMatiere([
        note('Histoire', 12),
        note('Anglais', 16),
        note('Histoire', 14),
      ]);

      expect(moyennes.map((m) => m.matiere).toList(), ['Anglais', 'Histoire']);
      expect(moyennes.first.nombreDeNotes, 1);
      expect(moyennes.last.valeur, 13.0);
    });

    test('la moyenne générale est la moyenne simple des matières', () {
      final List<MoyenneMatiere> moyennes = MoyenneMatiere.parMatiere([
        note('Anglais', 16),
        // Trois notes en histoire, mais la matière pèse autant que l'anglais.
        note('Histoire', 10),
        note('Histoire', 10),
        note('Histoire', 10),
      ]);

      expect(MoyenneMatiere.moyenneGenerale(moyennes), 13.0);
    });

    test('la moyenne générale vaut null sans aucune note', () {
      expect(MoyenneMatiere.moyenneGenerale([]), isNull);
      expect(
        MoyenneMatiere.moyenneGenerale([
          MoyenneMatiere.depuisNotes('Maths', []),
        ]),
        isNull,
      );
    });
  });
}
