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
import '../services/service_stockage_local.dart';

// --- Les services ---

/// Instance unique du service d'authentification.
final serviceAuthProvider = Provider<ServiceAuth>((ref) {
  return ServiceAuth();
});

/// Instance unique du service de base de données.
final serviceFirestoreProvider = Provider<ServiceFirestore>((ref) {
  return ServiceFirestore();
});

/// Instance unique du service de stockage local.
///
/// Ce provider n'a volontairement pas d'implémentation par défaut : l'accès aux
/// préférences est asynchrone, et il est obtenu une seule fois au démarrage
/// dans `main()`, qui remplace ce provider par l'instance prête. Toutes les
/// lectures deviennent alors synchrones.
///
/// L'erreur ci-dessous ne se déclenche que si l'on oublie ce remplacement, ce
/// qui se voit immédiatement plutôt que de produire un comportement silencieux.
final serviceStockageLocalProvider = Provider<ServiceStockageLocal>((ref) {
  throw UnimplementedError(
    'serviceStockageLocalProvider doit être remplacé au démarrage '
    'de l\'application.',
  );
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
/// La valeur est mémorisée sur le téléphone : l'application rouvre sur le même
/// enfant, sans que le parent ait à le resélectionner à chaque ouverture.
class SelectionEnfant extends Notifier<String?> {
  @override
  String? build() {
    // Lecture synchrone : les préférences ont été chargées au démarrage.
    // L'enfant mémorisé est donc disponible dès la première construction, sans
    // passer par un état intermédiaire qui ferait clignoter l'interface.
    return ref.read(serviceStockageLocalProvider).lireEnfantSelectionne();
  }

  /// Change l'enfant actif et mémorise le choix sur l'appareil.
  ///
  /// L'écriture n'est pas attendue : l'interface doit basculer immédiatement,
  /// et un échec d'écriture locale ne justifie pas de bloquer l'affichage.
  void choisir(String? identifiant) {
    state = identifiant;
    ref.read(serviceStockageLocalProvider).enregistrerEnfantSelectionne(
      identifiant,
    );
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

/// Flux brut des évaluations de l'enfant sélectionné.
///
/// Chaque émission est recopiée dans le stockage local. C'est ce qui alimente
/// la consultation hors connexion : les dernières notes vues restent lisibles
/// même sans réseau.
///
/// L'écriture n'est pas attendue, pour ne pas retarder l'affichage des notes
/// qui viennent d'arriver.
final fluxDesNotesProvider = StreamProvider<List<Note>>((ref) {
  final Enfant? enfant = ref.watch(enfantSelectionneProvider);
  if (enfant == null) {
    return Stream.value(const <Note>[]);
  }

  final ServiceStockageLocal stockage = ref.watch(serviceStockageLocalProvider);

  return ref
      .watch(serviceFirestoreProvider)
      .notesEnTempsReel(enfant.id)
      .map((notes) {
        stockage.enregistrerNotesEnCache(enfant.id, notes);
        return notes;
      });
});

/// Les notes réellement affichées.
///
/// Tant que le réseau n'a rien renvoyé, ou s'il échoue, on retombe sur le
/// cache local. Le parent voit donc les notes de sa dernière consultation
/// plutôt qu'un écran vide, ce qui est la seule chose utile hors connexion.
final notesProvider = Provider<List<Note>>((ref) {
  final AsyncValue<List<Note>> flux = ref.watch(fluxDesNotesProvider);
  if (flux.hasValue) {
    return flux.value!;
  }

  final Enfant? enfant = ref.watch(enfantSelectionneProvider);
  if (enfant == null) {
    return const <Note>[];
  }
  return ref.watch(serviceStockageLocalProvider).lireNotesEnCache(enfant.id);
});

/// Date de la dernière lecture réussie, affichée sous le tableau de bord.
final dateDerniereSynchroProvider = Provider<DateTime?>((ref) {
  // Dépend du flux afin d'être recalculé à chaque arrivée de notes.
  ref.watch(fluxDesNotesProvider);
  return ref.watch(serviceStockageLocalProvider).lireDateDerniereSynchro();
});

/// Moyennes par matière, calculées à partir des notes.
///
/// Le calcul vit dans le modèle [MoyenneMatiere] ; ce provider ne fait que
/// l'appliquer aux notes courantes et mettre le résultat en cache tant
/// qu'elles ne changent pas.
final moyennesProvider = Provider<List<MoyenneMatiere>>((ref) {
  return MoyenneMatiere.parMatiere(ref.watch(notesProvider));
});

/// Moyenne générale, ou `null` si aucune note n'est disponible.
final moyenneGeneraleProvider = Provider<double?>((ref) {
  return MoyenneMatiere.moyenneGenerale(ref.watch(moyennesProvider));
});

/// Les cinq évaluations les plus récentes, pour le tableau de bord.
final dernieresNotesProvider = Provider<List<Note>>((ref) {
  return ref.watch(notesProvider).take(5).toList();
});

/// Évaluations d'une matière donnée, pour l'écran de détail.
///
/// Un provider de famille évite d'ouvrir un second flux vers Firestore : il
/// filtre simplement les notes déjà chargées.
final notesDeLaMatiereProvider = Provider.family<List<Note>, String>((
  ref,
  matiere,
) {
  return ref
      .watch(notesProvider)
      .where((note) => note.matiere == matiere)
      .toList();
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
