import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeles/cours.dart';
import '../modeles/enfant.dart';
import '../modeles/note.dart';
import '../modeles/utilisateur.dart';

/// Service regroupant tous les échanges avec Cloud Firestore.
///
/// C'est le seul fichier du projet, avec [ServiceAuth], à importer le SDK
/// Firebase. Aucune page ni aucun widget ne manipule directement un
/// `DocumentSnapshot` : les documents ressortent d'ici déjà convertis en objets
/// [Utilisateur], [Enfant], [Note] ou [Cours].
///
/// Structure de la base :
/// ```
/// utilisateurs/{uid}   un document par parent, contenant la liste `enfants`
/// enfants/{id}         un document par enfant, rattaché par `idParent`
/// notes/{id}           une évaluation, rattachée par `idEnfant`
/// cours/{id}           un créneau hebdomadaire, rattaché par `idEnfant`
/// ```
///
/// **Choix assumé sur le tri.** Les requêtes filtrent côté serveur avec
/// `where`, mais trient côté Dart. Associer un `where` et un `orderBy` sur deux
/// champs différents impose à Firestore la création manuelle d'un index
/// composite, sinon la requête échoue à l'exécution. Le volume de données d'un
/// enfant se compte en dizaines de documents : trier en mémoire coûte moins que
/// d'imposer cette configuration à qui voudra lancer le projet.
class ServiceFirestore {
  final FirebaseFirestore _base;

  /// La base est injectable afin de pouvoir substituer une instance de test.
  /// En usage normal, l'instance par défaut du SDK suffit.
  ServiceFirestore({FirebaseFirestore? base})
    : _base = base ?? FirebaseFirestore.instance;

  /// Noms des collections, regroupés pour éviter les fautes de frappe
  /// dispersées dans le fichier.
  static const String collectionUtilisateurs = 'utilisateurs';
  static const String collectionEnfants = 'enfants';
  static const String collectionNotes = 'notes';
  static const String collectionCours = 'cours';

  // --- Lectures en temps réel ---

  /// Flux du profil du parent connecté.
  ///
  /// Émet `null` tant que le document n'existe pas, ce qui arrive pendant le
  /// court instant séparant la création du compte de l'écriture du profil.
  Stream<Utilisateur?> profilEnTempsReel(String uid) {
    return _base
        .collection(collectionUtilisateurs)
        .doc(uid)
        .snapshots()
        .map((document) {
          final Map<String, dynamic>? donnees = document.data();
          if (donnees == null) {
            return null;
          }
          return Utilisateur.depuisFirestore(document.id, donnees);
        });
  }

  /// Flux des enfants rattachés à un parent, triés par prénom.
  Stream<List<Enfant>> enfantsEnTempsReel(String idParent) {
    return _base
        .collection(collectionEnfants)
        .where('idParent', isEqualTo: idParent)
        .snapshots()
        .map((instantane) {
          final List<Enfant> enfants = instantane.docs
              .map((doc) => Enfant.depuisFirestore(doc.id, doc.data()))
              .toList();
          enfants.sort((a, b) => a.prenom.compareTo(b.prenom));
          return enfants;
        });
  }

  /// Flux des évaluations d'un enfant, de la plus récente à la plus ancienne.
  ///
  /// Les notes sans date sont renvoyées en fin de liste : elles proviennent
  /// d'un document incomplet et n'ont pas à occuper la tête de l'affichage.
  Stream<List<Note>> notesEnTempsReel(String idEnfant) {
    return _base
        .collection(collectionNotes)
        .where('idEnfant', isEqualTo: idEnfant)
        .snapshots()
        .map((instantane) {
          final List<Note> notes = instantane.docs
              .map((doc) => Note.depuisFirestore(doc.id, doc.data()))
              .toList();
          notes.sort(_deLaPlusRecente);
          return notes;
        });
  }

  /// Flux des créneaux d'un enfant, triés par jour puis par heure de début.
  Stream<List<Cours>> coursEnTempsReel(String idEnfant) {
    return _base
        .collection(collectionCours)
        .where('idEnfant', isEqualTo: idEnfant)
        .snapshots()
        .map((instantane) {
          final List<Cours> cours = instantane.docs
              .map((doc) => Cours.depuisFirestore(doc.id, doc.data()))
              .toList();
          cours.sort(_parJourPuisHeure);
          return cours;
        });
  }

  // --- Écritures ---

  /// Crée ou remplace le document de profil d'un parent.
  ///
  /// Appelé à l'inscription. L'identifiant du document est l'`uid` Firebase
  /// Auth, ce qui garantit qu'un compte ne peut avoir qu'un seul profil.
  Future<void> enregistrerProfil(Utilisateur utilisateur) async {
    await _base
        .collection(collectionUtilisateurs)
        .doc(utilisateur.id)
        .set(utilisateur.versFirestore());
  }

  /// Ajoute un enfant et renvoie l'identifiant attribué par Firestore.
  Future<String> ajouterEnfant(Enfant enfant) async {
    final DocumentReference<Map<String, dynamic>> document = await _base
        .collection(collectionEnfants)
        .add(enfant.versFirestore());
    return document.id;
  }

  Future<void> ajouterNote(Note note) async {
    await _base.collection(collectionNotes).add(note.versFirestore());
  }

  Future<void> ajouterCours(Cours cours) async {
    await _base.collection(collectionCours).add(cours.versFirestore());
  }

  /// Ajoute l'identifiant d'un enfant à la liste du parent.
  ///
  /// `arrayUnion` évite les doublons et `merge` crée le document s'il manque,
  /// ce qui rend l'opération sûre même appelée deux fois.
  Future<void> rattacherEnfant({
    required String uid,
    required String idEnfant,
  }) async {
    await _base.collection(collectionUtilisateurs).doc(uid).set({
      'enfants': FieldValue.arrayUnion([idEnfant]),
    }, SetOptions(merge: true));
  }

  /// Compte les enfants d'un parent.
  ///
  /// Sert à savoir si la base a déjà été peuplée, afin de ne pas proposer de
  /// générer les données de démonstration une seconde fois.
  Future<int> nombreDEnfants(String idParent) async {
    final QuerySnapshot<Map<String, dynamic>> instantane = await _base
        .collection(collectionEnfants)
        .where('idParent', isEqualTo: idParent)
        .get();
    return instantane.docs.length;
  }

  // --- Comparateurs de tri ---

  /// De la note la plus récente à la plus ancienne, les dates absentes à la fin.
  static int _deLaPlusRecente(Note a, Note b) {
    if (a.date == null && b.date == null) {
      return 0;
    }
    if (a.date == null) {
      return 1;
    }
    if (b.date == null) {
      return -1;
    }
    return b.date!.compareTo(a.date!);
  }

  /// Du lundi au vendredi, puis dans l'ordre chronologique de la journée.
  static int _parJourPuisHeure(Cours a, Cours b) {
    final int ecartDeJour = a.jour.compareTo(b.jour);
    if (ecartDeJour != 0) {
      return ecartDeJour;
    }
    return a.debutEnMinutes.compareTo(b.debutEnMinutes);
  }
}
