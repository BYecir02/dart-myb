import 'conversions.dart';

/// Le parent connecté à l'application.
///
/// Un document de la collection `utilisateurs` est créé à l'inscription, avec
/// pour identifiant l'`uid` fourni par Firebase Auth. Les deux systèmes restent
/// ainsi alignés : l'identifiant d'authentification est aussi la clé du profil.
class Utilisateur {
  /// Identifiant du document, égal à l'`uid` Firebase Auth.
  final String id;

  final String email;
  final String nom;
  final String prenom;

  /// Date de création du compte. Peut être `null` juste après l'inscription,
  /// le temps que le serveur inscrive son horodatage.
  final DateTime? dateInscription;

  /// Identifiants des enfants rattachés à ce parent.
  final List<String> enfants;

  const Utilisateur({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.dateInscription,
    required this.enfants,
  });

  /// Construit un utilisateur à partir d'un document Firestore.
  factory Utilisateur.depuisFirestore(String id, Map<String, dynamic> donnees) {
    return Utilisateur(
      id: id,
      email: versTexte(donnees['email']),
      nom: versTexte(donnees['nom']),
      prenom: versTexte(donnees['prenom']),
      dateInscription: versDate(donnees['dateInscription']),
      enfants: versListeDeTextes(donnees['enfants']),
    );
  }

  /// Transforme l'utilisateur en Map, prête à être envoyée à Firestore.
  ///
  /// L'identifiant n'y figure pas : il sert de nom au document et n'a pas à
  /// être dupliqué à l'intérieur.
  Map<String, dynamic> versFirestore() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'dateInscription': dateInscription,
      'enfants': enfants,
    };
  }

  /// Prénom et nom, prêts à être affichés.
  ///
  /// Si le profil est incomplet, on retombe sur l'adresse électronique plutôt
  /// que d'afficher une ligne vide.
  String get nomComplet {
    final String complet = '$prenom $nom'.trim();
    return complet.isEmpty ? email : complet;
  }

  /// Initiales affichées dans la pastille du profil.
  String get initiales => initialesDe(prenom, nom);

  /// Indique si le parent a au moins un enfant rattaché.
  bool get possedeDesEnfants => enfants.isNotEmpty;
}
