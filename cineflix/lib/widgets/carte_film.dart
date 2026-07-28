import 'package:flutter/material.dart';

import '../modeles/film.dart';
import 'badge_info.dart';

/// Carte "intelligente" présentant un film.
///
/// C'est le même composant qui est utilisé :
///   - dans la grille de l'accueil (3 films par ligne)  -> peu de largeur
///   - dans le flux de recommandations (1 film par ligne) -> pleine largeur
///
/// Le widget LayoutBuilder mesure la place réellement disponible et choisit
/// la mise en page adaptée. Aucun paramètre à passer : la carte se débrouille.
class CarteFilm extends StatelessWidget {
  /// En dessous de cette largeur, la carte bascule en présentation compacte.
  static const double seuilLargeur = 260;

  final Film film;
  final VoidCallback onVoir;

  const CarteFilm({super.key, required this.film, required this.onVoir});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        final bool pleineLargeur = contraintes.maxWidth >= seuilLargeur;
        return pleineLargeur ? _construirePleineLargeur() : _construireCompacte();
      },
    );
  }

  // ---------------------------------------------------------------------
  // Présentation compacte : utilisée dans la grille de l'accueil.
  // ---------------------------------------------------------------------
  Widget _construireCompacte() {
    return Container(
      decoration: _decorationCarte(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // L'affiche du film en fond.
          _construireAffiche(),
          // Voile sombre pour garder le texte lisible.
          _construireVoile(),
          // Les deux badges d'information, dans les angles.
          Positioned(
            top: 8,
            left: 8,
            child: BadgeInfo(
              texte: film.genre,
              couleur: Colors.redAccent,
              compact: true,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: BadgeInfo(
              texte: '${film.ageMinimum}+',
              couleur: Colors.black87,
              compact: true,
            ),
          ),
          // Titre et bouton "Voir".
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  film.titre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: onVoir,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(0, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Voir', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Présentation pleine largeur : utilisée dans le flux de recommandations
  // et dans la liste des favoris.
  // ---------------------------------------------------------------------
  Widget _construirePleineLargeur() {
    return Container(
      height: 190,
      decoration: _decorationCarte(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _construireAffiche(),
          _construireVoile(),
          Positioned(
            top: 12,
            left: 12,
            child: BadgeInfo(texte: film.genre, couleur: Colors.redAccent),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: BadgeInfo(
              texte: '${film.ageMinimum} ans et +',
              couleur: Colors.black87,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Row(
              children: [
                // Expanded force le texte à occuper l'espace restant
                // au lieu de déborder sur le bouton.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        film.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        film.synopsis,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onVoir,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Voir',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Éléments communs aux deux présentations.
  // ---------------------------------------------------------------------

  BoxDecoration _decorationCarte() {
    return BoxDecoration(
      color: const Color(0xFF1C1C22),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
      ],
    );
  }

  Widget _construireAffiche() {
    return Image.network(
      film.imageUrl,
      fit: BoxFit.cover,
      // État de chargement pendant que l'image arrive du réseau.
      loadingBuilder: (context, enfant, progression) {
        if (progression == null) {
          return enfant;
        }
        return Container(
          color: const Color(0xFF2A2A33),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, erreur, trace) {
        return Container(
          color: const Color(0xFF2A2A33),
          child: const Center(
            child: Icon(Icons.movie, color: Colors.white24, size: 40),
          ),
        );
      },
    );
  }

  Widget _construireVoile() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black26, Colors.black87],
          stops: [0.35, 1.0],
        ),
      ),
    );
  }
}
