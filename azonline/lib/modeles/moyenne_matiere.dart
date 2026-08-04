import 'note.dart';

/// Moyenne obtenue par un enfant dans une matière.
///
/// Contrairement aux quatre autres modèles, celui-ci ne correspond à aucune
/// collection Firestore : il n'a donc ni `depuisFirestore` ni `versFirestore`.
/// C'est un résultat calculé à partir d'une liste de [Note].
///
/// Le calcul vit ici plutôt que dans une page, pour deux raisons. D'abord parce
/// qu'il s'agit de logique métier et non d'affichage. Ensuite parce qu'il
/// devient testable sans lancer l'application ni contacter le réseau.
class MoyenneMatiere {
  /// Nom de la matière concernée.
  final String matiere;

  /// Moyenne ramenée sur 20, pondérée par les coefficients.
  final double valeur;

  /// Nombre d'évaluations ayant servi au calcul.
  final int nombreDeNotes;

  const MoyenneMatiere({
    required this.matiere,
    required this.valeur,
    required this.nombreDeNotes,
  });

  /// Calcule la moyenne d'une matière à partir de ses évaluations.
  ///
  /// La moyenne est **pondérée** : chaque note pèse selon son coefficient. Un
  /// devoir surveillé de coefficient 3 compte donc trois fois plus qu'une
  /// interrogation de coefficient 1.
  ///
  /// Chaque note est d'abord ramenée sur 20, faute de quoi un 8 sur 10 et un 8
  /// sur 20 seraient additionnés comme s'ils valaient la même chose.
  factory MoyenneMatiere.depuisNotes(String matiere, List<Note> notes) {
    if (notes.isEmpty) {
      return MoyenneMatiere(matiere: matiere, valeur: 0, nombreDeNotes: 0);
    }

    double sommePonderee = 0;
    double sommeDesCoefficients = 0;

    for (final Note note in notes) {
      sommePonderee += note.valeurSurVingt * note.coefficient;
      sommeDesCoefficients += note.coefficient;
    }

    // Le constructeur de Note garantit un coefficient strictement positif,
    // mais on reste défensif : une liste construite à la main dans un test
    // pourrait contourner cette garantie.
    if (sommeDesCoefficients <= 0) {
      return MoyenneMatiere(
        matiere: matiere,
        valeur: 0,
        nombreDeNotes: notes.length,
      );
    }

    return MoyenneMatiere(
      matiere: matiere,
      valeur: sommePonderee / sommeDesCoefficients,
      nombreDeNotes: notes.length,
    );
  }

  /// Regroupe un ensemble de notes par matière et calcule chaque moyenne.
  ///
  /// Le résultat est trié par ordre alphabétique, pour que l'ordre des matières
  /// reste stable d'un affichage à l'autre.
  static List<MoyenneMatiere> parMatiere(List<Note> notes) {
    final Map<String, List<Note>> parNom = <String, List<Note>>{};

    for (final Note note in notes) {
      parNom.putIfAbsent(note.matiere, () => <Note>[]).add(note);
    }

    final List<MoyenneMatiere> moyennes = parNom.entries
        .map((entree) => MoyenneMatiere.depuisNotes(entree.key, entree.value))
        .toList();

    moyennes.sort((a, b) => a.matiere.compareTo(b.matiere));
    return moyennes;
  }

  /// Calcule la moyenne générale à partir des moyennes de chaque matière.
  ///
  /// C'est la moyenne **simple** des moyennes, comme sur un bulletin scolaire :
  /// chaque matière pèse le même poids, indépendamment de son nombre
  /// d'évaluations. Une matière avec deux notes compte donc autant qu'une
  /// matière qui en compte dix.
  ///
  /// Renvoie `null` lorsqu'aucune moyenne exploitable n'est disponible. Ce
  /// `null` est volontaire : il permet à l'interface d'afficher un tiret plutôt
  /// qu'un zéro trompeur.
  static double? moyenneGenerale(List<MoyenneMatiere> moyennes) {
    final List<MoyenneMatiere> exploitables = moyennes
        .where((moyenne) => moyenne.nombreDeNotes > 0)
        .toList();

    if (exploitables.isEmpty) {
      return null;
    }

    final double somme = exploitables.fold<double>(
      0,
      (total, moyenne) => total + moyenne.valeur,
    );
    return somme / exploitables.length;
  }

  /// Moyenne arrondie au dixième, par exemple `13.4`.
  String get affichage => valeur.toStringAsFixed(1);

  /// Libellé du nombre d'évaluations, accordé au singulier ou au pluriel.
  String get affichageNombreDeNotes {
    return nombreDeNotes <= 1 ? '$nombreDeNotes note' : '$nombreDeNotes notes';
  }
}
