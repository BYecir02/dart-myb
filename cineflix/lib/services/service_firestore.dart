import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeles/film.dart';

/// Service regroupant tous les échanges avec Cloud Firestore.
///
/// Structure de la base :
///   Collection `films`        -> un document par film.
///   Collection `utilisateurs` -> un document par compte, contenant la
///                                liste `favoris` (les identifiants des films).
class ServiceFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Flux temps réel du catalogue : dès qu'un film est ajouté ou modifié
  /// dans la console Firebase, l'interface se met à jour toute seule.
  Stream<List<Film>> filmsEnTempsReel() {
    return _db.collection('films').orderBy('titre').snapshots().map((instantane) {
      return instantane.docs
          .map((document) => Film.depuisFirestore(document.id, document.data()))
          .toList();
    });
  }

  /// Flux temps réel des identifiants de films mis en favoris par l'utilisateur.
  Stream<List<String>> favorisEnTempsReel(String uid) {
    return _db.collection('utilisateurs').doc(uid).snapshots().map((document) {
      final donnees = document.data();
      if (donnees == null) {
        return <String>[];
      }
      final liste = donnees['favoris'] as List<dynamic>? ?? <dynamic>[];
      return liste.map((element) => element.toString()).toList();
    });
  }

  /// Lit les informations du profil (email, date d'inscription).
  Stream<Map<String, dynamic>> profilEnTempsReel(String uid) {
    return _db.collection('utilisateurs').doc(uid).snapshots().map((document) {
      return document.data() ?? <String, dynamic>{};
    });
  }

  /// Écrit le favori dans la base distante.
  /// `merge: true` crée le document s'il n'existe pas encore.
  Future<void> ajouterAuxFavoris({
    required String uid,
    required String idFilm,
  }) async {
    await _db.collection('utilisateurs').doc(uid).set(
      {
        'favoris': FieldValue.arrayUnion([idFilm]),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> retirerDesFavoris({
    required String uid,
    required String idFilm,
  }) async {
    await _db.collection('utilisateurs').doc(uid).set(
      {
        'favoris': FieldValue.arrayRemove([idFilm]),
      },
      SetOptions(merge: true),
    );
  }

  /// Compte les films présents en base (sert à savoir si le catalogue est vide).
  Future<int> nombreDeFilms() async {
    final instantane = await _db.collection('films').get();
    return instantane.docs.length;
  }

  /// Ajoute un film au catalogue (utilisé par l'outil de peuplement).
  Future<void> ajouterFilm(Film film) async {
    await _db.collection('films').add(film.versFirestore());
  }
}
