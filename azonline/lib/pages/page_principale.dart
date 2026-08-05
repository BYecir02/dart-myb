import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/enfant.dart';
import '../outils/peupler_base.dart';
import '../theme/theme_nature.dart';

/// Coquille de l'application une fois le parent connecté.
///
/// Elle porte la barre de navigation inférieure et conserve l'onglet actif.
/// Le contenu de chaque onglet est ajouté par les étapes suivantes du plan :
/// le tableau de bord en F9, l'emploi du temps en F11, le profil en F12.
class PagePrincipale extends ConsumerStatefulWidget {
  const PagePrincipale({super.key});

  @override
  ConsumerState<PagePrincipale> createState() => _EtatPagePrincipale();
}

class _EtatPagePrincipale extends ConsumerState<PagePrincipale> {
  int _ongletActif = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AZOnline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _seDeconnecter,
          ),
        ],
      ),

      // IndexedStack conserve l'état de chaque onglet : la position de
      // défilement d'une liste n'est pas perdue en changeant d'onglet, ce qui
      // arriverait si l'on reconstruisait la page à chaque fois.
      body: IndexedStack(
        index: _ongletActif,
        children: [
          _accueil(),
          const _ContenuAVenir(
            icone: Icons.calendar_month_outlined,
            titre: 'Emploi du temps',
            message: 'Les cours de la semaine arrivent ici.',
          ),
          const _ContenuAVenir(
            icone: Icons.person_outline,
            titre: 'Profil',
            message: 'Vos informations et vos enfants arrivent ici.',
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _ongletActif,
        onTap: (index) => setState(() => _ongletActif = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Emploi du temps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  /// Contenu de l'onglet d'accueil.
  ///
  /// Tant qu'aucun enfant n'est rattaché au compte, l'écran propose de générer
  /// les données de démonstration : c'est le seul geste utile à ce stade, et
  /// une page vide n'apprendrait rien au parent qui vient de s'inscrire.
  ///
  /// Le tableau de bord viendra remplacer le second cas en F9.
  Widget _accueil() {
    final AsyncValue<List<Enfant>> etatDesEnfants = ref.watch(enfantsProvider);

    return etatDesEnfants.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (erreur, trace) => _ContenuAVenir(
        icone: Icons.cloud_off,
        titre: 'Lecture impossible',
        message: '$erreur',
      ),
      data: (enfants) {
        if (enfants.isEmpty) {
          return const EncartBaseVide();
        }
        return const _ContenuAVenir(
          icone: Icons.insights_outlined,
          titre: 'Tableau de bord',
          message: 'Les moyennes et les dernières notes arrivent ici.',
        );
      },
    );
  }

  /// Ferme la session.
  ///
  /// Les données locales sont effacées avant la déconnexion : sans cela, le
  /// parent suivant à se connecter sur le même appareil retrouverait l'enfant
  /// sélectionné et les notes en cache du précédent.
  ///
  /// Aucune navigation n'est nécessaire ensuite : le portail observe l'état de
  /// connexion et réaffiche l'écran de connexion de lui-même.
  Future<void> _seDeconnecter() async {
    await ref.read(serviceStockageLocalProvider).oublierTout();
    await ref.read(serviceAuthProvider).deconnexion();
  }
}

/// Emplacement réservé pour un onglet dont le contenu n'est pas encore écrit.
///
/// Il sera remplacé par la vraie page à l'étape correspondante du plan.
class _ContenuAVenir extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String message;

  const _ContenuAVenir({
    required this.icone,
    required this.titre,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MesuresNature.margeEcran),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 56,
              color: PaletteNature.pierre.withValues(alpha: 0.60),
            ),
            const SizedBox(height: 16),
            Text(titre, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
