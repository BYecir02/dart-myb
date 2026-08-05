import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/enfant.dart';
import '../outils/peupler_base.dart';
import '../theme/theme_nature.dart';
import '../widgets/message_central.dart';
import '../widgets/selecteur_enfant.dart';
import 'page_detail_matiere.dart';
import 'page_emploi_du_temps.dart';
import 'page_profil.dart';
import 'page_tableau_de_bord.dart';

/// Coquille de l'application une fois le parent connecté.
///
/// Elle porte la barre de navigation inférieure et conserve l'onglet actif :
/// le tableau de bord, l'emploi du temps et le profil.
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
        // Le titre porte le sélecteur d'enfant : l'enfant consulté est le
        // contexte de tous les onglets, il doit rester visible en permanence.
        title: const SelecteurEnfant(),
        titleSpacing: MesuresNature.margeEcran,
      ),

      // IndexedStack conserve l'état de chaque onglet : la position de
      // défilement d'une liste n'est pas perdue en changeant d'onglet, ce qui
      // arriverait si l'on reconstruisait la page à chaque fois.
      body: IndexedStack(
        index: _ongletActif,
        children: [
          _accueil(),
          const PageEmploiDuTemps(),
          const PageProfil(),
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
  Widget _accueil() {
    final AsyncValue<List<Enfant>> etatDesEnfants = ref.watch(enfantsProvider);

    return etatDesEnfants.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (erreur, trace) => MessageCentral.erreur(
        erreur,
        titre: 'Impossible de lire vos enfants',
      ),
      data: (enfants) {
        if (enfants.isEmpty) {
          return const EncartBaseVide();
        }
        return PageTableauDeBord(surMatiereChoisie: _ouvrirLaMatiere);
      },
    );
  }

  /// Ouvre le détail d'une matière par-dessus l'onglet courant.
  ///
  /// La navigation est déclenchée ici plutôt que dans le tableau de bord :
  /// celui-ci reste ainsi un écran d'affichage pur, montable seul dans un test
  /// sans avoir à fournir un Navigator.
  void _ouvrirLaMatiere(BuildContext context, String matiere) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PageDetailMatiere(matiere: matiere),
      ),
    );
  }
}
