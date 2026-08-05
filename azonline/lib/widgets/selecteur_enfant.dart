import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/enfant.dart';
import '../theme/theme_nature.dart';

/// Sélecteur d'enfant, affiché dans la barre supérieure.
///
/// Il remplace le titre de l'application plutôt que d'occuper une page à lui
/// seul : l'enfant consulté est le contexte de tous les écrans, il doit rester
/// visible en permanence et changeable en deux gestes.
///
/// Le composant s'adapte au nombre d'enfants :
///
/// - aucun enfant, il affiche simplement le nom de l'application ;
/// - un seul enfant, il affiche son nom sans menu, puisqu'il n'y a rien à
///   choisir ;
/// - plusieurs enfants, il ouvre un menu de sélection.
class SelecteurEnfant extends ConsumerWidget {
  const SelecteurEnfant({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Enfant> enfants = ref.watch(enfantsProvider).value ?? const [];
    final Enfant? actif = ref.watch(enfantSelectionneProvider);

    if (enfants.isEmpty || actif == null) {
      return const Text('AZOnline');
    }

    if (enfants.length == 1) {
      return _Etiquette(enfant: actif, avecFleche: false);
    }

    return PopupMenuButton<String>(
      // Le menu s'ouvre sous la barre plutôt que par-dessus le nom.
      offset: const Offset(0, 48),
      tooltip: 'Changer d\'enfant',
      position: PopupMenuPosition.under,
      onSelected: (identifiant) {
        ref.read(selectionEnfantProvider.notifier).choisir(identifiant);
      },
      itemBuilder: (context) => enfants.map((enfant) {
        return PopupMenuItem<String>(
          value: enfant.id,
          child: _LigneDeMenu(enfant: enfant, estActif: enfant.id == actif.id),
        );
      }).toList(),
      child: _Etiquette(enfant: actif, avecFleche: true),
    );
  }
}

/// Nom de l'enfant affiché dans la barre supérieure.
class _Etiquette extends StatelessWidget {
  final Enfant enfant;

  /// La flèche n'apparaît que lorsqu'un choix est réellement possible.
  final bool avecFleche;

  const _Etiquette({required this.enfant, required this.avecFleche});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: Colors.white.withValues(alpha: 0.22),
          child: Text(
            enfant.initiales,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Flexible évite le débordement lorsqu'un nom est long et que la barre
        // porte déjà le bouton de déconnexion.
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enfant.nomComplet,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                enfant.classe,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        if (avecFleche)
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Icon(Icons.arrow_drop_down, color: Colors.white),
          ),
      ],
    );
  }
}

/// Une entrée du menu de sélection.
class _LigneDeMenu extends StatelessWidget {
  final Enfant enfant;
  final bool estActif;

  const _LigneDeMenu({required this.enfant, required this.estActif});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: estActif
              ? PaletteNature.vertFeuille
              : PaletteNature.vertTendre.withValues(alpha: 0.30),
          child: Text(
            enfant.initiales,
            style: TextStyle(
              color: estActif ? Colors.white : PaletteNature.vertProfond,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enfant.nomComplet,
                style: TextStyle(
                  color: PaletteNature.vertProfond,
                  fontSize: 14,
                  fontWeight: estActif ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                enfant.description,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PaletteNature.pierre,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (estActif)
          const Icon(Icons.check, color: PaletteNature.vertFeuille, size: 18),
      ],
    );
  }
}
