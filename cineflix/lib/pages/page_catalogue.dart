import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/film.dart';
import '../outils/peupler_base.dart';
import '../widgets/carte_film.dart';
import 'page_detail_film.dart';

/// Accueil : le catalogue, affiché 3 films par ligne.
///
/// Aucun film n'est écrit en dur ici. Tout provient du flux temps réel
/// `filmsProvider`, branché sur la collection Firestore `films`.
class PageCatalogue extends ConsumerWidget {
  const PageCatalogue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatFilms = ref.watch(filmsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF14141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C22),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.movie_filter, color: Colors.red),
            const SizedBox(width: 8),
            const Text(
              'CinéFlix',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: etatFilms.when(
          // État de chargement pendant la récupération distante.
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Chargement du catalogue...',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          error: (erreur, trace) => _construireErreur(erreur),
          data: (films) {
            if (films.isEmpty) {
              return const EncartCatalogueVide();
            }
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                // Trois films par ligne, comme demandé.
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.52,
              ),
              itemCount: films.length,
              itemBuilder: (context, index) {
                final Film film = films[index];
                return CarteFilm(
                  film: film,
                  onVoir: () => _ouvrirFiche(context, film),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _ouvrirFiche(BuildContext context, Film film) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PageDetailFilm(film: film)),
    );
  }

  Widget _construireErreur(Object erreur) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger le catalogue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$erreur',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
