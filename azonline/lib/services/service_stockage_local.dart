import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modeles/note.dart';

/// Service regroupant tous les échanges avec le stockage du téléphone.
///
/// Trois informations y sont conservées :
///
/// - **l'enfant actif**, pour que l'application rouvre là où le parent l'avait
///   laissée plutôt que de repartir systématiquement sur le premier enfant ;
/// - **les dernières notes lues**, afin qu'elles restent consultables sans
///   connexion ;
/// - **la date de la dernière lecture réussie**, affichée sous le tableau de
///   bord pour que le parent sache s'il regarde des données fraîches.
///
/// Les préférences sont reçues par le constructeur plutôt que récupérées ici.
/// L'instance est obtenue une seule fois au démarrage de l'application, ce qui
/// rend toutes les méthodes de lecture synchrones : un provider peut donc lire
/// l'enfant mémorisé sans passer par un état de chargement.
class ServiceStockageLocal {
  final SharedPreferences _preferences;

  const ServiceStockageLocal(this._preferences);

  /// Identifiant de l'enfant affiché en dernier.
  static const String cleEnfantSelectionne = 'enfantSelectionne';

  /// Préfixe du cache des notes. L'identifiant de l'enfant est ajouté derrière,
  /// sans quoi les notes d'un enfant écraseraient celles de l'autre.
  static const String prefixeCacheDesNotes = 'cacheNotes_';

  /// Date de la dernière lecture réussie depuis Firestore.
  static const String cleDateDerniereSynchro = 'dateDerniereSynchro';

  // --- L'enfant sélectionné ---

  /// Lit l'enfant mémorisé, ou `null` si aucun choix n'a encore été fait.
  String? lireEnfantSelectionne() {
    return _preferences.getString(cleEnfantSelectionne);
  }

  /// Mémorise l'enfant actif. Passer `null` efface le choix.
  Future<void> enregistrerEnfantSelectionne(String? identifiant) async {
    if (identifiant == null) {
      await _preferences.remove(cleEnfantSelectionne);
      return;
    }
    await _preferences.setString(cleEnfantSelectionne, identifiant);
  }

  // --- Le cache des notes ---

  /// Relit les notes mises en cache pour un enfant.
  ///
  /// Renvoie une liste vide si le cache est absent ou illisible. Un cache
  /// corrompu, par exemple après un changement de format, ne doit pas empêcher
  /// l'application de démarrer : elle repartira simplement du réseau.
  List<Note> lireNotesEnCache(String idEnfant) {
    final String? contenu = _preferences.getString(
      '$prefixeCacheDesNotes$idEnfant',
    );
    if (contenu == null || contenu.isEmpty) {
      return const <Note>[];
    }

    try {
      final List<dynamic> lignes = jsonDecode(contenu) as List<dynamic>;
      return lignes
          .map((ligne) => Note.depuisJson(ligne as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <Note>[];
    }
  }

  /// Enregistre les notes d'un enfant et met à jour la date de synchronisation.
  Future<void> enregistrerNotesEnCache(
    String idEnfant,
    List<Note> notes,
  ) async {
    final String contenu = jsonEncode(
      notes.map((note) => note.versJson()).toList(),
    );

    await _preferences.setString('$prefixeCacheDesNotes$idEnfant', contenu);
    await _preferences.setString(
      cleDateDerniereSynchro,
      DateTime.now().toIso8601String(),
    );
  }

  // --- La date de synchronisation ---

  /// Date de la dernière lecture réussie, ou `null` si aucune n'a eu lieu.
  DateTime? lireDateDerniereSynchro() {
    final String? contenu = _preferences.getString(cleDateDerniereSynchro);
    if (contenu == null) {
      return null;
    }
    return DateTime.tryParse(contenu);
  }

  // --- L'entretien ---

  /// Efface toutes les données locales de l'application.
  ///
  /// Appelé à la déconnexion : sans cela, le parent suivant à se connecter sur
  /// le même appareil retrouverait l'enfant et les notes du précédent.
  Future<void> oublierTout() async {
    final Iterable<String> aSupprimer = _preferences.getKeys().where((cle) {
      return cle == cleEnfantSelectionne ||
          cle == cleDateDerniereSynchro ||
          cle.startsWith(prefixeCacheDesNotes);
    }).toList();

    for (final String cle in aSupprimer) {
      await _preferences.remove(cle);
    }
  }
}
