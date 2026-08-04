import 'package:flutter/material.dart';

/// Palette de l'application, construite autour d'un registre naturel :
/// la feuille, le bois, le papier recyclé et le ciel.
///
/// Aucune couleur n'est écrite en dur ailleurs dans le projet : tout passe par
/// cette classe. L'identité visuelle peut donc évoluer depuis un seul fichier,
/// sans avoir à parcourir les pages une par une.
class PaletteNature {
  /// Constructeur privé : la classe ne sert que de porte-couleurs,
  /// elle n'a pas vocation à être instanciée.
  const PaletteNature._();

  /// Vert principal : boutons, barre de navigation, accents.
  static const Color vertFeuille = Color(0xFF2F6F4E);

  /// Vert sombre : titres et textes forts.
  static const Color vertProfond = Color(0xFF1B4332);

  /// Vert tendre : badges et indicateurs positifs.
  static const Color vertTendre = Color(0xFF7FB069);

  /// Beige très clair : fond de page, évoque le papier recyclé.
  static const Color sable = Color(0xFFF7F4ED);

  /// Blanc cassé : surface des cartes et des listes.
  static const Color blancCasse = Color(0xFFFFFFFF);

  /// Brun bois : couleur secondaire, en-têtes de matière.
  static const Color ecorce = Color(0xFF6B4F3A);

  /// Bleu doux : accent froid réservé à l'emploi du temps.
  static const Color ciel = Color(0xFF8FB8CE);

  /// Terre cuite : signale une difficulté, sans la violence d'un rouge vif.
  static const Color terracotta = Color(0xFFC1663F);

  /// Jaune miel : signale un résultat limite.
  static const Color miel = Color(0xFFD9A441);

  /// Gris chaud : textes secondaires et séparateurs.
  static const Color pierre = Color(0xFF8A8578);
}

/// Mesures partagées par toute l'interface.
///
/// Les regrouper ici évite les valeurs magiques dispersées dans les widgets et
/// garantit que deux cartes voisines auront exactement le même arrondi.
class MesuresNature {
  const MesuresNature._();

  /// Arrondi des cartes et des grands blocs.
  static const double rayonCarte = 16;

  /// Arrondi des boutons et des champs de saisie.
  static const double rayonBouton = 12;

  /// Marge horizontale standard d'un écran.
  static const double margeEcran = 16;

  /// Espace vertical entre deux blocs de contenu.
  static const double espaceBloc = 20;

  /// Largeur maximale de l'application.
  ///
  /// L'application est pensée pour le mobile. Sur un navigateur large, ce
  /// plafond conserve les proportions au lieu d'étirer les listes.
  static const double largeurMaximale = 500;
}

/// Construit le thème Material 3 de l'application à partir de la palette.
class ThemeNature {
  const ThemeNature._();

  /// Assemble le [ThemeData] appliqué au [MaterialApp].
  ///
  /// On part d'un [ColorScheme.fromSeed] pour que Material 3 dérive
  /// automatiquement les dizaines de teintes dont il a besoin, puis on impose
  /// nos couleurs sur les rôles qui comptent visuellement.
  static ThemeData construire() {
    final ColorScheme nuancier =
        ColorScheme.fromSeed(
          seedColor: PaletteNature.vertFeuille,
          brightness: Brightness.light,
        ).copyWith(
          primary: PaletteNature.vertFeuille,
          onPrimary: Colors.white,
          secondary: PaletteNature.ecorce,
          onSecondary: Colors.white,
          surface: PaletteNature.blancCasse,
          onSurface: PaletteNature.vertProfond,
          error: PaletteNature.terracotta,
          onError: Colors.white,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: nuancier,
      scaffoldBackgroundColor: PaletteNature.sable,

      appBarTheme: const AppBarTheme(
        backgroundColor: PaletteNature.vertFeuille,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: PaletteNature.blancCasse,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MesuresNature.rayonCarte),
          side: BorderSide(color: PaletteNature.pierre.withValues(alpha: 0.20)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PaletteNature.vertFeuille,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MesuresNature.rayonBouton),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: PaletteNature.vertFeuille),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PaletteNature.blancCasse,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: PaletteNature.pierre),
        labelStyle: const TextStyle(color: PaletteNature.pierre),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MesuresNature.rayonBouton),
          borderSide: BorderSide(
            color: PaletteNature.pierre.withValues(alpha: 0.35),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MesuresNature.rayonBouton),
          borderSide: BorderSide(
            color: PaletteNature.pierre.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MesuresNature.rayonBouton),
          borderSide: const BorderSide(
            color: PaletteNature.vertFeuille,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MesuresNature.rayonBouton),
          borderSide: const BorderSide(color: PaletteNature.terracotta),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PaletteNature.blancCasse,
        selectedItemColor: PaletteNature.vertFeuille,
        unselectedItemColor: PaletteNature.pierre,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),

      dividerTheme: DividerThemeData(
        color: PaletteNature.pierre.withValues(alpha: 0.20),
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: PaletteNature.vertProfond,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MesuresNature.rayonBouton),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: PaletteNature.vertFeuille,
      ),

      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: PaletteNature.vertProfond,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: PaletteNature.vertProfond,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: PaletteNature.vertProfond,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: PaletteNature.vertProfond, fontSize: 14),
        bodySmall: TextStyle(color: PaletteNature.pierre, fontSize: 12),
      ),
    );
  }
}

/// Traduit un résultat scolaire en couleur.
///
/// La note est d'abord ramenée sur 20, car toutes les évaluations n'ont pas le
/// même barème : un 8 sur 10 et un 16 sur 20 doivent afficher la même couleur.
///
/// Le rouge vif est volontairement écarté : les quatre teintes restent dans le
/// registre naturel de la palette, pour informer sans dramatiser.
Color couleurSelonNote(double valeur, {double bareme = 20}) {
  // Un barème nul ou négatif viendrait d'un document incomplet en base.
  // On renvoie une teinte neutre plutôt que de laisser passer une division
  // par zéro jusqu'à l'affichage.
  if (bareme <= 0) {
    return PaletteNature.pierre;
  }

  final double noteSurVingt = valeur / bareme * 20;

  if (noteSurVingt >= 16) {
    return PaletteNature.vertProfond;
  }
  if (noteSurVingt >= 12) {
    return PaletteNature.vertTendre;
  }
  if (noteSurVingt >= 10) {
    return PaletteNature.miel;
  }
  return PaletteNature.terracotta;
}
