import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/enfant.dart';
import '../modeles/moyenne_matiere.dart';
import '../modeles/note.dart';
import '../theme/theme_nature.dart';
import '../widgets/carte_note.dart';
import '../widgets/jauge_moyenne.dart';
import '../widgets/message_central.dart';

/// Détail d'une matière : toutes les évaluations et la moyenne associée.
///
/// La page reçoit un simple nom de matière plutôt qu'une liste de notes. Elle
/// reste ainsi branchée sur les providers : si une note est ajoutée en base
/// pendant la consultation, l'écran se met à jour tout seul.
///
/// Aucune requête supplémentaire n'est déclenchée : les notes de l'enfant sont
/// déjà chargées, `notesDeLaMatiereProvider` se contente de les filtrer.
class PageDetailMatiere extends ConsumerWidget {
  final String matiere;

  const PageDetailMatiere({super.key, required this.matiere});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Note> notes = ref.watch(notesDeLaMatiereProvider(matiere));
    final Enfant? enfant = ref.watch(enfantSelectionneProvider);
    final MoyenneMatiere moyenne = MoyenneMatiere.depuisNotes(matiere, notes);

    return Scaffold(
      appBar: AppBar(title: Text(matiere)),
      body: notes.isEmpty
          ? _aucuneNote(context)
          : ListView(
              padding: const EdgeInsets.all(MesuresNature.margeEcran),
              children: [
                _entete(moyenne, enfant),
                const SizedBox(height: MesuresNature.espaceBloc),
                Text(
                  'Toutes les évaluations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                // La matière est masquée sur chaque ligne : elle est déjà dans
                // le titre de la page, la répéter n'apprendrait rien.
                ...notes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CarteNote(note: note, avecMatiere: false),
                  ),
                ),
              ],
            ),
    );
  }

  /// Carte de synthèse : moyenne de la matière et volume d'évaluations.
  Widget _entete(MoyenneMatiere moyenne, Enfant? enfant) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            JaugeMoyenne(
              moyenne: moyenne.valeur,
              legende: 'Moyenne',
              taille: 118,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matiere,
                    style: const TextStyle(
                      color: PaletteNature.vertProfond,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    moyenne.affichageNombreDeNotes,
                    style: const TextStyle(
                      color: PaletteNature.pierre,
                      fontSize: 13,
                    ),
                  ),
                  if (enfant != null) ...[
                    const SizedBox(height: 10),
                    _etiquetteEnfant(enfant),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rappel de l'enfant concerné.
  ///
  /// La page étant ouverte par-dessus le tableau de bord, la barre supérieure
  /// affiche le nom de la matière et non plus le sélecteur d'enfant. Ce rappel
  /// évite toute ambiguïté chez un parent qui suit deux enfants.
  Widget _etiquetteEnfant(Enfant enfant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PaletteNature.vertTendre.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_outline,
            size: 13,
            color: PaletteNature.vertFeuille,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              enfant.prenom,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PaletteNature.vertProfond,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiché si la matière n'a plus aucune note.
  ///
  /// Peu probable en pratique, puisqu'on arrive ici depuis une moyenne qui
  /// existe, mais possible si la dernière note est supprimée pendant la
  /// consultation.
  Widget _aucuneNote(BuildContext context) {
    return MessageCentral(
      icone: Icons.assignment_outlined,
      titre: 'Aucune note en $matiere',
    );
  }
}
