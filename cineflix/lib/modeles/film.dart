/// Modèle de données représentant un film du catalogue.
///
/// Les films ne sont jamais écrits en dur dans l'interface : ils sont
/// construits à partir des documents de la collection Firestore `films`.
class Film {
  final String id;
  final String titre;
  final String genre;
  final int ageMinimum;
  final String synopsis;
  final String imageUrl;

  Film({
    required this.id,
    required this.titre,
    required this.genre,
    required this.ageMinimum,
    required this.synopsis,
    required this.imageUrl,
  });

  /// Construit un Film à partir d'un document Firestore.
  ///
  /// L'opérateur `??` fournit une valeur de secours pour chaque champ,
  /// ce qui évite un crash si un document est incomplet en base.
  factory Film.depuisFirestore(String id, Map<String, dynamic> donnees) {
    return Film(
      id: id,
      titre: donnees['titre'] as String? ?? 'Titre inconnu',
      genre: donnees['genre'] as String? ?? 'Non classé',
      ageMinimum: (donnees['ageMinimum'] as num?)?.toInt() ?? 0,
      synopsis: donnees['synopsis'] as String? ?? 'Aucun synopsis disponible.',
      imageUrl: donnees['imageUrl'] as String? ?? '',
    );
  }

  /// Transforme le film en Map, prête à être envoyée à Firestore.
  Map<String, dynamic> versFirestore() {
    return {
      'titre': titre,
      'genre': genre,
      'ageMinimum': ageMinimum,
      'synopsis': synopsis,
      'imageUrl': imageUrl,
    };
  }
}
