// Test du composant "carte intelligente".
//
// Il vérifie le critère d'adaptabilité de l'interface : le même widget
// CarteFilm doit se présenter différemment selon la place disponible.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineflix/modeles/film.dart';
import 'package:cineflix/widgets/carte_film.dart';

final Film filmDeTest = Film(
  id: 'test-1',
  titre: 'Inception',
  genre: 'Science-Fiction',
  ageMinimum: 12,
  synopsis: 'Un voleur qui dérobe des secrets dans les rêves.',
  imageUrl: 'https://exemple.invalide/affiche.png',
);

Widget _enveloppe({required double largeur}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: largeur,
          height: 300,
          child: CarteFilm(film: filmDeTest, onVoir: () {}),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('en cellule de grille, la carte adopte la présentation compacte',
      (WidgetTester tester) async {
    await tester.pumpWidget(_enveloppe(largeur: 140));

    // Le badge d'âge est abrégé et le synopsis n'est pas affiché.
    expect(find.text('12+'), findsOneWidget);
    expect(find.text('Science-Fiction'), findsOneWidget);
    expect(find.text('Voir'), findsOneWidget);
    expect(find.text(filmDeTest.synopsis), findsNothing);
  });

  testWidgets('en pleine largeur, la carte adopte la présentation étendue',
      (WidgetTester tester) async {
    await tester.pumpWidget(_enveloppe(largeur: 420));

    // Le badge d'âge est écrit en toutes lettres et le synopsis apparaît.
    expect(find.text('12 ans et +'), findsOneWidget);
    expect(find.text('Science-Fiction'), findsOneWidget);
    expect(find.text('Voir'), findsOneWidget);
    expect(find.text(filmDeTest.synopsis), findsOneWidget);
  });

  test('Film.depuisFirestore comble les champs manquants', () {
    final film = Film.depuisFirestore('abc', {'titre': 'Matrix'});

    expect(film.id, 'abc');
    expect(film.titre, 'Matrix');
    expect(film.genre, 'Non classé');
    expect(film.ageMinimum, 0);
  });
}
