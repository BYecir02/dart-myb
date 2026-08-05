/// Règles de validation des champs de formulaire.
///
/// Chaque fonction renvoie `null` lorsque la saisie est acceptable, ou le
/// message à afficher sous le champ. C'est exactement la signature attendue par
/// le `validator` d'un `TextFormField`.
///
/// Les extraire des pages leur donne deux qualités : elles sont réutilisables
/// entre l'inscription et la connexion, et elles se testent sans construire la
/// moindre interface.
library;

/// Expression vérifiant la forme générale d'une adresse électronique.
///
/// Volontairement permissive : elle écarte les fautes de frappe évidentes,
/// sans prétendre valider la norme complète, que Firebase vérifiera de son
/// côté à la création du compte.
final RegExp _formeDUneAdresse = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

/// Longueur minimale imposée par Firebase Auth.
const int longueurMinimaleDuMotDePasse = 6;

/// Vérifie une adresse électronique.
String? validerAdresse(String? saisie) {
  final String valeur = (saisie ?? '').trim();

  if (valeur.isEmpty) {
    return 'Renseignez votre adresse électronique.';
  }
  if (!_formeDUneAdresse.hasMatch(valeur)) {
    return 'Cette adresse ne semble pas valide.';
  }
  return null;
}

/// Vérifie un mot de passe.
///
/// La longueur minimale n'est pas un choix esthétique : Firebase refuse les
/// mots de passe plus courts. Vérifier avant l'envoi évite un aller-retour
/// réseau pour rien.
String? validerMotDePasse(String? saisie) {
  final String valeur = saisie ?? '';

  if (valeur.isEmpty) {
    return 'Renseignez un mot de passe.';
  }
  if (valeur.length < longueurMinimaleDuMotDePasse) {
    return 'Le mot de passe doit contenir au moins '
        '$longueurMinimaleDuMotDePasse caractères.';
  }
  return null;
}

/// Vérifie un champ de texte obligatoire, comme le nom ou le prénom.
///
/// Le libellé est passé en paramètre pour que le message reste précis :
/// « Renseignez votre prénom » plutôt qu'un « champ obligatoire » générique.
String? validerChampObligatoire(String? saisie, String libelle) {
  final String valeur = (saisie ?? '').trim();

  if (valeur.isEmpty) {
    return 'Renseignez votre $libelle.';
  }
  if (valeur.length < 2) {
    return 'Ce $libelle est trop court.';
  }
  return null;
}
