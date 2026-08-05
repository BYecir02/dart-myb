import 'package:azonline/modeles/note.dart';
import 'package:azonline/services/service_stockage_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vérifie le stockage local.
///
/// `setMockInitialValues` remplace les préférences du système par une carte en
/// mémoire : les tests s'exécutent sans téléphone ni navigateur.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ServiceStockageLocal stockage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    stockage = ServiceStockageLocal(await SharedPreferences.getInstance());
  });

  Note note(String id, String matiere, double valeur) {
    return Note.depuisFirestore(id, {
      'idEnfant': 'enfant-1',
      'matiere': matiere,
      'intitule': 'Contrôle',
      'valeur': valeur,
      'bareme': 20,
      'coefficient': 2,
      'date': DateTime(2026, 3, 14),
      'appreciation': 'Bon travail',
    });
  }

  group('enfant sélectionné', () {
    test('rien n\'est mémorisé au premier lancement', () {
      expect(stockage.lireEnfantSelectionne(), isNull);
    });

    test('le choix est relu tel quel', () async {
      await stockage.enregistrerEnfantSelectionne('enfant-2');

      expect(stockage.lireEnfantSelectionne(), 'enfant-2');
    });

    test('enregistrer null efface le choix', () async {
      await stockage.enregistrerEnfantSelectionne('enfant-2');
      await stockage.enregistrerEnfantSelectionne(null);

      expect(stockage.lireEnfantSelectionne(), isNull);
    });
  });

  group('cache des notes', () {
    test('un cache absent renvoie une liste vide', () {
      expect(stockage.lireNotesEnCache('enfant-1'), isEmpty);
    });

    test('les notes sont relues à l\'identique', () async {
      await stockage.enregistrerNotesEnCache('enfant-1', [
        note('n1', 'Mathématiques', 16),
        note('n2', 'Français', 12.5),
      ]);

      final List<Note> relues = stockage.lireNotesEnCache('enfant-1');

      expect(relues.length, 2);
      expect(relues.first.id, 'n1');
      expect(relues.first.matiere, 'Mathématiques');
      expect(relues.first.valeur, 16);
      expect(relues.first.coefficient, 2);
      expect(relues.first.appreciation, 'Bon travail');
      // La date passe par une chaîne ISO : elle doit survivre à l'aller-retour.
      expect(relues.first.date, DateTime(2026, 3, 14));
      expect(relues.last.valeur, 12.5);
    });

    test('chaque enfant a son propre cache', () async {
      await stockage.enregistrerNotesEnCache('enfant-1', [
        note('n1', 'Mathématiques', 16),
      ]);
      await stockage.enregistrerNotesEnCache('enfant-2', [
        note('n2', 'Français', 8),
        note('n3', 'Anglais', 14),
      ]);

      expect(stockage.lireNotesEnCache('enfant-1').length, 1);
      expect(stockage.lireNotesEnCache('enfant-2').length, 2);
    });

    test('un cache illisible ne fait pas échouer la lecture', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        '${ServiceStockageLocal.prefixeCacheDesNotes}enfant-1':
            'ceci n\'est pas du json',
      });
      final ServiceStockageLocal abime = ServiceStockageLocal(
        await SharedPreferences.getInstance(),
      );

      // L'application doit repartir du réseau, pas refuser de démarrer.
      expect(abime.lireNotesEnCache('enfant-1'), isEmpty);
    });
  });

  group('date de synchronisation', () {
    test('elle est absente avant toute mise en cache', () {
      expect(stockage.lireDateDerniereSynchro(), isNull);
    });

    test('elle est mise à jour à chaque mise en cache', () async {
      final DateTime avant = DateTime.now();
      await stockage.enregistrerNotesEnCache('enfant-1', [
        note('n1', 'Mathématiques', 16),
      ]);

      final DateTime? synchro = stockage.lireDateDerniereSynchro();

      expect(synchro, isNotNull);
      expect(
        synchro!.isBefore(avant.subtract(const Duration(seconds: 1))),
        isFalse,
      );
    });
  });

  group('oublierTout', () {
    test('efface la sélection, les caches et la date', () async {
      await stockage.enregistrerEnfantSelectionne('enfant-1');
      await stockage.enregistrerNotesEnCache('enfant-1', [
        note('n1', 'Mathématiques', 16),
      ]);
      await stockage.enregistrerNotesEnCache('enfant-2', [
        note('n2', 'Français', 12),
      ]);

      await stockage.oublierTout();

      // Sans cet effacement, le parent suivant à se connecter sur le même
      // appareil retrouverait les données du précédent.
      expect(stockage.lireEnfantSelectionne(), isNull);
      expect(stockage.lireNotesEnCache('enfant-1'), isEmpty);
      expect(stockage.lireNotesEnCache('enfant-2'), isEmpty);
      expect(stockage.lireDateDerniereSynchro(), isNull);
    });
  });
}
