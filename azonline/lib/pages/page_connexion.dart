import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../outils/validateurs.dart';
import '../services/service_auth.dart';
import '../theme/theme_nature.dart';

/// Porte d'entrée de l'application : connexion et inscription.
///
/// Les deux parcours partagent le même écran plutôt que d'occuper deux pages.
/// Ils demandent presque les mêmes informations, et basculer de l'un à l'autre
/// sans changer de contexte évite au parent de se perdre.
class PageConnexion extends ConsumerStatefulWidget {
  const PageConnexion({super.key});

  @override
  ConsumerState<PageConnexion> createState() => _EtatPageConnexion();
}

class _EtatPageConnexion extends ConsumerState<PageConnexion> {
  /// Clé du formulaire, utilisée pour déclencher la validation des champs.
  final GlobalKey<FormState> _cleDuFormulaire = GlobalKey<FormState>();

  final TextEditingController _adresse = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();

  /// `false` pour la connexion, `true` pour la création de compte.
  bool _modeInscription = false;

  /// Empêche le double envoi pendant que la requête est en cours.
  bool _envoiEnCours = false;

  /// Masquage du mot de passe.
  bool _motDePasseMasque = true;

  /// Message d'erreur affiché au-dessus du formulaire.
  String? _erreur;

  @override
  void dispose() {
    // Les contrôleurs retiennent des ressources : les libérer évite une fuite
    // de mémoire à chaque passage sur l'écran.
    _adresse.dispose();
    _motDePasse.dispose();
    _prenom.dispose();
    _nom.dispose();
    super.dispose();
  }

  /// Bascule entre connexion et inscription.
  ///
  /// L'erreur affichée est effacée : elle concernait le parcours précédent.
  void _changerDeMode() {
    setState(() {
      _modeInscription = !_modeInscription;
      _erreur = null;
    });
    _cleDuFormulaire.currentState?.reset();
  }

  /// Valide la saisie puis envoie la demande à Firebase.
  ///
  /// Aucune navigation n'est déclenchée ici. En cas de succès, Firebase émet un
  /// nouvel état de connexion, le portail le capte et remplace l'écran de
  /// lui-même. C'est ce qui garantit qu'une session ouverte dans un autre
  /// onglet est prise en compte sans action de l'utilisateur.
  Future<void> _envoyer() async {
    if (!(_cleDuFormulaire.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });

    final ServiceAuth service = ref.read(serviceAuthProvider);

    try {
      if (_modeInscription) {
        await service.inscription(
          email: _adresse.text.trim(),
          motDePasse: _motDePasse.text,
          nom: _nom.text.trim(),
          prenom: _prenom.text.trim(),
        );
      } else {
        await service.connexion(
          email: _adresse.text.trim(),
          motDePasse: _motDePasse.text,
        );
      }
    } on FirebaseAuthException catch (erreur) {
      // Le code technique est traduit par le service, jamais affiché tel quel.
      _afficherErreur(ServiceAuth.messageDErreur(erreur));
    } catch (erreur) {
      _afficherErreur('Une erreur inattendue est survenue.');
    } finally {
      // Le widget peut avoir disparu si la connexion a réussi entre-temps.
      if (mounted) {
        setState(() => _envoiEnCours = false);
      }
    }
  }

  void _afficherErreur(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _erreur = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MesuresNature.margeEcran),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _enTete(),
              const SizedBox(height: 32),
              if (_erreur != null) ...[
                _bandeauDErreur(_erreur!),
                const SizedBox(height: MesuresNature.espaceBloc),
              ],
              _formulaire(),
              const SizedBox(height: MesuresNature.espaceBloc),
              _boutonPrincipal(),
              const SizedBox(height: 8),
              _lienDeBascule(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Logo, nom de l'application et phrase d'accroche.
  Widget _enTete() {
    return Column(
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
        const SizedBox(height: 16),
        const Text(
          'AZOnline',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PaletteNature.vertProfond,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _modeInscription
              ? 'Créez votre compte parent pour suivre la scolarité '
                    'de vos enfants.'
              : 'Suivez la scolarité de vos enfants au jour le jour.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: PaletteNature.pierre, fontSize: 13),
        ),
      ],
    );
  }

  /// Bandeau rouge terre cuite affiché lorsqu'une demande échoue.
  Widget _bandeauDErreur(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaletteNature.terracotta.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MesuresNature.rayonBouton),
        border: Border.all(
          color: PaletteNature.terracotta.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: PaletteNature.terracotta,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: PaletteNature.terracotta,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Les champs de saisie, dans une carte.
  ///
  /// Le prénom et le nom n'apparaissent qu'à l'inscription : les redemander à
  /// la connexion n'aurait aucun sens.
  Widget _formulaire() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MesuresNature.margeEcran),
        child: Form(
          key: _cleDuFormulaire,
          child: Column(
            children: [
              if (_modeInscription) ...[
                TextFormField(
                  controller: _prenom,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (saisie) =>
                      validerChampObligatoire(saisie, 'prénom'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nom,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (saisie) => validerChampObligatoire(saisie, 'nom'),
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _adresse,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Adresse électronique',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: validerAdresse,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _motDePasse,
                obscureText: _motDePasseMasque,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _motDePasseMasque
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: PaletteNature.pierre,
                    ),
                    tooltip: _motDePasseMasque ? 'Afficher' : 'Masquer',
                    onPressed: () => setState(
                      () => _motDePasseMasque = !_motDePasseMasque,
                    ),
                  ),
                ),
                validator: validerMotDePasse,
                onFieldSubmitted: (_) => _envoyer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bouton d'envoi, qui affiche un indicateur pendant la requête.
  Widget _boutonPrincipal() {
    return ElevatedButton(
      onPressed: _envoiEnCours ? null : _envoyer,
      child: _envoiEnCours
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(_modeInscription ? 'Créer mon compte' : 'Se connecter'),
    );
  }

  /// Lien permettant de passer d'un parcours à l'autre.
  Widget _lienDeBascule() {
    return TextButton(
      onPressed: _envoiEnCours ? null : _changerDeMode,
      child: Text(
        _modeInscription
            ? 'J\'ai déjà un compte, me connecter'
            : 'Pas encore de compte ? En créer un',
        textAlign: TextAlign.center,
      ),
    );
  }
}
