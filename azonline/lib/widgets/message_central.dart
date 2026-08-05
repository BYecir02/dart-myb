import 'package:flutter/material.dart';

import '../theme/theme_nature.dart';

/// Message occupant tout l'espace disponible, avec une icône et un texte.
///
/// Trois situations reviennent sur presque chaque écran branché sur le réseau :
/// il n'y a rien à afficher, la lecture a échoué, ou l'écran attend une action.
/// Les traiter avec un composant commun évite qu'elles soient dessinées
/// différemment d'un onglet à l'autre, ce qui donnerait une impression de
/// bricolage.
class MessageCentral extends StatelessWidget {
  final IconData icone;
  final String titre;

  /// Détail affiché sous le titre. Facultatif.
  final String? message;

  /// Bouton ou lien proposé sous le message. Facultatif.
  final Widget? action;

  /// Teinte de l'icône. Neutre par défaut, terre cuite pour une erreur.
  final Color? couleurIcone;

  const MessageCentral({
    super.key,
    required this.icone,
    required this.titre,
    this.message,
    this.action,
    this.couleurIcone,
  });

  /// Variante pour une lecture qui a échoué.
  ///
  /// Le détail technique est conservé : il ne dit rien au parent, mais il est
  /// la première chose utile lorsqu'il faut comprendre une panne.
  factory MessageCentral.erreur(Object erreur, {String? titre}) {
    return MessageCentral(
      icone: Icons.cloud_off,
      titre: titre ?? 'Lecture impossible',
      message: 'Vérifiez votre connexion, puis réessayez.\n\n$erreur',
      couleurIcone: PaletteNature.terracotta,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MesuresNature.margeEcran),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 48,
              color: couleurIcone ?? PaletteNature.pierre,
            ),
            const SizedBox(height: 14),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PaletteNature.pierre,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
