import 'package:flutter/material.dart';

import '../theme/theme_nature.dart';

/// Écran affiché tant que le projet n'est pas rattaché à Firebase.
///
/// Il évite l'écran noir déroutant au premier lancement : plutôt que de planter
/// sur une clé manquante, l'application explique ce qu'il reste à faire.
/// Une fois `flutterfire configure` exécuté, cet écran n'apparaît plus.
class PageConfigurationRequise extends StatelessWidget {
  /// Message technique remonté par l'initialisation de Firebase.
  final String message;

  const PageConfigurationRequise({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MesuresNature.margeEcran),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              _enTete(),
              const SizedBox(height: MesuresNature.espaceBloc),
              Text(message, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: MesuresNature.espaceBloc),
              _etapes(),
              const SizedBox(height: MesuresNature.espaceBloc),
              _renvoiDocumentation(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Titre de l'écran, accompagné du logo provisoire de l'application.
  Widget _enTete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PaletteNature.vertTendre.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(MesuresNature.rayonCarte),
          ),
          child: const Icon(
            Icons.eco_outlined,
            color: PaletteNature.vertFeuille,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Configuration Firebase requise',
          style: TextStyle(
            color: PaletteNature.vertProfond,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'AZOnline a besoin d\'un projet Firebase pour stocker les comptes, '
          'les notes et les emplois du temps.',
          style: TextStyle(color: PaletteNature.pierre, fontSize: 13),
        ),
      ],
    );
  }

  /// La marche à suivre, à réaliser une seule fois.
  Widget _etapes() {
    const List<String> etapes = [
      'Créer un projet sur console.firebase.google.com',
      'Activer Authentication, puis le fournisseur Email et mot de passe',
      'Créer la base Cloud Firestore',
      'Lancer la commande flutterfire configure',
      'Relancer l\'application',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MesuresNature.margeEcran),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'À faire une seule fois',
              style: TextStyle(
                color: PaletteNature.vertProfond,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            // `asMap` fournit l'index, qui sert à numéroter les pastilles.
            ...etapes.asMap().entries.map((entree) {
              return _ligneEtape(numero: entree.key + 1, libelle: entree.value);
            }),
          ],
        ),
      ),
    );
  }

  /// Une étape numérotée dans une pastille verte.
  Widget _ligneEtape({required int numero, required String libelle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: PaletteNature.vertFeuille,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$numero',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                libelle,
                style: const TextStyle(
                  color: PaletteNature.vertProfond,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renvoi vers la documentation du dépôt.
  Widget _renvoiDocumentation(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.menu_book_outlined,
          color: PaletteNature.ecorce,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Le détail pas à pas se trouve dans le fichier README.md, '
            'à la racine du projet.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
