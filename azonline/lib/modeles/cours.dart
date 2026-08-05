import 'conversions.dart';

/// Un créneau de l'emploi du temps hebdomadaire d'un enfant.
///
/// Les horaires sont stockés en texte au format `HH:mm`. Ce choix garde les
/// documents lisibles dans la console Firebase et évite de manipuler des dates
/// complètes pour une information qui se répète chaque semaine. Le modèle
/// expose la conversion en minutes, seule forme réellement comparable.
class Cours {
  /// Identifiant du document dans la collection `cours`.
  final String id;

  /// Enfant concerné par ce créneau.
  final String idEnfant;

  /// Matière enseignée pendant le créneau.
  final String matiere;

  /// Jour de la semaine, de 1 pour lundi à 5 pour vendredi.
  final int jour;

  /// Heure de début au format `HH:mm`, par exemple `08:00`.
  final String heureDebut;

  /// Heure de fin au format `HH:mm`.
  final String heureFin;

  /// Salle de cours, par exemple `B12`.
  final String salle;

  /// Nom du professeur.
  final String professeur;

  const Cours({
    required this.id,
    required this.idEnfant,
    required this.matiere,
    required this.jour,
    required this.heureDebut,
    required this.heureFin,
    required this.salle,
    required this.professeur,
  });

  /// Libellés des jours ouvrés, indexés de 1 à 5.
  static const List<String> joursDeLaSemaine = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
  ];

  /// Construit un cours à partir d'un document Firestore.
  ///
  /// Le jour est ramené de force dans l'intervalle 1 à 5 : un document portant
  /// un samedi ou une valeur aberrante ne doit pas faire disparaître le créneau
  /// de l'affichage ni provoquer un accès hors limites.
  factory Cours.depuisFirestore(String id, Map<String, dynamic> donnees) {
    final int jourLu = versEntier(donnees['jour'], defaut: 1);

    return Cours(
      id: id,
      idEnfant: versTexte(donnees['idEnfant']),
      matiere: versTexte(donnees['matiere'], defaut: 'Matière inconnue'),
      jour: jourLu.clamp(1, joursDeLaSemaine.length),
      heureDebut: versTexte(donnees['heureDebut'], defaut: '00:00'),
      heureFin: versTexte(donnees['heureFin'], defaut: '00:00'),
      salle: versTexte(donnees['salle']),
      professeur: versTexte(donnees['professeur']),
    );
  }

  /// Transforme le cours en Map, prête à être envoyée à Firestore.
  Map<String, dynamic> versFirestore() {
    return {
      'idEnfant': idEnfant,
      'matiere': matiere,
      'jour': jour,
      'heureDebut': heureDebut,
      'heureFin': heureFin,
      'salle': salle,
      'professeur': professeur,
    };
  }

  /// Nom du jour, par exemple `Mardi`.
  String get libelleDuJour => joursDeLaSemaine[jour - 1];

  /// Créneau complet, par exemple `08:00 - 09:00`.
  String get creneau => '$heureDebut - $heureFin';

  /// Heure de début exprimée en minutes depuis minuit.
  /// C'est cette valeur qui sert à trier les cours d'une journée.
  int get debutEnMinutes => minutesDepuisTexte(heureDebut);

  /// Heure de fin exprimée en minutes depuis minuit.
  int get finEnMinutes => minutesDepuisTexte(heureFin);

  /// Durée du cours en minutes. Vaut zéro si les horaires sont incohérents.
  int get dureeEnMinutes {
    final int duree = finEnMinutes - debutEnMinutes;
    return duree > 0 ? duree : 0;
  }

  /// Indique si le cours a lieu au moment donné.
  ///
  /// Sert à mettre en évidence le créneau courant dans l'emploi du temps.
  /// Le paramètre est explicite plutôt que lu depuis l'horloge interne : la
  /// méthode reste ainsi testable sans dépendre de l'heure réelle.
  bool estEnCours(DateTime maintenant) {
    if (maintenant.weekday != jour) {
      return false;
    }
    final int minutesActuelles = maintenant.hour * 60 + maintenant.minute;
    return minutesActuelles >= debutEnMinutes &&
        minutesActuelles < finEnMinutes;
  }

  /// Convertit un horaire `HH:mm` en minutes depuis minuit.
  ///
  /// Renvoie zéro si le texte n'a pas la forme attendue, ce qui place le
  /// créneau en tête de journée plutôt que de faire échouer le tri.
  static int minutesDepuisTexte(String horaire) {
    final List<String> morceaux = horaire.split(':');
    if (morceaux.length != 2) {
      return 0;
    }
    final int? heures = int.tryParse(morceaux[0]);
    final int? minutes = int.tryParse(morceaux[1]);
    if (heures == null || minutes == null) {
      return 0;
    }
    return heures * 60 + minutes;
  }
}
