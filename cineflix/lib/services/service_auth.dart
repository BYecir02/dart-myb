import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service regroupant tous les échanges avec FirebaseAuth.
///
/// Toutes les méthodes sont asynchrones : chaque appel part sur internet.
class ServiceAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Flux qui émet l'utilisateur courant, ou `null` s'il est déconnecté.
  /// C'est lui qui verrouille l'accès au catalogue.
  Stream<User?> get changementsUtilisateur => _auth.authStateChanges();

  User? get utilisateurActuel => _auth.currentUser;

  /// Crée un compte, puis son document dans la collection `utilisateurs`.
  Future<void> inscription({
    required String email,
    required String motDePasse,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: motDePasse,
    );

    final utilisateur = cred.user;
    if (utilisateur != null) {
      await _db.collection('utilisateurs').doc(utilisateur.uid).set({
        'email': email,
        'dateInscription': FieldValue.serverTimestamp(),
        'favoris': <String>[],
      });
    }
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
  static String messageDErreur(FirebaseAuthException erreur) {
    switch (erreur.code) {
      case 'invalid-email':
        return "L'adresse email n'est pas valide.";
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cette adresse email.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'network-request-failed':
        return 'Pas de connexion internet.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      default:
        return 'Une erreur est survenue : ${erreur.code}';
    }
  }
}
