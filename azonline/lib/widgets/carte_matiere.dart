import 'package:flutter/material.dart';

import '../modeles/moyenne_matiere.dart';
import '../theme/theme_nature.dart';

/// Ligne présentant la moyenne d'une matière.
///
/// Le bandeau coloré à gauche reprend la couleur de la moyenne : en parcourant
/// la liste, le parent repère les matières en difficulté sans lire un seul
/// chiffre.
class CarteMatiere extends StatelessWidget {
  final MoyenneMatiere moyenne;

  /// Action déclenchée au toucher, typiquement l'ouverture du détail.
  final VoidCallback? onTap;

  const CarteMatiere({super.key, required this.moyenne, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color couleur = couleurSelonNote(moyenne.valeur);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Bandeau vertical coloré, repère visuel principal de la ligne.
              Container(width: 5, color: couleur),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moyenne.matiere,
                              style: const TextStyle(
                                color: PaletteNature.vertProfond,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              moyenne.affichageNombreDeNotes,
                              style: const TextStyle(
                                color: PaletteNature.pierre,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            moyenne.affichage,
                            style: TextStyle(
                              color: couleur,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / 20',
                            style: TextStyle(
                              color: couleur.withValues(alpha: 0.70),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (onTap != null)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.chevron_right,
                            color: PaletteNature.pierre,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
