import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modeles/film.dart';
import '../services/service_auth.dart';
import '../services/service_firestore.dart';

/// Les Providers sont déclarés en dehors de toute classe (variables globales).
/// Ils constituent le "nuage" d'état accessible depuis n'importe quel widget,
/// ce qui évite de faire transiter les données par les constructeurs.

// --- Les services ---

final serviceAuthProvider = Provider<ServiceAuth>((ref) {
  return ServiceAuth();
});

final serviceFirestoreProvider = Provider<ServiceFirestore>((ref) {
  return ServiceFirestore();
});

// --- L'état de connexion ---

/// Émet l'utilisateur connecté, ou `null`. C'est ce provider qui décide
/// si l'on affiche l'écran de connexion ou le catalogue.
final utilisateurProvider = StreamProvider<User?>((ref) {
  return ref.watch(serviceAuthProvider).changementsUtilisateur;
});

// --- Les données distantes ---

/// Le catalogue, lu en temps réel depuis Firestore.
final filmsProvider = StreamProvider<List<Film>>((ref) {
  return ref.watch(serviceFirestoreProvider).filmsEnTempsReel();
});

/// Les identifiants des films mis en favoris par l'utilisateur connecté.
final favorisProvider = StreamProvider<List<String>>((ref) {
  final utilisateur = ref.watch(utilisateurProvider).value;
  if (utilisateur == null) {
    return Stream.value(<String>[]);
  }
  return ref.watch(serviceFirestoreProvider).favorisEnTempsReel(utilisateur.uid);
});

/// Les informations du document profil de l'utilisateur connecté.
final profilProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final utilisateur = ref.watch(utilisateurProvider).value;
  if (utilisateur == null) {
    return Stream.value(<String, dynamic>{});
  }
  return ref.watch(serviceFirestoreProvider).profilEnTempsReel(utilisateur.uid);
});

/// Croise le catalogue et la liste des favoris pour obtenir les films favoris
/// complets, prêts à être affichés dans l'onglet Profil.
final filmsFavorisProvider = Provider<List<Film>>((ref) {
  final films = ref.watch(filmsProvider).value ?? <Film>[];
  final favoris = ref.watch(favorisProvider).value ?? <String>[];
  return films.where((film) => favoris.contains(film.id)).toList();
});
