import 'package:flutter/material.dart';

import 'page_catalogue.dart';
import 'page_profil.dart';

/// Coquille de l'application une fois l'utilisateur connecté.
///
/// Elle porte les deux onglets exigés : le catalogue et le profil.
/// L'index courant est un état purement local : `setState()` suffit,
/// pas besoin de Riverpod ici.
class PagePrincipale extends StatefulWidget {
  const PagePrincipale({super.key});

  @override
  State<PagePrincipale> createState() => _PagePrincipaleState();
}

class _PagePrincipaleState extends State<PagePrincipale> {
  int _indexActuel = 0;

  static const List<Widget> _onglets = [
    PageCatalogue(),
    PageProfil(),
  ];

  void _changerDOnglet(int index) {
    setState(() {
      _indexActuel = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack conserve l'état de chaque onglet lors des allers-retours.
      body: IndexedStack(index: _indexActuel, children: _onglets),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexActuel,
        onTap: _changerDOnglet,
        backgroundColor: const Color(0xFF1C1C22),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_movies_outlined),
            activeIcon: Icon(Icons.local_movies),
            label: 'Catalogue',
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
}
