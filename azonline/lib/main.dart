import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/page_configuration_requise.dart';
import 'theme/theme_nature.dart';

/// Point d'entrée de AZOnline.
///
/// L'initialisation de Firebase et le portail d'authentification sont ajoutés
/// à l'étape suivante (F2). Pour l'instant, l'application démarre sur l'écran
/// qui explique comment rattacher le projet à Firebase.
void main() {
  runApp(
    // ProviderScope conserve l'état global de l'application. Il enveloppe
    // l'arbre entier dès le démarrage, sans quoi aucun provider ne serait
    // accessible depuis les pages.
    const ProviderScope(child: ApplicationAZOnline()),
  );
}

/// Racine de l'application : thème, titre et premier écran.
class ApplicationAZOnline extends StatelessWidget {
  const ApplicationAZOnline({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AZOnline',
      debugShowCheckedModeBanner: false,
      theme: ThemeNature.construire(),

      // L'application est pensée pour le mobile. Sur un navigateur large, on la
      // maintient dans un cadre étroit : sans cette contrainte, les listes de
      // notes s'étireraient sur toute la largeur et deviendraient illisibles.
      builder: (context, enfant) {
        return ColoredBox(
          color: PaletteNature.sable,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: MesuresNature.largeurMaximale,
              ),
              child: enfant ?? const SizedBox.shrink(),
            ),
          ),
        );
      },

      home: const PageConfigurationRequise(
        message: 'Firebase n\'est pas encore rattaché au projet.',
      ),
    );
  }
}
