/// Mise en forme des dates en français.
///
/// Le paquet `intl` n'est pas utilisé : l'application n'a besoin que de trois
/// formats, tous en français. Douze noms de mois et trois fonctions suffisent,
/// pour une dépendance de moins à installer et à maintenir.
library;

/// Noms des mois, indexés de 1 à 12 par `DateTime.month`.
const List<String> nomsDesMois = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Jour et mois, par exemple `14 mars`.
///
/// Format utilisé dans les listes de notes, où l'année est presque toujours
/// l'année scolaire en cours et n'apporte rien.
String dateCourte(DateTime date) {
  return '${date.day} ${nomsDesMois[date.month - 1]}';
}

/// Jour, mois et année, par exemple `14 mars 2026`.
String dateComplete(DateTime date) {
  return '${dateCourte(date)} ${date.year}';
}

/// Ancienneté exprimée en langage courant, par exemple `il y a 3 jours`.
///
/// Sert à indiquer la fraîcheur des données sous le tableau de bord. Une date
/// brute obligerait le parent à faire le calcul lui-même.
///
/// L'instant de référence est un paramètre plutôt que l'horloge interne : la
/// fonction reste ainsi testable sans dépendre du moment où le test tourne.
String depuisQuand(DateTime date, {DateTime? maintenant}) {
  final DateTime reference = maintenant ?? DateTime.now();
  final Duration ecart = reference.difference(date);

  if (ecart.isNegative || ecart.inMinutes < 1) {
    return 'à l\'instant';
  }
  if (ecart.inMinutes < 60) {
    final int minutes = ecart.inMinutes;
    return 'il y a $minutes minute${minutes > 1 ? 's' : ''}';
  }
  if (ecart.inHours < 24) {
    final int heures = ecart.inHours;
    return 'il y a $heures heure${heures > 1 ? 's' : ''}';
  }
  if (ecart.inDays < 30) {
    final int jours = ecart.inDays;
    return 'il y a $jours jour${jours > 1 ? 's' : ''}';
  }
  return 'le ${dateComplete(date)}';
}
