import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/film.dart';

/// OUTIL DE MISE EN ROUTE - à utiliser une seule fois.
///
/// L'application n'affiche jamais ces films directement : ils servent
/// uniquement à remplir la collection Firestore `films` au premier lancement,
/// pour éviter d'avoir à saisir huit documents à la main dans la console.
/// Une fois la base peuplée, ce fichier peut être supprimé.
const List<Map<String, dynamic>> catalogueInitial = [
  {
    'titre': 'Inception',
    'genre': 'Science-Fiction',
    'ageMinimum': 12,
    'synopsis':
        "Dom Cobb est un voleur expérimenté dans l'art périlleux de l'extraction : "
            "il s'approprie les secrets enfouis au plus profond du subconscient pendant "
            "le sommeil. On lui propose cette fois d'accomplir l'inverse : implanter une idée.",
    'imageUrl': 'https://picsum.photos/seed/inception/500/750',
  },
  {
    'titre': 'Interstellar',
    'genre': 'Science-Fiction',
    'ageMinimum': 10,
    'synopsis':
        "La Terre se meurt. Un groupe d'explorateurs franchit un trou de ver "
            "apparu près de Saturne pour partir à la recherche d'un nouveau monde habitable.",
    'imageUrl': 'https://picsum.photos/seed/interstellar/500/750',
  },
  {
    'titre': 'Le Parrain',
    'genre': 'Drame',
    'ageMinimum': 16,
    'synopsis':
        "New York, 1945. Don Vito Corleone règne sur l'une des cinq familles de la mafia. "
            "Son plus jeune fils, revenu de la guerre, se tient à l'écart des affaires... jusqu'au jour où tout bascule.",
    'imageUrl': 'https://picsum.photos/seed/parrain/500/750',
  },
  {
    'titre': 'Parasite',
    'genre': 'Thriller',
    'ageMinimum': 16,
    'synopsis':
        "Toute la famille Ki-taek est au chômage. Le fils aîné décroche un poste de "
            "professeur particulier chez les Park, une famille fortunée. Un engrenage se met en marche.",
    'imageUrl': 'https://picsum.photos/seed/parasite/500/750',
  },
  {
    'titre': 'Le Voyage de Chihiro',
    'genre': 'Animation',
    'ageMinimum': 6,
    'synopsis':
        "En route vers sa nouvelle maison, Chihiro se retrouve piégée dans un monde "
            "peuplé d'esprits. Pour sauver ses parents transformés en cochons, elle devra travailler aux bains.",
    'imageUrl': 'https://picsum.photos/seed/chihiro/500/750',
  },
  {
    'titre': 'Matrix',
    'genre': 'Science-Fiction',
    'ageMinimum': 12,
    'synopsis':
        "Programmeur le jour, hacker la nuit, Thomas Anderson découvre que le monde "
            "qu'il croyait réel n'est qu'une simulation créée par les machines.",
    'imageUrl': 'https://picsum.photos/seed/matrix/500/750',
  },
  {
    'titre': 'Pulp Fiction',
    'genre': 'Policier',
    'ageMinimum': 18,
    'synopsis':
        "Les destins entremêlés de deux tueurs à gages, d'un boxeur, d'un gangster "
            "et de sa femme, racontés dans le désordre le plus savamment orchestré.",
    'imageUrl': 'https://picsum.photos/seed/pulpfiction/500/750',
  },
  {
    'titre': 'Le Roi Lion',
    'genre': 'Animation',
    'ageMinimum': 3,
    'synopsis':
        "Simba, jeune lionceau, est promis au trône de la Terre des Lions. "
            "Après la mort de son père, il fuit le royaume, rongé par la culpabilité.",
    'imageUrl': 'https://picsum.photos/seed/roilion/500/750',
  },
];

/// Encart affiché lorsque la collection `films` est encore vide.
class EncartCatalogueVide extends ConsumerStatefulWidget {
  const EncartCatalogueVide({super.key});

  @override
  ConsumerState<EncartCatalogueVide> createState() =>
      _EncartCatalogueVideState();
}

class _EncartCatalogueVideState extends ConsumerState<EncartCatalogueVide> {
  bool _enCours = false;

  Future<void> _peupler() async {
    setState(() => _enCours = true);

    try {
      final service = ref.read(serviceFirestoreProvider);
      for (final donnees in catalogueInitial) {
        await service.ajouterFilm(Film.depuisFirestore('', donnees));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${catalogueInitial.length} films ajoutés à la base.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (erreur) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de l\'ajout : $erreur'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_creation_outlined,
                color: Colors.white24, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Le catalogue est vide',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Aucun document dans la collection « films » de Firestore.\n"
              "Ce bouton en ajoute huit pour démarrer.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _enCours ? null : _peupler,
              icon: _enCours
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_enCours ? 'Envoi en cours...' : 'Peupler la base'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
