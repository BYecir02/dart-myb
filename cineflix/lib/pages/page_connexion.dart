import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../services/service_auth.dart';

/// Écran d'ouverture de l'application.
///
/// Tant que l'utilisateur n'a pas de compte valide, il ne peut pas
/// atteindre le catalogue : c'est le portail d'authentification qui
/// décide de la page affichée, en fonction de `utilisateurProvider`.
class PageConnexion extends ConsumerStatefulWidget {
  const PageConnexion({super.key});

  @override
  ConsumerState<PageConnexion> createState() => _PageConnexionState();
}

class _PageConnexionState extends ConsumerState<PageConnexion> {
  final TextEditingController _controleurEmail = TextEditingController();
  final TextEditingController _controleurMotDePasse = TextEditingController();

  bool _modeInscription = false;
  bool _chargementEnCours = false;
  String? _messageErreur;

  @override
  void dispose() {
    _controleurEmail.dispose();
    _controleurMotDePasse.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final String email = _controleurEmail.text.trim();
    final String motDePasse = _controleurMotDePasse.text;

    // Retours visuels immédiats sur les erreurs de saisie.
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _messageErreur = 'Merci de saisir une adresse email valide.');
      return;
    }
    if (motDePasse.length < 6) {
      setState(() {
        _messageErreur = 'Le mot de passe doit contenir au moins 6 caractères.';
      });
      return;
    }

    setState(() {
      _chargementEnCours = true;
      _messageErreur = null;
    });

    try {
      final ServiceAuth service = ref.read(serviceAuthProvider);
      if (_modeInscription) {
        await service.inscription(email: email, motDePasse: motDePasse);
      } else {
        await service.connexion(email: email, motDePasse: motDePasse);
      }
      // Aucune navigation manuelle : le portail réagit au changement d'état.
    } on FirebaseAuthException catch (erreur) {
      if (!mounted) return;
      final String message = ServiceAuth.messageDErreur(erreur);
      setState(() => _messageErreur = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
      );
    } catch (erreur) {
      if (!mounted) return;
      setState(() => _messageErreur = 'Une erreur inattendue est survenue.');
    } finally {
      if (mounted) {
        setState(() => _chargementEnCours = false);
      }
    }
  }

  void _changerDeMode() {
    setState(() {
      _modeInscription = !_modeInscription;
      _messageErreur = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14141A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.movie_filter, color: Colors.red, size: 72),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'CinéFlix',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _modeInscription
                        ? 'Créez votre compte pour accéder au catalogue'
                        : 'Connectez-vous pour accéder au catalogue',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 36),

                _construireChamp(
                  controleur: _controleurEmail,
                  libelle: 'Adresse email',
                  icone: Icons.email_outlined,
                  typeClavier: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _construireChamp(
                  controleur: _controleurMotDePasse,
                  libelle: 'Mot de passe',
                  icone: Icons.lock_outline,
                  masquer: true,
                ),

                // Encadré d'erreur : le retour visuel exigé.
                if (_messageErreur != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade700),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _messageErreur!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _chargementEnCours ? null : _valider,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _chargementEnCours
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _modeInscription
                              ? 'Créer mon compte'
                              : 'Se connecter',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _chargementEnCours ? null : _changerDeMode,
                  child: Text(
                    _modeInscription
                        ? "J'ai déjà un compte - Se connecter"
                        : "Pas encore de compte ? - S'inscrire",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construireChamp({
    required TextEditingController controleur,
    required String libelle,
    required IconData icone,
    bool masquer = false,
    TextInputType typeClavier = TextInputType.text,
  }) {
    return TextField(
      controller: controleur,
      obscureText: masquer,
      keyboardType: typeClavier,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: libelle,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icone, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1F1F28),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
