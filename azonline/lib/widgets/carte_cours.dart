import 'package:flutter/material.dart';

import '../modeles/cours.dart';
import '../theme/theme_nature.dart';

/// Ligne présentant un créneau de l'emploi du temps.
///
/// L'horaire occupe une colonne fixe à gauche : les heures s'alignent d'une
/// ligne à l'autre, et la journée se lit comme une frise verticale.
///
/// Le cours en cours est mis en avant par un fond teinté et une pastille : le
/// parent qui ouvre l'application à midi voit immédiatement où se trouve son
/// enfant.
class CarteCours extends StatelessWidget {
  final Cours cours;

  /// Met le créneau en évidence lorsqu'il a lieu maintenant.
  final bool estEnCours;

  const CarteCours({super.key, required this.cours, this.estEnCours = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: estEnCours
          ? PaletteNature.vertTendre.withValues(alpha: 0.14)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MesuresNature.rayonCarte),
        side: BorderSide(
          color: estEnCours
              ? PaletteNature.vertFeuille
              : PaletteNature.pierre.withValues(alpha: 0.20),
          width: estEnCours ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _horaire(),
            const SizedBox(width: 12),
            // Trait vertical séparant l'horaire du contenu du cours.
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: estEnCours
                    ? PaletteNature.vertFeuille
                    : PaletteNature.ciel,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _contenu()),
          ],
        ),
      ),
    );
  }

  /// Heures de début et de fin, empilées.
  Widget _horaire() {
    return SizedBox(
      width: 46,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cours.heureDebut,
            style: const TextStyle(
              color: PaletteNature.vertProfond,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cours.heureFin,
            style: const TextStyle(
              color: PaletteNature.pierre,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Matière, salle et professeur.
  Widget _contenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                cours.matiere,
                style: const TextStyle(
                  color: PaletteNature.vertProfond,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (estEnCours) _pastilleEnCours(),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (cours.salle.isNotEmpty) ...[
              const Icon(
                Icons.meeting_room_outlined,
                size: 13,
                color: PaletteNature.pierre,
              ),
              const SizedBox(width: 4),
              Text(
                cours.salle,
                style: const TextStyle(
                  color: PaletteNature.pierre,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (cours.professeur.isNotEmpty)
              Flexible(
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 13,
                      color: PaletteNature.pierre,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        cours.professeur,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PaletteNature.pierre,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Pastille signalant le créneau en train de se dérouler.
  Widget _pastilleEnCours() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PaletteNature.vertFeuille,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'en cours',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
