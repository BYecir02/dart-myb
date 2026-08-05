import 'package:flutter/material.dart';

import '../modeles/note.dart';
import '../outils/formats.dart';
import '../theme/theme_nature.dart';

/// Ligne présentant une évaluation.
///
/// La note occupe une pastille colorée à gauche, à taille fixe : les pastilles
/// s'alignent verticalement d'une ligne à l'autre, ce qui rend la colonne des
/// résultats lisible en diagonale.
class CarteNote extends StatelessWidget {
  final Note note;

  /// Affiche le nom de la matière sous l'intitulé.
  ///
  /// Utile sur le tableau de bord, où les notes de toutes les matières sont
  /// mélangées. Inutile sur l'écran d'une matière donnée, où l'information
  /// serait répétée à chaque ligne.
  final bool avecMatiere;

  const CarteNote({super.key, required this.note, this.avecMatiere = true});

  @override
  Widget build(BuildContext context) {
    final Color couleur = couleurSelonNote(note.valeur, bareme: note.bareme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pastille(couleur),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.intitule,
                    style: const TextStyle(
                      color: PaletteNature.vertProfond,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _sousTitre(),
                    style: const TextStyle(
                      color: PaletteNature.pierre,
                      fontSize: 12,
                    ),
                  ),
                  if (note.possedeUneAppreciation) ...[
                    const SizedBox(height: 8),
                    _appreciation(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pastille portant la note, sur fond teinté de la couleur du résultat.
  Widget _pastille(Color couleur) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MesuresNature.rayonBouton),
        border: Border.all(color: couleur.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            note.affichage.split(' / ').first,
            style: TextStyle(
              color: couleur,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          Text(
            '/ ${note.affichage.split(' / ').last}',
            style: TextStyle(
              color: couleur.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Matière, coefficient et date, séparés par des points médians.
  ///
  /// La date peut manquer sur un document incomplet : elle est simplement
  /// omise, sans laisser de séparateur orphelin.
  String _sousTitre() {
    final List<String> morceaux = [
      if (avecMatiere) note.matiere,
      note.affichageCoefficient,
      if (note.date != null) dateCourte(note.date!),
    ];
    return morceaux.join('  ·  ');
  }

  /// Commentaire du professeur, sur fond de papier.
  Widget _appreciation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: PaletteNature.sable,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote,
            size: 14,
            color: PaletteNature.ecorce,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              note.appreciation,
              style: const TextStyle(
                color: PaletteNature.ecorce,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
