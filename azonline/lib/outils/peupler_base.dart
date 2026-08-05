/// Génération des données de démonstration.
///
/// AZOnline n'est relié à aucun système scolaire réel : les enfants, les notes
/// et les emplois du temps sont fictifs. Ce fichier les décrit et les écrit
/// dans Firestore, afin d'éviter de saisir quatre-vingts documents à la main
/// dans la console avant de pouvoir regarder l'application fonctionner.
///
/// Il vit dans `outils/` et non dans `pages/` : c'est un utilitaire de mise en
/// route, pas une fonctionnalité du produit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/cours.dart';
import '../modeles/enfant.dart';
import '../modeles/note.dart';
import '../services/service_firestore.dart';
import '../theme/theme_nature.dart';

// --- La grille horaire ---

/// Heures de début des cinq créneaux d'une journée.
const List<String> creneauxDeLaJournee = [
  '08:00',
  '09:00',
  '10:15',
  '13:30',
  '14:30',
];

/// Durée d'un cours, en minutes.
const int dureeDUnCours = 60;

/// Salle et professeur attachés à chaque matière.
///
/// Les regrouper évite de répéter l'information sur chacun des vingt-cinq
/// créneaux d'un emploi du temps.
const Map<String, List<String>> salleEtProfesseurParMatiere = {
  'Mathématiques': ['B12', 'M. Renard'],
  'Français': ['A04', 'Mme Lefèvre'],
  'Histoire-Géographie': ['A11', 'M. Bernard'],
  'Anglais': ['C03', 'Mme Carter'],
  'SVT': ['D01', 'Mme Nguyen'],
  'EPS': ['Gymnase', 'M. Aubert'],
};

/// Emploi du temps d'une classe de cinquième.
///
/// Une ligne par jour, du lundi au vendredi. Une chaîne vide représente une
/// heure de permanence : un emploi du temps entièrement rempli ne ressemblerait
/// à rien de réel.
const List<List<String>> grilleCinquieme = [
  ['Mathématiques', 'Français', 'Anglais', 'Histoire-Géographie', 'SVT'],
  ['Français', 'Mathématiques', 'SVT', 'EPS', 'EPS'],
  ['Histoire-Géographie', 'Anglais', 'Mathématiques', '', ''],
  ['SVT', 'Français', 'Histoire-Géographie', 'Anglais', 'Mathématiques'],
  ['Mathématiques', 'EPS', 'Français', 'Anglais', ''],
];

/// Emploi du temps d'une classe de troisième.
const List<List<String>> grilleTroisieme = [
  ['Français', 'Mathématiques', 'Histoire-Géographie', 'Anglais', 'EPS'],
  ['Mathématiques', 'SVT', 'Anglais', 'Français', ''],
  ['Anglais', 'Histoire-Géographie', 'Français', '', ''],
  ['Mathématiques', 'Français', 'SVT', 'Histoire-Géographie', 'Anglais'],
  ['EPS', 'EPS', 'Mathématiques', 'SVT', 'Français'],
];

// --- Les enfants et leurs notes ---

