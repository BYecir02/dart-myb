/// Couche de logique et d'état de l'application.
///
/// Les providers sont déclarés en dehors de toute classe : ils forment un
/// espace d'état accessible depuis n'importe quel widget, sans avoir à faire
/// transiter les données de constructeur en constructeur.
///
/// C'est ici que se fait la jonction entre la couche données et la couche
/// présentation. Une page ne connaît que ces providers ; elle n'appelle jamais
/// un service directement, et n'importe aucun paquet Firebase.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modeles/cours.dart';
import '../modeles/enfant.dart';
import '../modeles/moyenne_matiere.dart';
import '../modeles/note.dart';
import '../modeles/utilisateur.dart';
import '../services/service_auth.dart';
import '../services/service_firestore.dart';

// --- Les services ---

/// Instance unique du service d'authentification.
final serviceAuthProvider = Provider<ServiceAuth>((ref) {
  return ServiceAuth();
});

/// Instance unique du service de base de données.
final serviceFirestoreProvider = Provider<ServiceFirestore>((ref) {
  return ServiceFirestore();
});

// --- L'état de connexion ---

/// Émet le compte Firebase connecté, ou `null`.
///
/// C'est ce provider qui décide si l'application affiche l'écran de connexion
/// ou le suivi scolaire.
final compteProvider = StreamProvider<User?>((ref) {
  return ref.watch(serviceAuthProvider).changementsUtilisateur;
});

/// Identifiant du parent connecté, ou `null` s'il n'y a pas de session.
///
/// Extrait une fois ici plutôt que dans chaque provider qui en a besoin.
final identifiantParentProvider = Provider<String?>((ref) {
  return ref.watch(compteProvider).value?.uid;
});

/// Profil du parent, lu en temps réel depuis la collection `utilisateurs`.
final profilProvider = StreamProvider<Utilisateur?>((ref) {
  final String? uid = ref.watch(identifiantParentProvider);
  if (uid == null) {
    return Stream.value(null);
  }
  return ref.watch(serviceFirestoreProvider).profilEnTempsReel(uid);
});

// --- Les enfants ---

/// Enfants rattachés au parent connecté, triés par prénom.
final enfantsProvider = StreamProvider<List<Enfant>>((ref) {
  final String? uid = ref.watch(identifiantParentProvider);
  if (uid == null) {
    return Stream.value(const <Enfant>[]);
  }
  return ref.watch(serviceFirestoreProvider).enfantsEnTempsReel(uid);
});

/// Retient l'enfant choisi par le parent dans le sélecteur.
///
/// L'état ne contient que l'identifiant, pas l'objet complet : ainsi, une mise
/// à jour de l'enfant en base se répercute sans avoir à ressaisir la sélection.
///
/// La valeur est mémorisée sur le téléphone à l'étape F7, afin que
/// l'application rouvre sur le même enfant.
class SelectionEnfant extends Notifier<String?> {
  @override
  String? build() => null;

  /// Change l'enfant actif.
  void choisir(String? identifiant) {
    state = identifiant;
  }
}

final selectionEnfantProvider = NotifierProvider<SelectionEnfant, String?>(
  SelectionEnfant.new,
);

/// L'enfant réellement affiché.
///
/// Si aucun choix n'a été fait, ou si l'identifiant retenu ne correspond plus à
/// aucun enfant, on retombe sur le premier de la liste. L'application affiche
/// donc toujours quelque chose dès qu'un enfant existe.
final enfantSelectionneProvider = Provider<Enfant?>((ref) {
  final List<Enfant> enfants = ref.watch(enfantsProvider).value ?? const [];
  if (enfants.isEmpty) {
    return null;
  }

  final String? choisi = ref.watch(selectionEnfantProvider);
  return enfants.firstWhere(
    (enfant) => enfant.id == choisi,
    orElse: () => enfants.first,
  );
});

// --- Les notes ---

/// Évaluations de l'enfant sélectionné, de la plus récente à la plus ancienne.
final notesProvider = StreamProvider<List<Note>>((ref) {
  final Enfant? enfant = ref.watch(enfantSelectionneProvider);
  if (enfant == null) {
    return Stream.value(const <Note>[]);
  }
  return ref.watch(serviceFirestoreProvider).notesEnTempsReel(enfant.id);
});

/// Moyennes par matière, calculées à partir des notes.
///
/// Le calcul vit dans le modèle [MoyenneMatiere] ; ce provider ne fait que
/// l'appliquer au flux courant et mettre le résultat en cache tant que les
/// notes ne changent pas.
final moyennesProvider = Provider<List<MoyenneMatiere>>((ref) {
  final List<Note> notes = ref.watch(notesProvider).value ?? const [];
  return MoyenneMatiere.parMatiere(notes);
});

/// Moyenne générale, ou `null` si aucune note n'est disponible.
final moyenneGeneraleProvider = Provider<double?>((ref) {
  return MoyenneMatiere.moyenneGenerale(ref.watch(moyennesProvider));
});

/// Les cinq évaluations les plus récentes, pour le tableau de bord.
final dernieresNotesProvider = Provider<List<Note>>((ref) {
  final List<Note> notes = ref.watch(notesProvider).value ?? const [];
  return notes.take(5).toList();
});

/// Évaluations d'une matière donnée, pour l'écran de détail.
///
/// Un provider de famille évite d'ouvrir un second flux vers Firestore : il
/// filtre simplement les notes déjà chargées.
final notesDeLaMatiereProvider = Provider.family<List<Note>, String>((
  ref,
  matiere,
) {
  final List<Note> notes = ref.watch(notesProvider).value ?? const [];
  return notes.where((note) => note.matiere == matiere).toList();
});

// --- L'emploi du temps ---

/// Créneaux de l'enfant sélectionné, triés par jour puis par heure.
final coursProvider = StreamProvider<List<Cours>>((ref) {
  final Enfant? enfant = ref.watch(enfantSelectionneProvider);
  if (enfant == null) {
    return Stream.value(const <Cours>[]);
  }
  return ref.watch(serviceFirestoreProvider).coursEnTempsReel(enfant.id);
});

/// Ramène une date au jour ouvré à afficher.
///
/// Un samedi ou un dimanche renvoie sur le lundi : l'emploi du temps ne couvre
/// que la semaine de classe, et une page vide le week-end serait déroutante.
int jourOuvreDe(DateTime date) {
  return date.weekday > Cours.joursDeLaSemaine.length ? 1 : date.weekday;
}

/// Jour affiché dans l'emploi du temps, du lundi au vendredi.
class JourSelectionne extends Notifier<int> {
  @override
  int build() => jourOuvreDe(DateTime.now());

  /// Change le jour affiché, en restant dans la semaine ouvrée.
  void choisir(int jour) {
    state = jour.clamp(1, Cours.joursDeLaSemaine.length);
  }
}

final jourSelectionneProvider = NotifierProvider<JourSelectionne, int>(
  JourSelectionne.new,
);

/// Créneaux du jour affiché, déjà triés par heure de début.
final coursDuJourProvider = Provider<List<Cours>>((ref) {
  final int jour = ref.watch(jourSelectionneProvider);
  final List<Cours> cours = ref.watch(coursProvider).value ?? const [];
  return cours.where((creneau) => creneau.jour == jour).toList();
});
