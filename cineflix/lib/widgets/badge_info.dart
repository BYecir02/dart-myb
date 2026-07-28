import 'package:flutter/material.dart';

/// Petite pastille d'information affichée dans les angles d'une carte film.
class BadgeInfo extends StatelessWidget {
  final String texte;
  final Color couleur;
  final bool compact;

  const BadgeInfo({
    super.key,
    required this.texte,
    required this.couleur,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4),
        ],
      ),
      child: Text(
        texte,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 9 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
