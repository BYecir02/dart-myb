import 'conversions.dart';

/// Une évaluation obtenue par un enfant dans une matière.
///
/// Toutes les notes ne sont pas sur 20 : un contrôle peut être noté sur 10 ou
/// sur 40. Le modèle conserve donc la valeur brute et son barème, et expose
/// séparément la conversion sur 20. Les moyennes restent ainsi comparables
/// d'une évaluation à l'autre.
class Note {
  /// Identifiant du document dans la collection `notes`.
  final String id;

  /// Enfant concerné par l'évaluation.
  final String idEnfant;

  /// Matière, par exemple `Mathématiques`.
  final String matiere;

  /// Intitulé de l'évaluation, par exemple `Contrôle sur les fractions`.
  final String intitule;

  /// Note obtenue, exprimée dans le barème ci-dessous.
  final double valeur;

  /// Barème de l'évaluation. Vaut 20 dans la grande majorité des cas.
  final double bareme;

  /// Poids de l'évaluation dans la moyenne de la matière.
  final double coefficient;

  /// Date de l'évaluation. Peut être `null` si le champ manque en base.
  final DateTime? date;

  /// Commentaire laissé par le professeur. Souvent vide.
  final String appreciation;

  const Note({
    required this.id,
    required this.idEnfant,
    required this.matiere,
    required this.intitule,
    required this.valeur,
    required this.bareme,
    required this.coefficient,
    required this.date,
    required this.appreciation,
  });

  /// Construit une note à partir d'un document Firestore.
  ///
  /// Le barème et le coefficient reçoivent une valeur de repli lorsqu'ils sont
  /// absents ou nuls en base : sans cette précaution, une division par zéro
  /// remonterait jusqu'au calcul des moyennes.
  factory Note.depuisFirestore(String id, Map<String, dynamic> donnees) {
    final double baremeLu = versDecimal(donnees['bareme'], defaut: 20);
    final double coefficientLu = versDecimal(donnees['coefficient'], defaut: 1);

    return Note(
      id: id,
      idEnfant: versTexte(donnees['idEnfant']),
      matiere: versTexte(donnees['matiere'], defaut: 'Matière inconnue'),
      intitule: versTexte(donnees['intitule'], defaut: 'Évaluation'),
      valeur: versDecimal(donnees['valeur']),
      bareme: baremeLu > 0 ? baremeLu : 20,
      coefficient: coefficientLu > 0 ? coefficientLu : 1,
      date: versDate(donnees['date']),
      appreciation: versTexte(donnees['appreciation']),
    );
  }

  /// Transforme la note en Map, prête à être envoyée à Firestore.
  Map<String, dynamic> versFirestore() {
    return {
      'idEnfant': idEnfant,
      'matiere': matiere,
      'intitule': intitule,
      'valeur': valeur,
      'bareme': bareme,
      'coefficient': coefficient,
      'date': date,
      'appreciation': appreciation,
    };
  }

  /// Reconstruit une note depuis le cache local.
  ///
  /// Le format du cache est identique à celui de Firestore, à ceci près que la
  /// date y est une chaîne ISO et que l'identifiant y figure. La lecture est
  /// donc déléguée à [Note.depuisFirestore], qui sait déjà interpréter une date
  /// en texte grâce à `versDate`.
  factory Note.depuisJson(Map<String, dynamic> json) {
    return Note.depuisFirestore(versTexte(json['id']), json);
  }

  /// Sérialise la note pour le stockage local.
  ///
  /// La date devient une chaîne ISO : `jsonEncode` ne sait pas écrire un
  /// [DateTime]. L'identifiant est ajouté car, contrairement à Firestore, le
  /// cache ne le porte pas ailleurs.
  Map<String, dynamic> versJson() {
    return {
      ...versFirestore(),
      'id': id,
      'date': date?.toIso8601String(),
    };
  }

  /// La note ramenée sur 20, seule échelle comparable entre évaluations.
  ///
  /// Le barème est garanti strictement positif par le constructeur nommé, la
  /// division est donc sûre.
  double get valeurSurVingt => valeur / bareme * 20;

  /// Affichage brut de l'évaluation, par exemple `15.5 / 20`.
  ///
  /// Les décimales inutiles sont retirées : on écrit `15 / 20`, pas `15.0 / 20`.
  String get affichage => '${_sansZeroInutile(valeur)} / ${_sansZeroInutile(bareme)}';

  /// Affichage du coefficient, par exemple `coef. 2`.
  String get affichageCoefficient => 'coef. ${_sansZeroInutile(coefficient)}';

  /// Indique si le professeur a laissé un commentaire.
  bool get possedeUneAppreciation => appreciation.isNotEmpty;

  /// Retire la décimale d'un nombre entier : `15.0` devient `15`.
  static String _sansZeroInutile(double nombre) {
    return nombre == nombre.roundToDouble()
        ? nombre.toStringAsFixed(0)
        : nombre.toStringAsFixed(1);
  }
}
