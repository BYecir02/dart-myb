import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/enfant.dart';
import '../modeles/utilisateur.dart';
import '../outils/formats.dart';
import '../theme/theme_nature.dart';

/// Profil du parent connecté : ses informations, ses enfants, la déconnexion.
///
/// La déconnexion est placée ici plutôt que dans la barre supérieure : c'est un
/// geste rare et irréversible, il n'a pas à rester à portée de pouce sur tous
/// les écrans, où il serait déclenché par erreur.
class PageProfil extends ConsumerWidget {
  const PageProfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Utilisateur? profil = ref.watch(profilProvider).value;
    final List<Enfant> enfants = ref.watch(enfantsProvider).value ?? const [];
    final Enfant? actif = ref.watch(enfantSelectionneProvider);

    return ListView(
      padding: const EdgeInsets.all(MesuresNature.margeEcran),
      children: [
        _carteParent(profil),
        const SizedBox(height: MesuresNature.espaceBloc),

        Text(
          enfants.length > 1 ? 'Mes enfants' : 'Mon enfant',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (enfants.isEmpty)
          _aucunEnfant()
        else
          ...enfants.map(
            (enfant) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _carteEnfant(ref, enfant, enfant.id == actif?.id),
            ),
          ),

        const SizedBox(height: MesuresNature.espaceBloc),
        _aPropos(),
        const SizedBox(height: MesuresNature.espaceBloc),
        _boutonDeconnexion(context, ref),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Carte d'identité du parent.
  ///
  /// Le profil peut être absent le temps que le document remonte de Firestore,
  /// juste après une inscription. On affiche alors un état neutre plutôt qu'un
  /// écran vide.
  Widget _carteParent(Utilisateur? profil) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MesuresNature.margeEcran),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: PaletteNature.vertTendre.withValues(alpha: 0.30),
              child: Text(
                profil?.initiales ?? '?',
                style: const TextStyle(
                  color: PaletteNature.vertProfond,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profil?.nomComplet ?? 'Chargement du profil...',
                    style: const TextStyle(
                      color: PaletteNature.vertProfond,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profil != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      profil.email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PaletteNature.pierre,
                        fontSize: 13,
                      ),
                    ),
                    if (profil.dateInscription != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Compte créé le '
                        '${dateComplete(profil.dateInscription!)}',
                        style: const TextStyle(
                          color: PaletteNature.pierre,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Un enfant rattaché au compte, sélectionnable depuis cette liste.
  Widget _carteEnfant(WidgetRef ref, Enfant enfant, bool estActif) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MesuresNature.rayonCarte),
        side: BorderSide(
          color: estActif
              ? PaletteNature.vertFeuille
              : PaletteNature.pierre.withValues(alpha: 0.20),
          width: estActif ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        // Le profil offre un second chemin vers le changement d'enfant, en
        // plus du sélecteur de la barre supérieure.
        onTap: () =>
            ref.read(selectionEnfantProvider.notifier).choisir(enfant.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: estActif
                    ? PaletteNature.vertFeuille
                    : PaletteNature.vertTendre.withValues(alpha: 0.30),
                child: Text(
                  enfant.initiales,
                  style: TextStyle(
                    color: estActif ? Colors.white : PaletteNature.vertProfond,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enfant.nomComplet,
                      style: const TextStyle(
                        color: PaletteNature.vertProfond,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enfant.description,
                      style: const TextStyle(
                        color: PaletteNature.pierre,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (estActif)
                const Icon(
                  Icons.check_circle,
                  color: PaletteNature.vertFeuille,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiché tant qu'aucun enfant n'est rattaché au compte.
  Widget _aucunEnfant() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MesuresNature.margeEcran),
        child: Row(
          children: [
            const Icon(
              Icons.family_restroom_outlined,
              color: PaletteNature.pierre,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Aucun enfant rattaché. Générez les données de démonstration '
                'depuis l\'onglet d\'accueil.',
                style: TextStyle(
                  color: PaletteNature.pierre,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mention rappelant que les données ne sont pas réelles.
  ///
  /// L'application ressemble suffisamment à un portail scolaire pour qu'un
  /// utilisateur de passage s'y trompe. La mention lève l'ambiguïté.
  Widget _aPropos() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaletteNature.ecorce.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MesuresNature.rayonCarte),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 17,
            color: PaletteNature.ecorce,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'AZOnline est un projet d\'école. Les enfants, les notes et les '
              'emplois du temps sont fictifs : l\'application n\'est reliée à '
              'aucun établissement réel.',
              style: TextStyle(
                color: PaletteNature.ecorce,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton de déconnexion, précédé d'une demande de confirmation.
  Widget _boutonDeconnexion(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _confirmerPuisDeconnecter(context, ref),
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Se déconnecter'),
      style: OutlinedButton.styleFrom(
        foregroundColor: PaletteNature.terracotta,
        side: const BorderSide(color: PaletteNature.terracotta),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MesuresNature.rayonBouton),
        ),
      ),
    );
  }

  /// Demande confirmation, puis ferme la session.
  ///
  /// Les données locales sont effacées avant la déconnexion : sans cela, le
  /// parent suivant à se connecter sur le même appareil retrouverait l'enfant
  /// sélectionné et les notes en cache du précédent.
  ///
  /// Aucune navigation n'est nécessaire ensuite : le portail observe l'état de
  /// connexion et réaffiche l'écran de connexion de lui-même.
  Future<void> _confirmerPuisDeconnecter(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool? confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text(
          'Vous devrez saisir à nouveau votre adresse et votre mot de passe '
          'pour revenir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: PaletteNature.terracotta,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirme != true) {
      return;
    }

    await ref.read(serviceStockageLocalProvider).oublierTout();
    await ref.read(serviceAuthProvider).deconnexion();
  }
}
