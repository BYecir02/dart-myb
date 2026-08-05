import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/cours.dart';
import '../theme/theme_nature.dart';
import '../widgets/carte_cours.dart';
import '../widgets/message_central.dart';

/// Emploi du temps de la semaine, affiché un jour à la fois.
///
/// Une grille hebdomadaire complète serait illisible sur un téléphone : les
/// cases deviendraient trop petites, ou il faudrait défiler dans les deux
/// directions. Une journée par écran, avec un sélecteur en haut, donne la même
/// information en restant confortable au pouce.
class PageEmploiDuTemps extends ConsumerWidget {
  /// Instant de référence, utilisé pour repérer le cours en train de se
  /// dérouler. Paramétrable afin que les tests ne dépendent pas de l'heure
  /// à laquelle ils tournent.
  final DateTime? maintenant;

  const PageEmploiDuTemps({super.key, this.maintenant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int jour = ref.watch(jourSelectionneProvider);
    final List<Cours> cours = ref.watch(coursDuJourProvider);
    final AsyncValue<List<Cours>> etat = ref.watch(coursProvider);
    final DateTime reference = maintenant ?? DateTime.now();

    return Column(
      children: [
        _selecteurDeJour(ref, jour),
        Expanded(
          child: RefreshIndicator(
            // Même geste que sur le tableau de bord : relancer la lecture
            // depuis Firestore. Le flux se rétablit seul en temps normal, ce
            // geste sert surtout au retour de connexion.
            onRefresh: () async => ref.invalidate(coursProvider),
            child: etat.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (erreur, trace) => _defilable(
                MessageCentral.erreur(
                  erreur,
                  titre: 'Impossible de lire l\'emploi du temps',
                ),
              ),
              data: (_) => _journee(context, cours, reference),
            ),
          ),
        ),
      ],
    );
  }

  /// Rend un contenu fixe défilable.
  ///
  /// Le geste de rafraîchissement exige un descendant qui défile. Sans cette
  /// enveloppe, tirer sur un message d'erreur ou sur une journée vide ne
  /// déclencherait rien.
  Widget _defilable(Widget contenu) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: contraintes.maxHeight),
            child: contenu,
          ),
        );
      },
    );
  }

  /// Barre des cinq jours ouvrés.
  ///
  /// Les initiales suffisent : elles tiennent sur une ligne sans défilement,
  /// là où les noms complets obligeraient à faire glisser la barre.
  Widget _selecteurDeJour(WidgetRef ref, int jourActif) {
    return Container(
      color: PaletteNature.blancCasse,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: List.generate(Cours.joursDeLaSemaine.length, (index) {
          final int jour = index + 1;
          final bool estActif = jour == jourActif;
          final String nom = Cours.joursDeLaSemaine[index];

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  MesuresNature.rayonBouton,
                ),
                onTap: () =>
                    ref.read(jourSelectionneProvider.notifier).choisir(jour),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: estActif
                        ? PaletteNature.vertFeuille
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      MesuresNature.rayonBouton,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        // Deux lettres distinguent mardi de mercredi, que la
                        // seule initiale confondrait.
                        nom.substring(0, 2),
                        style: TextStyle(
                          color: estActif
                              ? Colors.white
                              : PaletteNature.vertProfond,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Les créneaux du jour sélectionné.
  Widget _journee(
    BuildContext context,
    List<Cours> cours,
    DateTime reference,
  ) {
    if (cours.isEmpty) {
      return _defilable(
        const MessageCentral(
          icone: Icons.free_breakfast_outlined,
          titre: 'Aucun cours ce jour',
          message: 'Journée libre, ou emploi du temps non renseigné.',
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(MesuresNature.margeEcran),
      itemCount: cours.length,
      itemBuilder: (context, index) {
        final Cours creneau = cours[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CarteCours(
            cours: creneau,
            // La mise en évidence n'a lieu que si le jour affiché est bien
            // aujourd'hui : consulter le vendredi un mardi ne doit rien
            // allumer.
            estEnCours: creneau.estEnCours(reference),
          ),
        );
      },
    );
  }

}
