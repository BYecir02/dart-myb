import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/film.dart';
import '../widgets/badge_info.dart';
import '../widgets/carte_film.dart';

/// Fiche détaillée d'un film.
///
/// Le film est transmis par le constructeur depuis la page précédente
/// (passage de variable classique via MaterialPageRoute).
class PageDetailFilm extends ConsumerStatefulWidget {
  final Film film;

  const PageDetailFilm({super.key, required this.film});

  @override
  ConsumerState<PageDetailFilm> createState() => _PageDetailFilmState();
}

class _PageDetailFilmState extends ConsumerState<PageDetailFilm> {
  bool _enregistrementEnCours = false;

  Future<void> _basculerFavori(bool estDejaFavori) async {
    final utilisateur = ref.read(utilisateurProvider).value;
    if (utilisateur == null) {
      return;
    }

    setState(() => _enregistrementEnCours = true);

    try {
      final service = ref.read(serviceFirestoreProvider);
      if (estDejaFavori) {
        await service.retirerDesFavoris(
          uid: utilisateur.uid,
          idFilm: widget.film.id,
        );
      } else {
        await service.ajouterAuxFavoris(
          uid: utilisateur.uid,
          idFilm: widget.film.id,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estDejaFavori
                ? '« ${widget.film.titre} » retiré de vos favoris.'
                : '« ${widget.film.titre} » ajouté à vos favoris.',
          ),
          backgroundColor:
              estDejaFavori ? Colors.grey.shade800 : Colors.green.shade700,
        ),
      );
    } catch (erreur) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enregistrement impossible : $erreur'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _enregistrementEnCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Film film = widget.film;

    // Lecture temps réel des favoris : le bouton se met à jour tout seul.
    final List<String> favoris = ref.watch(favorisProvider).value ?? <String>[];
    final bool estFavori = favoris.contains(film.id);

    // Les recommandations proviennent du même flux distant que l'accueil.
    final List<Film> tousLesFilms =
        ref.watch(filmsProvider).value ?? <Film>[];
    final List<Film> recommandations =
        tousLesFilms.where((autre) => autre.id != film.id).take(5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF14141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C22),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          film.titre,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _construireAfficheGrandFormat(film),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      film.titre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        BadgeInfo(
                          texte: film.genre,
                          couleur: Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        BadgeInfo(
                          texte: '${film.ageMinimum} ans et +',
                          couleur: Colors.black87,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _construireBoutonFavori(estFavori),
                    const SizedBox(height: 22),
                    const Text(
                      'Synopsis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F28),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E2E3A)),
                      ),
                      child: Text(
                        film.synopsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Recommandations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'La même carte que l\'accueil, ici en pleine largeur.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              // Un film par ligne : la carte détecte la largeur disponible
              // et bascule d'elle-même en présentation étendue.
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    for (final Film recommandation in recommandations)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: CarteFilm(
                          film: recommandation,
                          onVoir: () => _ouvrirAutreFiche(recommandation),
                        ),
                      ),
                    if (recommandations.isEmpty)
                      const Text(
                        'Aucune autre suggestion pour le moment.',
                        style: TextStyle(color: Colors.white38),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _ouvrirAutreFiche(Film film) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PageDetailFilm(film: film)),
    );
  }

  Widget _construireAfficheGrandFormat(Film film) {
    return SizedBox(
      height: 340,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            film.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, enfant, progression) {
              if (progression == null) {
                return enfant;
              }
              return Container(
                color: const Color(0xFF2A2A33),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              );
            },
            errorBuilder: (context, erreur, trace) => Container(
              color: const Color(0xFF2A2A33),
              child: const Center(
                child: Icon(Icons.movie, color: Colors.white24, size: 64),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xFF14141A)],
                stops: [0.55, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireBoutonFavori(bool estFavori) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            _enregistrementEnCours ? null : () => _basculerFavori(estFavori),
        icon: _enregistrementEnCours
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(estFavori ? Icons.favorite : Icons.favorite_border),
        label: Text(
          _enregistrementEnCours
              ? 'Enregistrement...'
              : (estFavori ? 'Retirer de mes favoris' : 'Ajouter à mes favoris'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: estFavori ? Colors.grey.shade800 : Colors.red,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.red.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
