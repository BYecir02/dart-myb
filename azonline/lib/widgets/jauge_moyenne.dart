import 'package:flutter/material.dart';

import '../theme/theme_nature.dart';

/// Jauge circulaire affichant la moyenne générale.
///
/// L'anneau se remplit proportionnellement à la note sur 20 et prend la couleur
/// correspondante. Le parent situe donc le niveau de son enfant d'un coup
/// d'œil, avant même d'avoir lu le chiffre.
///
/// Une moyenne absente affiche un tiret plutôt qu'un zéro : les deux
/// situations sont différentes, et un zéro laisserait croire à un échec.
class JaugeMoyenne extends StatelessWidget {
  /// Moyenne sur 20, ou `null` si aucune note n'est disponible.
  final double? moyenne;

  /// Texte affiché sous le chiffre.
  final String legende;

  /// Diamètre de la jauge.
  final double taille;

  const JaugeMoyenne({
    super.key,
    required this.moyenne,
    this.legende = 'Moyenne générale',
    this.taille = 150,
  });

  @override
  Widget build(BuildContext context) {
    final double? valeur = moyenne;
    final Color couleur = valeur == null
        ? PaletteNature.pierre
        : couleurSelonNote(valeur);

    return SizedBox(
      width: taille,
      height: taille,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anneau de fond, toujours complet, qui matérialise le maximum.
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 12,
              color: PaletteNature.pierre.withValues(alpha: 0.15),
            ),
          ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              // La division par 20 ramène la note en proportion de l'anneau.
              value: valeur == null ? 0 : (valeur / 20).clamp(0.0, 1.0),
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              color: couleur,
            ),
          ),
          // Le contenu est maintenu à l'intérieur de l'anneau. La marge réserve
          // la place de l'épaisseur du trait, et FittedBox réduit le texte
          // plutôt que de le laisser déborder si la police rendue est plus
          // large que prévu.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: taille * 0.16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        valeur == null ? '--' : valeur.toStringAsFixed(1),
                        style: TextStyle(
                          color: couleur,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Text(
                        ' / 20',
                        style: TextStyle(
                          color: couleur.withValues(alpha: 0.70),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  legende,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PaletteNature.pierre,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
