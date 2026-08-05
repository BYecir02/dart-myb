import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'fournisseurs/fournisseurs.dart';
import 'pages/page_configuration_requise.dart';
import 'pages/page_connexion.dart';
import 'pages/page_principale.dart';
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
    ProviderScope(
      child: ApplicationAZOnline(messageDemarrage: messageDemarrage),
    ),
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
          ? const PortailAuthentification()
          : PageConfigurationRequise(message: messageDemarrage!),
    );
  }
}

/// Portail : c'est lui qui rend le suivi scolaire inaccessible sans compte.
///
/// Il observe l'état de connexion et choisit la page à afficher. Aucun écran
/// protégé n'est joignable tant que [compteProvider] renvoie `null`, y compris
/// en manipulant la navigation : il n'existe simplement aucune route vers eux.
///
/// C'est aussi ce qui dispense les pages de connexion et de déconnexion de
/// naviguer elles-mêmes. Elles se contentent d'appeler le service ; le
/// changement d'écran découle du nouvel état émis par Firebase.
class PortailAuthentification extends ConsumerWidget {
  const PortailAuthentification({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Object?> etatDuCompte = ref.watch(compteProvider);

    return etatDuCompte.when(
      // Premier instant de l'application : Firebase vérifie s'il existe une
      // session enregistrée sur l'appareil.
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (erreur, trace) => _ecranDErreur(erreur),
      data: (compte) {
        if (compte == null) {
          return const PageConnexion();
        }
        return const PagePrincipale();
      },
    );
  }

  /// Affiché si le service d'authentification lui-même est en défaut.
  Widget _ecranDErreur(Object erreur) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MesuresNature.margeEcran),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 56,
                color: PaletteNature.terracotta,
              ),
              const SizedBox(height: 16),
              const Text(
                'Service d\'authentification indisponible',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PaletteNature.vertProfond,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$erreur',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PaletteNature.pierre,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
