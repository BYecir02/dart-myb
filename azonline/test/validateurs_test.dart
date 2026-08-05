import 'package:azonline/outils/validateurs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie les règles de saisie du formulaire de connexion.
///
/// Ces fonctions renvoient `null` quand la saisie est acceptable, et le message
/// à afficher sinon. Les avoir sorties de la page permet de les tester sans
/// construire le moindre widget.
void main() {
  group('validerAdresse', () {
    test('accepte une adresse correcte', () {
      expect(validerAdresse('parent@exemple.fr'), isNull);
      expect(validerAdresse('  parent@exemple.fr  '), isNull);
      expect(validerAdresse('prenom.nom@sous.domaine.org'), isNull);
    });

    test('refuse une adresse vide', () {
      expect(validerAdresse(''), isNotNull);
      expect(validerAdresse('   '), isNotNull);
      expect(validerAdresse(null), isNotNull);
    });

    test('refuse les fautes de frappe courantes', () {
      expect(validerAdresse('parent'), isNotNull);
      expect(validerAdresse('parent@'), isNotNull);
      expect(validerAdresse('parent@exemple'), isNotNull);
      expect(validerAdresse('parent exemple@fr.fr'), isNotNull);
    });
  });

  group('validerMotDePasse', () {
    test('accepte un mot de passe assez long', () {
      expect(validerMotDePasse('secret123'), isNull);
      expect(validerMotDePasse('123456'), isNull);
    });

    test('refuse un mot de passe trop court', () {
      // Firebase refuse en dessous de six caractères : le vérifier ici évite
      // un aller-retour réseau pour rien.
      expect(validerMotDePasse('12345'), isNotNull);
      expect(validerMotDePasse(''), isNotNull);
      expect(validerMotDePasse(null), isNotNull);
    });

    test('le message annonce la longueur attendue', () {
      expect(
        validerMotDePasse('abc'),
        contains('$longueurMinimaleDuMotDePasse'),
      );
    });
  });

  group('validerChampObligatoire', () {
    test('accepte une saisie normale', () {
      expect(validerChampObligatoire('Claire', 'prénom'), isNull);
    });

    test('refuse une saisie vide ou trop courte', () {
      expect(validerChampObligatoire('', 'prénom'), isNotNull);
      expect(validerChampObligatoire('  ', 'prénom'), isNotNull);
      expect(validerChampObligatoire('C', 'prénom'), isNotNull);
    });

    test('le message reprend le libellé du champ', () {
      expect(validerChampObligatoire('', 'prénom'), contains('prénom'));
      expect(validerChampObligatoire('', 'nom'), contains('nom'));
    });
  });
}
