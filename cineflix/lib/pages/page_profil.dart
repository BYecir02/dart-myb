import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fournisseurs/fournisseurs.dart';
import '../modeles/film.dart';
import '../widgets/carte_film.dart';
import 'page_detail_film.dart';

/// Onglet Profil : informations du compte, favoris enregistrés en base,
/// et déconnexion.
class PageProfil extends ConsumerWidget {
  const PageProfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurProvider).value;
    final Map<String, dynamic> profil =
        ref.watch(profilProvider).value ?? <String, dynamic>{};
    final List<Film> favoris = ref.watch(filmsFavorisProvider);
    final bool favorisEnCoursDeChargement =
        ref.watch(favorisProvider).isLoading || ref.watch(filmsProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF14141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C22),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mon profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _construireEnteteCompte(
                email: utilisateur?.email ?? 'Inconnu',
                identifiant: utilisateur?.uid ?? '-',
                dateInscription: _formaterDate(profil['dateInscription']),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Mes films favoris',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${favoris.length}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (favorisEnCoursDeChargement)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
                )
              else if (favoris.isEmpty)
                _construireAucunFavori()
              else
                Column(
                  children: [
                    for (final Film film in favoris)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: CarteFilm(
                          film: film,
                          onVoir: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PageDetailFilm(film: film),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _demanderDeconnexion(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A33),
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construireEnteteCompte({
    required String email,
    required String identifiant,
    required String dateInscription,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compte connecté',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _construireLigneInfo('Membre depuis', dateInscription),
          const SizedBox(height: 8),
          _construireLigneInfo('Identifiant', identifiant),
        ],
      ),
    );
  }

  Widget _construireLigneInfo(String libelle, String valeur) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            libelle,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            valeur,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _construireAucunFavori() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E3A)),
      ),
      child: const Column(
        children: [
          Icon(Icons.favorite_border, color: Colors.white24, size: 44),
          SizedBox(height: 12),
          Text(
            'Aucun favori pour le moment',
            style: TextStyle(color: Colors.white54),
          ),
          SizedBox(height: 4),
          Text(
            'Ouvrez la fiche d\'un film pour l\'ajouter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Modale de confirmation avant de quitter la session.
  Future<void> _demanderDeconnexion(BuildContext context, WidgetRef ref) async {
    final messager = ScaffoldMessenger.of(context);

    final bool? confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F28),
        title: const Text(
          'Déconnexion',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Confirmer',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirme != true) {
      return;
    }

    try {
      await ref.read(serviceAuthProvider).deconnexion();
      // Le portail d'authentification ramène automatiquement à la connexion.
    } catch (erreur) {
      messager.showSnackBar(
        SnackBar(
          content: Text('Déconnexion impossible : $erreur'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String _formaterDate(dynamic valeur) {
    if (valeur is Timestamp) {
      final DateTime date = valeur.toDate();
      final String jour = date.day.toString().padLeft(2, '0');
      final String mois = date.month.toString().padLeft(2, '0');
      return '$jour/$mois/${date.year}';
    }
    return 'Non renseignée';
  }
}