/// Les deux enfants créés au peuplement, avec leurs évaluations.
///
/// Chaque note porte le nombre de jours écoulés depuis l'évaluation plutôt
/// qu'une date fixe : le jeu de données reste ainsi récent quelle que soit la
/// date à laquelle il est généré.
///
/// Les deux profils sont volontairement contrastés. Lina réussit bien, Noah est
/// en difficulté en mathématiques. Les quatre couleurs du code de notation sont
/// donc visibles dès l'ouverture de l'application.
const List<Map<String, Object>> enfantsDeDemonstration = [
  {
    'prenom': 'Lina',
    'nom': 'Moreau',
    'classe': '5e B',
    'etablissement': 'Collège Jean Moulin',
    'grille': grilleCinquieme,
    'notes': [
      ['Mathématiques', 'Contrôle sur les fractions', 16.0, 20.0, 2.0, 6, 'Très bon travail, continue.'],
      ['Mathématiques', 'Interrogation sur les puissances', 14.0, 20.0, 1.0, 20, ''],
      ['Mathématiques', 'Devoir surveillé de géométrie', 17.5, 20.0, 3.0, 34, 'Raisonnement rigoureux.'],
      ['Français', 'Dictée préparée', 8.0, 10.0, 1.0, 4, ''],
      ['Français', 'Rédaction sur le portrait', 15.0, 20.0, 2.0, 17, 'Belle langue, quelques répétitions.'],
      ['Français', 'Lecture analytique', 13.0, 20.0, 2.0, 31, ''],
      ['Histoire-Géographie', 'Contrôle sur le Moyen Âge', 15.5, 20.0, 2.0, 9, ''],
      ['Histoire-Géographie', 'Croquis de géographie', 12.0, 20.0, 1.0, 25, 'Légende à soigner.'],
      ['Anglais', 'Compréhension orale', 17.0, 20.0, 2.0, 7, 'Excellente compréhension.'],
      ['Anglais', 'Vocabulaire de la maison', 19.0, 20.0, 1.0, 22, ''],
      ['SVT', 'Contrôle sur la nutrition', 14.5, 20.0, 2.0, 12, ''],
      ['SVT', 'Compte rendu de travaux pratiques', 16.0, 20.0, 1.0, 28, 'Protocole bien respecté.'],
      ['EPS', 'Évaluation de demi-fond', 15.0, 20.0, 1.0, 14, ''],
      ['EPS', 'Cycle de gymnastique', 13.0, 20.0, 1.0, 30, ''],
    ],
  },
  {
    'prenom': 'Noah',
    'nom': 'Moreau',
    'classe': '3e A',
    'etablissement': 'Collège Jean Moulin',
    'grille': grilleTroisieme,
    'notes': [
      ['Mathématiques', 'Devoir surveillé sur les fonctions', 7.5, 20.0, 3.0, 5, 'Les bases doivent être revues.'],
      ['Mathématiques', 'Interrogation sur Thalès', 9.0, 20.0, 1.0, 19, ''],
      ['Mathématiques', 'Contrôle de calcul littéral', 11.0, 20.0, 2.0, 33, 'Des progrès, continue ainsi.'],
      ['Français', 'Commentaire de texte', 12.5, 20.0, 2.0, 8, ''],
      ['Français', 'Dictée', 6.0, 10.0, 1.0, 21, 'Attention aux accords.'],
      ['Français', 'Exposé sur Victor Hugo', 15.0, 20.0, 2.0, 35, 'Présentation orale convaincante.'],
      ['Histoire-Géographie', 'Contrôle sur la Première Guerre mondiale', 13.5, 20.0, 2.0, 11, ''],
      ['Histoire-Géographie', 'Étude de documents', 10.5, 20.0, 1.0, 26, ''],
      ['Anglais', 'Expression écrite', 14.0, 20.0, 2.0, 6, 'Bonne maîtrise des temps.'],
      ['Anglais', 'Interrogation de grammaire', 11.5, 20.0, 1.0, 23, ''],
      ['SVT', 'Contrôle sur la génétique', 12.0, 20.0, 2.0, 13, ''],
      ['SVT', 'Travaux pratiques sur les enzymes', 15.5, 20.0, 1.0, 29, 'Très bonne autonomie.'],
      ['EPS', 'Évaluation de natation', 16.0, 20.0, 1.0, 16, ''],
      ['EPS', 'Cycle de basket-ball', 14.0, 20.0, 1.0, 32, ''],
    ],
  },
];

/// Écrit les données de démonstration dans Firestore.
///
/// La classe encapsule le service plutôt que d'aller chercher une instance
/// globale : elle reste ainsi testable, et l'écriture passe par la même couche
/// que le reste de l'application.
class PeuplementDeDemonstration {
  final ServiceFirestore _firestore;

  const PeuplementDeDemonstration(this._firestore);

  /// Crée les enfants, leurs notes et leurs emplois du temps.
  ///
  /// Renvoie le nombre de documents écrits, affiché ensuite à l'utilisateur.
  ///
  /// L'enfant est créé en premier car son identifiant est nécessaire pour
  /// rattacher les notes et les cours. Ces derniers partent en revanche
  /// ensemble : rien ne les ordonne, les lancer en parallèle divise l'attente.
  Future<int> executer(String idParent) async {
    int documentsEcrits = 0;

    for (final Map<String, Object> modele in enfantsDeDemonstration) {
      final String idEnfant = await _firestore.ajouterEnfant(
        Enfant.depuisFirestore('', {
          'idParent': idParent,
          'prenom': modele['prenom'],
          'nom': modele['nom'],
          'classe': modele['classe'],
          'etablissement': modele['etablissement'],
        }),
      );
      await _firestore.rattacherEnfant(uid: idParent, idEnfant: idEnfant);
      documentsEcrits++;

      final List<Note> notes = _notesDe(modele, idEnfant);
      final List<Cours> cours = _coursDe(modele, idEnfant);

      await Future.wait([
        ...notes.map(_firestore.ajouterNote),
        ...cours.map(_firestore.ajouterCours),
      ]);
      documentsEcrits += notes.length + cours.length;
    }

    return documentsEcrits;
  }

