import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'fournisseurs/fournisseurs.dart';
import 'pages/page_connexion.dart';
import 'pages/page_principale.dart';

/// Valeur présente dans le gabarit `firebase_options.dart`.
/// Après `flutterfire configure`, la vraie clé la remplace et l'application
/// démarre normalement.
const String cleNonConfiguree = 'A_REMPLACER_PAR_FLUTTERFIRE';

Future<void> main() async {
  // Obligatoire : Firebase dialogue avec la couche native avant que
  // l'interface Flutter ne soit dessinée.
  WidgetsFlutterBinding.ensureInitialized();

  String? messageDemarrage;

  try {
    final FirebaseOptions options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey == cleNonConfiguree) {
      messageDemarrage = 'Firebase n\'est pas encore configuré sur ce projet.';
    } else {
      await Firebase.initializeApp(options: options);
    }
  } catch (erreur) {
    messageDemarrage = 'Initialisation de Firebase impossible : $erreur';
  }

  runApp(
    // ProviderScope stocke l'état global de toute l'application.
    ProviderScope(
      child: ApplicationCineFlix(messageDemarrage: messageDemarrage),
    ),
  );
}

class ApplicationCineFlix extends StatelessWidget {
  final String? messageDemarrage;

  const ApplicationCineFlix({super.key, this.messageDemarrage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinéFlix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14141A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
      ),
      // L'application est pensée pour mobile. Sur un navigateur large,
      // on la garde dans un cadre étroit pour conserver les proportions
      // de la grille (3 films par ligne).
      builder: (context, enfant) {
        return ColoredBox(
          color: const Color(0xFF08080C),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
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

/// Portail : c'est lui qui rend le catalogue inaccessible sans compte.
///
/// Il écoute l'état de connexion et choisit la page à afficher.
/// Aucun écran protégé n'est joignable tant que `utilisateurProvider`
/// renvoie `null`.
class PortailAuthentification extends ConsumerWidget {
  const PortailAuthentification({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatUtilisateur = ref.watch(utilisateurProvider);

    return etatUtilisateur.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF14141A),
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      ),
      error: (erreur, trace) => Scaffold(
        backgroundColor: const Color(0xFF14141A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erreur d\'authentification : $erreur',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
      data: (utilisateur) {
        if (utilisateur == null) {
          return const PageConnexion();
        }
        return const PagePrincipale();
      },
    );
  }
}

/// Écran affiché tant que les clés Firebase n'ont pas été générées.
class PageConfigurationRequise extends StatelessWidget {
  final String message;

  const PageConfigurationRequise({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14141A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.settings_suggest_outlined,
                  color: Colors.orange, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Configuration Firebase requise',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F28),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E2E3A)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'À faire une seule fois :',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Créer le projet sur console.firebase.google.com\n'
                      '2. Activer Authentication > Email/Mot de passe\n'
                      '3. Créer la base Cloud Firestore\n'
                      '4. Lancer : flutterfire configure\n'
                      '5. Relancer l\'application',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Le détail pas à pas se trouve dans GUIDE-FIREBASE.md,\n'
                'à la racine du projet.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
