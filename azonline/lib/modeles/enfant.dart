import 'conversions.dart';

/// Un enfant dont le parent suit la scolarité.
///
/// Les enfants vivent dans leur propre collection `enfants` plutôt que dans un
/// tableau à l'intérieur du document du parent. Ils portent ainsi un
/// identifiant stable, auquel les notes et les cours peuvent se rattacher.
class Enfant {
  /// Identifiant du document dans la collection `enfants`.
  final String id;

  /// Identifiant du parent propriétaire, égal à son `uid` Firebase Auth.
  /// C'est ce champ qui filtre les enfants visibles par le compte connecté.
  final String idParent;

  final String prenom;
  final String nom;

  /// Classe suivie, par exemple `5e B`.
  final String classe;

  /// Nom de l'établissement scolaire.
  final String etablissement;

  const Enfant({
    required this.id,
    required this.idParent,
    required this.prenom,
    required this.nom,
    required this.classe,
    required this.etablissement,
  });

  /// Construit un enfant à partir d'un document Firestore.
  factory Enfant.depuisFirestore(String id, Map<String, dynamic> donnees) {
    return Enfant(
      id: id,
      idParent: versTexte(donnees['idParent']),
      prenom: versTexte(donnees['prenom'], defaut: 'Enfant'),
      nom: versTexte(donnees['nom']),
      classe: versTexte(donnees['classe'], defaut: 'Classe inconnue'),
      etablissement: versTexte(
        donnees['etablissement'],
        defaut: 'Établissement inconnu',
      ),
    );
  }

  /// Transforme l'enfant en Map, prête à être envoyée à Firestore.
  Map<String, dynamic> versFirestore() {
    return {
      'idParent': idParent,
      'prenom': prenom,
      'nom': nom,
      'classe': classe,
      'etablissement': etablissement,
    };
  }

  /// Prénom et nom, prêts à être affichés.
  String get nomComplet => '$prenom $nom'.trim();

  /// Initiales affichées dans le sélecteur d'enfant.
  String get initiales => initialesDe(prenom, nom);

  /// Ligne secondaire du sélecteur, par exemple `5e B, Collège Jean Moulin`.
  String get description => '$classe, $etablissement';
}