  /// Convertit les évaluations décrites plus haut en objets [Note].
  ///
  /// Chaque ligne suit l'ordre : matière, intitulé, valeur, barème,
  /// coefficient, ancienneté en jours, appréciation.
  static List<Note> _notesDe(Map<String, Object> modele, String idEnfant) {
    final List<Object> lignes = modele['notes']! as List<Object>;
    final DateTime aujourdHui = DateTime.now();

    return lignes.map((ligne) {
      final List<Object> champs = ligne as List<Object>;
      return Note.depuisFirestore('', {
        'idEnfant': idEnfant,
        'matiere': champs[0],
        'intitule': champs[1],
        'valeur': champs[2],
        'bareme': champs[3],
        'coefficient': champs[4],
        'date': aujourdHui.subtract(Duration(days: champs[5] as int)),
        'appreciation': champs[6],
      });
    }).toList();
  }

  /// Déplie la grille hebdomadaire en objets [Cours].
  ///
  /// Les créneaux vides sont ignorés : ce sont les heures de permanence.
  static List<Cours> _coursDe(Map<String, Object> modele, String idEnfant) {
    final List<Object> grille = modele['grille']! as List<Object>;
    final List<Cours> cours = <Cours>[];

    for (int indexDuJour = 0; indexDuJour < grille.length; indexDuJour++) {
      final List<Object> journee = grille[indexDuJour] as List<Object>;

      for (int creneau = 0; creneau < journee.length; creneau++) {
        final String matiere = journee[creneau] as String;
        if (matiere.isEmpty) {
          continue;
        }

        final List<String> salleEtProfesseur =
            salleEtProfesseurParMatiere[matiere] ?? const ['', ''];
        final String heureDebut = creneauxDeLaJournee[creneau];

        cours.add(
          Cours.depuisFirestore('', {
            'idEnfant': idEnfant,
            'matiere': matiere,
            'jour': indexDuJour + 1,
            'heureDebut': heureDebut,
            'heureFin': heureDeFin(heureDebut),
            'salle': salleEtProfesseur[0],
            'professeur': salleEtProfesseur[1],
          }),
        );
      }
    }

    return cours;
  }
}

/// Calcule l'heure de fin d'un cours à partir de son heure de début.
///
/// Isolée et publique pour être testable : une erreur ici décalerait tout
/// l'emploi du temps sans que rien ne le signale.
String heureDeFin(String heureDebut, {int duree = dureeDUnCours}) {
  final int minutes = Cours.minutesDepuisTexte(heureDebut) + duree;
  final String heures = (minutes ~/ 60).toString().padLeft(2, '0');
  final String reste = (minutes % 60).toString().padLeft(2, '0');
  return '$heures:$reste';
}

/// Encart affiché lorsque le parent n'a encore aucun enfant rattaché.
///
/// Il évite l'écran vide au premier lancement et donne le seul geste utile à ce
/// stade : générer le jeu de données de démonstration.
class EncartBaseVide extends ConsumerStatefulWidget {
  const EncartBaseVide({super.key});

  @override
  ConsumerState<EncartBaseVide> createState() => _EtatEncartBaseVide();
}

class _EtatEncartBaseVide extends ConsumerState<EncartBaseVide> {
  bool _enCours = false;

  Future<void> _peupler() async {
    final String? idParent = ref.read(identifiantParentProvider);
    if (idParent == null) {
      return;
    }

    setState(() => _enCours = true);

    try {
      final int documents = await PeuplementDeDemonstration(
        ref.read(serviceFirestoreProvider),
      ).executer(idParent);

      _signaler('$documents documents ajoutés à la base.');
    } catch (erreur) {
      _signaler('Échec de la génération : $erreur', enEchec: true);
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  /// Affiche le résultat de l'opération.
  ///
  /// Le contexte est vérifié : l'écran peut avoir été quitté pendant que les
  /// quatre-vingts écritures partaient sur le réseau.
  void _signaler(String message, {bool enEchec = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: enEchec
            ? PaletteNature.terracotta
            : PaletteNature.vertProfond,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MesuresNature.margeEcran),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: PaletteNature.vertTendre.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.family_restroom_outlined,
                color: PaletteNature.vertFeuille,
                size: 44,
              ),
            ),
            const SizedBox(height: MesuresNature.espaceBloc),
            Text(
              'Aucun enfant rattaché',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'AZOnline n\'est relié à aucun système scolaire réel. '
              'Générez un jeu de données fictives pour découvrir '
              'l\'application.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PaletteNature.pierre,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _enCours ? null : _peupler,
              icon: _enCours
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(
                _enCours ? 'Génération en cours...' : 'Générer mes données',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '2 enfants, 28 notes et 44 cours seront créés.',
              style: TextStyle(color: PaletteNature.pierre, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
