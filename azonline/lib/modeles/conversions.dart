/// Fonctions de conversion partagées par tous les modèles.
///
/// Un document Firestore arrive sous la forme d'une `Map<String, dynamic>` :
/// rien ne garantit qu'un champ existe, ni qu'il porte le type attendu. Un
/// document saisi à la main dans la console peut très bien contenir la chaîne
/// `"15"` là où le code attend un nombre.
///
/// Ces fonctions absorbent ces écarts et renvoient toujours une valeur
/// exploitable. Elles évitent d'écrire la même cascade de `??` et de `as`
/// dans les cinq modèles.
///
/// Aucune de ces fonctions n'importe `cloud_firestore` : les modèles restent
/// des objets Dart purs, réutilisables tels quels si les données venaient un
/// jour d'une API REST plutôt que de Firestore.
library;

/// Convertit une valeur quelconque en texte.
String versTexte(Object? valeur, {String defaut = ''}) {
  if (valeur == null) {
    return defaut;
  }
  final String texte = valeur.toString().trim();
  return texte.isEmpty ? defaut : texte;
}

/// Convertit une valeur quelconque en nombre décimal.
///
/// Accepte aussi bien un `num` qu'une chaîne, avec la virgule ou le point
/// comme séparateur décimal.
double versDecimal(Object? valeur, {double defaut = 0}) {
  if (valeur is num) {
    return valeur.toDouble();
  }
  if (valeur is String) {
    return double.tryParse(valeur.replaceAll(',', '.')) ?? defaut;
  }
  return defaut;
}

/// Convertit une valeur quelconque en nombre entier.
int versEntier(Object? valeur, {int defaut = 0}) {
  if (valeur is num) {
    return valeur.toInt();
  }
  if (valeur is String) {
    return int.tryParse(valeur) ?? defaut;
  }
  return defaut;
}

/// Convertit une valeur quelconque en date.
///
/// Firestore renvoie ses dates sous forme de `Timestamp`. Plutôt que d'importer
/// le SDK dans la couche des modèles, on appelle sa méthode `toDate()` de
/// manière dynamique. La fonction accepte également une date ISO en texte ou un
/// horodatage en millisecondes, ce qui la rend indépendante de la source.
///
/// Renvoie `null` si la valeur est absente ou illisible : au niveau du modèle,
/// une date manquante est une information, pas une erreur.
DateTime? versDate(Object? valeur) {
  if (valeur == null) {
    return null;
  }
  if (valeur is DateTime) {
    return valeur;
  }
  if (valeur is String) {
    return DateTime.tryParse(valeur);
  }
  if (valeur is int) {
    return DateTime.fromMillisecondsSinceEpoch(valeur);
  }

  // Cas du Timestamp Firestore, atteint sans dépendre du paquet.
  try {
    final Object? date = (valeur as dynamic).toDate();
    return date is DateTime ? date : null;
  } catch (_) {
    return null;
  }
}

/// Convertit une valeur quelconque en liste de textes.
///
/// Utilisée pour les champs tableau, comme la liste des enfants rattachés à un
/// parent. Une valeur absente donne une liste vide, jamais `null` : les pages
/// n'ont ainsi aucun cas particulier à traiter.
List<String> versListeDeTextes(Object? valeur) {
  if (valeur is! List) {
    return <String>[];
  }
  return valeur
      .map((element) => versTexte(element))
      .where((texte) => texte.isNotEmpty)
      .toList();
}

/// Extrait les initiales d'un prénom et d'un nom.
///
/// Sert aux pastilles rondes affichées à côté des enfants et du parent.
String initialesDe(String prenom, String nom) {
  final String premiere = prenom.isEmpty ? '' : prenom[0].toUpperCase();
  final String seconde = nom.isEmpty ? '' : nom[0].toUpperCase();
  final String initiales = '$premiere$seconde';
  return initiales.isEmpty ? '?' : initiales;
}
