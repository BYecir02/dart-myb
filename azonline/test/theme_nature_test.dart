import 'package:azonline/theme/theme_nature.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie la traduction d'une note en couleur.
///
/// Cette logique ne dépend ni de Firebase ni de l'interface : elle se teste
/// donc sans réseau et sans construire le moindre widget. C'est exactement
/// l'intérêt d'avoir isolé les calculs hors des pages.
void main() {
  group('couleurSelonNote', () {
    test('un très bon résultat ressort en vert profond', () {
      expect(couleurSelonNote(18), PaletteNature.vertProfond);
      expect(couleurSelonNote(16), PaletteNature.vertProfond);
    });

    test('un résultat satisfaisant ressort en vert tendre', () {
      expect(couleurSelonNote(15.9), PaletteNature.vertTendre);
      expect(couleurSelonNote(12), PaletteNature.vertTendre);
    });

    test('un résultat limite ressort en miel', () {
      expect(couleurSelonNote(11.5), PaletteNature.miel);
      expect(couleurSelonNote(10), PaletteNature.miel);
    });

    test('un résultat en difficulté ressort en terracotta', () {
      expect(couleurSelonNote(9.9), PaletteNature.terracotta);
      expect(couleurSelonNote(0), PaletteNature.terracotta);
    });

    test('la note est ramenée sur 20 avant comparaison', () {
      // 8 sur 10 vaut 16 sur 20 : même couleur qu'un 16 sur 20.
      expect(couleurSelonNote(8, bareme: 10), PaletteNature.vertProfond);
      // 4 sur 10 vaut 8 sur 20 : le résultat est en difficulté.
      expect(couleurSelonNote(4, bareme: 10), PaletteNature.terracotta);
    });

    test('un barème invalide renvoie une couleur neutre sans planter', () {
      expect(couleurSelonNote(12, bareme: 0), PaletteNature.pierre);
      expect(couleurSelonNote(12, bareme: -5), PaletteNature.pierre);
    });
  });
}
