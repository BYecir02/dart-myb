import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/enfant.dart';
import '../modeles/moyenne_matiere.dart';
import '../modeles/note.dart';
import '../outils/formats.dart';
import '../theme/theme_nature.dart';
import '../widgets/carte_matiere.dart';
import '../widgets/carte_note.dart';
import '../widgets/jauge_moyenne.dart';

/// Écran d'accueil : la synthèse des résultats de l'enfant sélectionné.
///
/// Trois blocs, du plus général au plus détaillé : la moyenne générale, les
/// moyennes par matière, puis les dernières évaluations. Le parent qui ouvre
/// l'application pour dix secondes a sa réponse dès le premier écran, sans
/// avoir à naviguer.
///
/// Cette page ne connaît ni Firestore ni SharedPreferences : elle lit des
/// providers et affiche des objets Dart.
class PageTableauDeBord extends ConsumerWidget {
  /// Ouvre le détail d'une matière.
  ///
  /// Fourni par la page qui héberge le tableau de bord. Laissé à `null`, les
  /// cartes de matière ne sont pas cliquables, ce qui permet de monter cet
  /// écran seul dans un test sans avoir à fournir un Navigator.
  final void Function(BuildContext context, String matiere)? surMatiereChoisie;

  const PageTableauDeBord({super.key, this.surMatiereChoisie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Enfant? enfant = ref.watch(enfantSelectionneProvider);
    final List<MoyenneMatiere> moyennes = ref.watch(moyennesProvider);
    final double? moyenneGenerale = ref.watch(moyenneGeneraleProvider);
    final List<Note> dernieres = ref.watch(dernieresNotesProvider);
    final DateTime? synchro = ref.watch(dateDerniereSynchroProvider);

    return RefreshIndicator(
      // Relance la lecture des notes. Le flux Firestore se rétablit seul en
      // temps normal ; ce geste sert surtout au retour de connexion.
      onRefresh: () async => ref.invalidate(fluxDesNotesProvider),
      child: ListView(
        // AlwaysScrollable garde le geste de rafraîchissement actif même quand
        // le contenu tient dans l'écran.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(MesuresNature.margeEcran),
        children: [
          _blocMoyenneGenerale(moyenneGenerale, moyennes.length),
          const SizedBox(height: MesuresNature.espaceBloc),

          if (moyennes.isEmpty)
            _aucuneNote(context, enfant)
          else ...[
            _titre('Moyennes par matière'),
            const SizedBox(height: 10),
            ...moyennes.map(
              (moyenne) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CarteMatiere(
                  moyenne: moyenne,
                  onTap: surMatiereChoisie == null
                      ? null
                      : () => surMatiereChoisie!(context, moyenne.matiere),
                ),
              ),
            ),
            const SizedBox(height: MesuresNature.espaceBloc),
            _titre('Dernières notes'),
            const SizedBox(height: 10),
            ...dernieres.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CarteNote(note: note),
              ),
            ),
          ],

          const SizedBox(height: 12),
          _pied(synchro),
        ],
      ),
    );
  }

  /// Carte d'en-tête portant la jauge de moyenne générale.
  Widget _blocMoyenneGenerale(double? moyenne, int nombreDeMatieres) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            JaugeMoyenne(moyenne: moyenne),
            if (nombreDeMatieres > 0) ...[
              const SizedBox(height: 14),
              Text(
                'sur $nombreDeMatieres matière${nombreDeMatieres > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: PaletteNature.pierre,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Intertitre de section.
  Widget _titre(String libelle) {
    return Text(
      libelle,
      style: const TextStyle(
        color: PaletteNature.vertProfond,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Message affiché lorsque l'enfant existe mais n'a encore aucune note.
  Widget _aucuneNote(BuildContext context, Enfant? enfant) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 44,
              color: PaletteNature.pierre,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune note pour le moment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              enfant == null
                  ? 'Sélectionnez un enfant pour voir ses résultats.'
                  : 'Les évaluations de ${enfant.prenom} apparaîtront ici '
                        'dès qu\'elles seront saisies.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PaletteNature.pierre,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fraîcheur des données affichées.
  ///
  /// Sans cette mention, le parent consultant hors connexion ne pourrait pas
  /// savoir qu'il regarde des notes mises en cache la veille.
  Widget _pied(DateTime? synchro) {
    if (synchro == null) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.sync, size: 13, color: PaletteNature.pierre),
        const SizedBox(width: 6),
        Text(
          'Mis à jour ${depuisQuand(synchro)}',
          style: const TextStyle(color: PaletteNature.pierre, fontSize: 11),
        ),
      ],
    );
  }
}
