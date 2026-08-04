import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'pages/page_configuration_requise.dart';
import 'theme/theme_nature.dart';

/// Point d'entrée de AZOnline.
///
/// La fonction est asynchrone car Firebase doit terminer son initialisation
/// avant que le premier widget ne soit dessiné : les services d'authentification
/// et de base de données ne répondent pas tant que cette étape n'est pas passée.
Future<void> main() async {
  // Obligatoire avant tout appel natif : Firebase dialogue avec la couche
  // Android ou navigateur avant que Flutter ne construise son interface.
  WidgetsFlutterBinding.ensureInitialized();

  // L'échec de l'initialisation n'est pas traité comme un plantage. On le
  // conserve dans une variable pour afficher un écran explicatif, plutôt que
  // de laisser l'utilisateur devant une application morte.
  String? messageDemarrage;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (erreur) {
    messageDemarrage = 'Initialisation de Firebase impossible : $erreur';
  }

  runApp(
    // ProviderScope conserve l'état global de l'application. Il enveloppe
    // l'arbre entier dès le démarrage, sans quoi aucun provider ne serait
    // accessible depuis les pages.
    ProviderScope(child: ApplicationAZOnline(messageDemarrage: messageDemarrage)),
  );
}

/// Racine de l'application : thème, titre et premier écran.
class ApplicationAZOnline extends StatelessWidget {
  /// Renseigné uniquement si Firebase n'a pas pu démarrer.
  /// Vaut `null` lorsque tout s'est bien passé.
  final String? messageDemarrage;

  const ApplicationAZOnline({super.key, this.messageDemarrage});

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

      home: messageDemarrage == null
          ? const PageSocleProvisoire()
          : PageConfigurationRequise(message: messageDemarrage!),
    );
  }
}

/// Écran provisoire affiché lorsque Firebase répond correctement.
///
/// Il n'a qu'un rôle de vérification : confirmer que le socle technique tient
/// debout avant que les vraies pages n'existent. Il sera remplacé par le
/// portail d'authentification à l'étape F5.
class PageSocleProvisoire extends StatelessWidget {
  const PageSocleProvisoire({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AZOnline')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MesuresNature.margeEcran),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: PaletteNature.vertTendre.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: PaletteNature.vertFeuille,
                  size: 44,
                ),
              ),
              const SizedBox(height: MesuresNature.espaceBloc),
              Text(
                'Firebase est connecté',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Le socle technique répond correctement.\n'
                'Les écrans de connexion arrivent à l\'étape suivante.',
                textAlign: TextAlign.center,
                style: TextStyle(color: PaletteNature.pierre, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
