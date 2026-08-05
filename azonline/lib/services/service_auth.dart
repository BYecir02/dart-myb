import 'package:firebase_auth/firebase_auth.dart';

import '../modeles/utilisateur.dart';
import 'service_firestore.dart';

/// Service regroupant tous les échanges avec Firebase Auth.
///
/// Toutes les méthodes sont asynchrones : chaque appel part sur le réseau.
///
/// L'écriture du profil est déléguée à [ServiceFirestore] plutôt qu'effectuée
/// ici. Chaque service reste ainsi responsable d'une seule technologie, et la
/// structure du document `utilisateurs` n'est décrite qu'à un seul endroit.
class ServiceAuth {
  final FirebaseAuth _auth;
  final ServiceFirestore _firestore;

  /// Les deux dépendances sont injectables pour faciliter les tests.
  ServiceAuth({FirebaseAuth? auth, ServiceFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? ServiceFirestore();

  /// Flux qui émet le compte courant, ou `null` après une déconnexion.
  ///
  /// C'est lui qui verrouille l'application : tant qu'il vaut `null`, aucun
  /// écran de suivi scolaire n'est atteignable.
  Stream<User?> get changementsUtilisateur => _auth.authStateChanges();

  /// Compte actuellement connecté, sans passer par le flux.
  User? get utilisateurActuel => _auth.currentUser;

  /// Crée un compte, puis son document de profil.
  ///
  /// Les deux opérations vont de pair : un compte sans profil laisserait
  /// l'application incapable d'afficher un nom ou de retrouver les enfants.
  Future<void> inscription({
    required String email,
    required String motDePasse,
    required String nom,
    required String prenom,
  }) async {
    final UserCredential identifiants = await _auth
        .createUserWithEmailAndPassword(email: email, password: motDePasse);

    final User? compte = identifiants.user;
    if (compte == null) {
      return;
    }

    await _firestore.enregistrerProfil(
      Utilisateur(
        id: compte.uid,
        email: email,
        nom: nom,
        prenom: prenom,
        dateInscription: DateTime.now(),
        enfants: const <String>[],
      ),
    );
  }

  Future<void> connexion({
    required String email,
    required String motDePasse,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: motDePasse);
  }

  Future<void> deconnexion() async {
    await _auth.signOut();
  }

  /// Traduit les codes d'erreur techniques de Firebase en messages lisibles.
  ///
  /// Sans cette traduction, l'utilisateur verrait s'afficher des chaînes comme
  /// `invalid-credential`, qui ne lui apprennent rien.
  static String messageDErreur(FirebaseAuthException erreur) {
    switch (erreur.code) {
      case 'invalid-email':
        return 'L\'adresse électronique n\'est pas valide.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cette adresse.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Adresse ou mot de passe incorrect.';
      case 'network-request-failed':
        return 'Pas de connexion à internet.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 'operation-not-allowed':
        return 'La connexion par adresse électronique n\'est pas activée '
            'sur le projet Firebase.';
      default:
        return 'Une erreur est survenue : ${erreur.code}';
    }
  }
}
