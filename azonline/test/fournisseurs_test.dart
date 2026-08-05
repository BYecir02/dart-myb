import 'package:azonline/fournisseurs/fournisseurs.dart';
import 'package:azonline/modeles/enfant.dart';
import 'package:azonline/services/service_stockage_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vérifie la logique portée par les providers.
///
/// Aucun de ces tests ne contacte Firebase : le flux des enfants est remplacé
/// par une valeur fixe grâce aux `overrides` de Riverpod, et les préférences
/// sont simulées en mémoire. C'est précisément ce que permet d'avoir isolé
/// l'accès aux données derrière des services.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
  });

  Enfant enfant(String id, String prenom) {
    return Enfant.depuisFirestore(id, {
      'idParent': 'parent-1',
      'prenom': prenom,
      'nom': 'Dupont',
    });
  }

  group('jourOuvreDe', () {
    test('un jour de semaine est conservé', () {
      // 6 janvier 2026, un mardi.
      final DateTime mardi = DateTime(2026, 1, 6);
      expect(mardi.weekday, DateTime.tuesday);
      expect(jourOuvreDe(mardi), 2);
    });

    test('le week-end renvoie sur le lundi', () {
      final DateTime samedi = DateTime(2026, 1, 10);
      final DateTime dimanche = DateTime(2026, 1, 11);
      expect(samedi.weekday, DateTime.saturday);

      expect(jourOuvreDe(samedi), 1);
      expect(jourOuvreDe(dimanche), 1);
    });
  });

  group('enfantSelectionneProvider', () {
    /// Prépare un conteneur dont le flux des enfants est déjà rempli.
    Future<ProviderContainer> conteneurAvec(List<Enfant> enfants) async {
      final ProviderContainer conteneur = ProviderContainer(
        overrides: [
          serviceStockageLocalProvider.overrideWithValue(
            ServiceStockageLocal(preferences),
          ),
          enfantsProvider.overrideWith((ref) => Stream.value(enfants)),
        ],
      );
      addTearDown(conteneur.dispose);

      // Depuis Riverpod 3, un provider est supprimé dès qu'il n'a plus
      // d'auditeur. Sans ces abonnements, le flux serait fermé avant d'avoir
      // émis et l'attente ci-dessous ne se terminerait jamais. Dans
      // l'application, ce rôle est tenu par les widgets qui observent.
      conteneur.listen(enfantsProvider, (precedent, suivant) {});
      conteneur.listen(selectionEnfantProvider, (precedent, suivant) {});
      conteneur.listen(enfantSelectionneProvider, (precedent, suivant) {});

      // On attend la première émission, sans quoi le provider dérivé lirait
      // encore une valeur absente.
      await conteneur.read(enfantsProvider.future);
      return conteneur;
    }

    test('sans aucun enfant, la sélection reste vide', () async {
      final ProviderContainer conteneur = await conteneurAvec([]);

      expect(conteneur.read(enfantSelectionneProvider), isNull);
    });

    test('sans choix explicite, le premier enfant est retenu', () async {
      final ProviderContainer conteneur = await conteneurAvec([
        enfant('e1', 'Lina'),
        enfant('e2', 'Noah'),
      ]);

      expect(conteneur.read(enfantSelectionneProvider)?.id, 'e1');
    });

    test('un choix explicite est respecté', () async {
      final ProviderContainer conteneur = await conteneurAvec([
        enfant('e1', 'Lina'),
        enfant('e2', 'Noah'),
      ]);

      conteneur.read(selectionEnfantProvider.notifier).choisir('e2');

      expect(conteneur.read(enfantSelectionneProvider)?.prenom, 'Noah');
    });

    test('un choix devenu invalide retombe sur le premier enfant', () async {
      final ProviderContainer conteneur = await conteneurAvec([
        enfant('e1', 'Lina'),
      ]);

      // Cas réel : l'enfant mémorisé la veille a été retiré de la base.
      conteneur
          .read(selectionEnfantProvider.notifier)
          .choisir('enfant-supprime');

      expect(conteneur.read(enfantSelectionneProvider)?.id, 'e1');
    });

    test('le choix est relu depuis le stockage au redémarrage', () async {
      // Premier lancement : le parent choisit le second enfant.
      final ProviderContainer premierLancement = await conteneurAvec([
        enfant('e1', 'Lina'),
        enfant('e2', 'Noah'),
      ]);
      premierLancement.read(selectionEnfantProvider.notifier).choisir('e2');
      expect(premierLancement.read(enfantSelectionneProvider)?.id, 'e2');

      // Second lancement : un conteneur neuf, mais les mêmes préférences.
      final ProviderContainer secondLancement = await conteneurAvec([
        enfant('e1', 'Lina'),
        enfant('e2', 'Noah'),
      ]);

      expect(secondLancement.read(enfantSelectionneProvider)?.id, 'e2');
    });
  });

  group('JourSelectionne', () {
    test('démarre sur un jour ouvré', () {
      final ProviderContainer conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);

      final int jour = conteneur.read(jourSelectionneProvider);
      expect(jour, greaterThanOrEqualTo(1));
      expect(jour, lessThanOrEqualTo(5));
    });

    test('un jour hors semaine est ramené dans l\'intervalle', () {
      final ProviderContainer conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);

      final JourSelectionne selection = conteneur.read(
        jourSelectionneProvider.notifier,
      );

      selection.choisir(9);
      expect(conteneur.read(jourSelectionneProvider), 5);

      selection.choisir(0);
      expect(conteneur.read(jourSelectionneProvider), 1);

      selection.choisir(3);
      expect(conteneur.read(jourSelectionneProvider), 3);
    });
  });
}
