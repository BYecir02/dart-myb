# AZOnline

> Application mobile de suivi de la scolarité, destinée aux parents.

---

## 1. L'objectif du projet

**AZOnline** permet à un parent de suivre la scolarité de ses enfants depuis son
téléphone, sans avoir à attendre le bulletin trimestriel.

Après s'être connecté, le parent accède pour chacun de ses enfants à :

- **ses notes**, matière par matière, avec le détail de chaque évaluation
  (intitulé, barème, coefficient, appréciation du professeur) ;
- **ses moyennes**, calculées automatiquement et pondérées par les coefficients ;
- **son emploi du temps** de la semaine, jour par jour.

L'application répond à un besoin concret : donner au parent une vision claire et
immédiate du travail de son enfant, là où l'information est habituellement
dispersée entre carnet de correspondance, bulletins papier et portails scolaires
peu ergonomiques.

> **Note sur les données :** ce projet est un exercice pédagogique. Les données
> (enfants, notes, cours) sont **fictives** et générées par un outil de
> peuplement intégré à l'application. Aucune connexion à un système scolaire
> réel n'est mise en place.

---

## 2. Le groupe

| Nom | Prénom |
| --- | --- |
| _à compléter_ | _à compléter_ |

---

## 3. La stack technique

| Outil | Version | Rôle |
| --- | --- | --- |
| Flutter | 3.32.1 (stable) | Framework d'interface |
| Dart | 3.8.1 | Langage |

### Packages

| Package | Rôle dans le projet |
| --- | --- |
| `firebase_core` | Initialisation du SDK Firebase |
| `firebase_auth` | Inscription et connexion des parents |
| `cloud_firestore` | Base de données distante (notes, cours, enfants) |
| `flutter_riverpod` | Gestion d'état et injection des services |
| `shared_preferences` | Stockage local sur le téléphone |
| `cupertino_icons` | Jeu d'icônes |
| `flutter_lints` | Règles d'analyse statique |

---

## 4. L'architecture

### 4.1 L'arborescence

```
lib/
├── main.dart                          # Initialisation Firebase + portail d'authentification
├── firebase_options.dart              # Généré par `flutterfire configure`
│
├── theme/                             # Identité visuelle
│   └── theme_nature.dart              #   Palette + ThemeData de l'application
│
├── modeles/                           # COUCHE MÉTIER : objets purs
│   ├── conversions.dart               #   Lecture défensive des champs Firestore
│   ├── utilisateur.dart               #   Le parent connecté
│   ├── enfant.dart                    #   Un enfant rattaché au parent
│   ├── note.dart                      #   Une évaluation
│   ├── cours.dart                     #   Un créneau de l'emploi du temps
│   └── moyenne_matiere.dart           #   Résultat calculé, sans dépendance Firebase
│
├── services/                          # COUCHE DONNÉES
│   ├── service_auth.dart              #   Tous les échanges avec Firebase Auth
│   ├── service_firestore.dart         #   Tous les échanges avec Cloud Firestore
│   └── service_stockage_local.dart    #   Tous les échanges avec SharedPreferences
│
├── fournisseurs/                      # COUCHE LOGIQUE ET ÉTAT
│   └── fournisseurs.dart              #   Providers Riverpod + calcul des moyennes
│
├── pages/                             # COUCHE PRÉSENTATION
│   ├── page_connexion.dart
│   ├── page_principale.dart           #   Barre de navigation inférieure
│   ├── page_tableau_de_bord.dart
│   ├── page_detail_matiere.dart
│   ├── page_emploi_du_temps.dart
│   └── page_profil.dart
│
├── widgets/                           # Composants réutilisables
│   ├── carte_note.dart
│   ├── carte_matiere.dart
│   ├── carte_cours.dart
│   ├── selecteur_enfant.dart
│   └── jauge_moyenne.dart
│
└── outils/
    ├── validateurs.dart               # Règles de saisie des formulaires
    ├── formats.dart                   # Mise en forme des dates en français
    └── peupler_base.dart              # Génération des données fictives
```

### 4.2 La justification de l'architecture

L'architecture retenue est une **architecture en couches inspirée de la Clean
Architecture**, adaptée à la taille du projet. Elle repose sur une règle simple
et vérifiable : **chaque couche ne connaît que la couche située en dessous
d'elle, jamais celle du dessus.**

```
   pages / widgets          (présentation)
          ↓  lit des providers, ne connaît aucun SDK
     fournisseurs           (logique métier et état)
          ↓  appelle des services, expose des modèles
       services             (accès aux données)
          ↓  parle à Firebase et au stockage du téléphone
       modeles              (objets purs, ne dépendent de rien)
```

**Pourquoi ce découpage ?**

1. **Aucun SDK dans l'interface.** Aucun fichier de `pages/` ou `widgets/`
   n'importe `cloud_firestore` ou `firebase_auth`. Une page se contente de lire
   un provider et d'afficher son résultat. Conséquence directe : si demain les
   données viennent d'une API REST au lieu de Firestore, seule la couche
   `services/` est réécrite, sans que l'interface soit touchée.

2. **Les données brutes ne circulent jamais.** Un `DocumentSnapshot` Firestore
   est converti en objet Dart typé dès sa sortie du service, via un constructeur
   nommé `depuisFirestore()`. Le reste de l'application ne manipule que des
   objets `Note`, `Cours` ou `Enfant`. Aucune `Map<String, dynamic>` ne remonte
   jusqu'à l'affichage.

3. **La logique métier est isolée et testable.** Le calcul des moyennes
   pondérées par coefficient vit dans `fournisseurs/` et produit des objets
   `MoyenneMatiere`. Cette logique ne dépend ni de Flutter ni de Firebase : elle
   peut être testée sans lancer l'application ni contacter le réseau.

4. **Un seul point d'entrée par source de données.** Les trois services
   encapsulent chacun exactement une technologie (Auth, Firestore,
   SharedPreferences). On sait immédiatement où chercher, et une modification de
   schéma ne se répercute qu'à un seul endroit.

**Pourquoi Riverpod plutôt qu'un `setState` global ?** Les providers sont
déclarés hors de tout widget : n'importe quel écran accède à l'état sans qu'on
ait à faire transiter les données de constructeur en constructeur. Riverpod gère
aussi nativement les trois états d'une donnée distante (`loading`, `error`,
`data`), ce qui évite les écrans blancs et les `null` non gérés pendant le
chargement.

---

## 5. L'identité visuelle

Le thème est **clair**, construit autour d'un registre naturel : feuille, bois,
papier recyclé, ciel. Ce choix privilégie la lisibilité, car l'application
affiche essentiellement des tableaux de notes et des horaires. Il adoucit aussi
un sujet, les résultats scolaires, qui peut être source de tension.

### 5.1 La palette

| Rôle | Nom Dart | Hex | Usage |
| --- | --- | --- | --- |
| Primaire | `vertFeuille` | `#2F6F4E` | Boutons, barre de navigation, accents |
| Foncé | `vertProfond` | `#1B4332` | Titres, textes forts |
| Clair | `vertTendre` | `#7FB069` | Badges, indicateurs positifs |
| Fond | `sable` | `#F7F4ED` | Fond de page, papier recyclé |
| Surface | `blancCasse` | `#FFFFFF` | Cartes, listes |
| Secondaire | `ecorce` | `#6B4F3A` | Brun bois, en-têtes de matière |
| Accent froid | `ciel` | `#8FB8CE` | Emploi du temps |
| Alerte | `terracotta` | `#C1663F` | Résultats en difficulté |
| Accent chaud | `miel` | `#D9A441` | Résultats limites |
| Neutre | `pierre` | `#8A8578` | Textes secondaires, séparateurs |

### 5.2 Le code couleur des notes

Aucun rouge vif n'est utilisé : les couleurs restent dans le registre naturel,
pour informer sans dramatiser.

| Note sur 20 | Couleur | Lecture |
| --- | --- | --- |
| 16 et plus | `vertProfond` | Très bon résultat |
| de 12 à 16 | `vertTendre` | Résultat satisfaisant |
| de 10 à 12 | `miel` | Résultat limite |
| moins de 10 | `terracotta` | Difficulté à accompagner |

### 5.3 Les principes d'interface

- **Material 3** activé, couleurs dérivées d'un `ColorScheme.fromSeed`.
- **Largeur maximale de 500 px**, afin que l'application conserve ses
  proportions mobiles lorsqu'elle tourne dans un navigateur large.
- **Cartes à coins arrondis** (rayon 12 à 16), ombres légères, respiration
  généreuse entre les blocs.
- **Aucun état non géré** : chaque écran distant traite explicitement le
  chargement, l'erreur et le cas « aucune donnée ».

---

## 6. Le modèle de données Firestore

| Collection | Champs |
| --- | --- |
| `utilisateurs` | `email`, `nom`, `prenom`, `dateInscription`, `enfants` (tableau d'identifiants) |
| `enfants` | `idParent`, `prenom`, `nom`, `classe`, `etablissement` |
| `notes` | `idEnfant`, `matiere`, `intitule`, `valeur`, `bareme`, `coefficient`, `date`, `appreciation` |
| `cours` | `idEnfant`, `matiere`, `jour` (1 pour lundi, 5 pour vendredi), `heureDebut`, `heureFin`, `salle`, `professeur` |

### Les données stockées localement

| Clé | Contenu | Utilité |
| --- | --- | --- |
| `enfantSelectionne` | Identifiant de l'enfant actif | L'application rouvre sur le bon enfant |
| `cacheNotes` | Dernières notes sérialisées en JSON | Consultation hors connexion |
| `dateDerniereSynchro` | Horodatage de la dernière lecture réussie | Affiché sur le tableau de bord |

---

## 7. Le plan des fonctionnalités

Une branche par fonctionnalité, fusionnée dans `develop` une fois terminée.

### Socle technique

| # | Branche | Contenu | Critère couvert |
| --- | --- | --- | --- |
| F1 | `feature/init-projet` | Création du projet, dépendances, arborescence, `theme_nature.dart`, `main.dart` | Architecture |
| F2 | `feature/config-firebase` | `flutterfire configure`, `firebase_options.dart`, portail d'authentification | Socle |
| F3 | `feature/modeles` | Les 5 modèles avec `depuisFirestore()` et `versFirestore()` | **POO** |
| F4 | `feature/services-donnees` | `ServiceFirestore` (flux temps réel) et providers Riverpod | **Firestore** |

### Fonctionnalités utilisateur

| # | Branche | Contenu | Critère couvert |
| --- | --- | --- | --- |
| F5 | `feature/authentification` | Inscription, connexion, validation des champs, erreurs traduites | **Firebase Auth** |
| F6 | `feature/peuplement` | Génération des données fictives : 2 enfants, 30 notes, 25 cours | Socle |
| F7 | `feature/stockage-local` | `ServiceStockageLocal` : enfant actif, cache des notes, date de synchro | **Stockage local** |
| F8 | `feature/selection-enfant` | Sélecteur d'enfant dans la barre supérieure, bascule instantanée | UI/UX |
| F9 | `feature/tableau-de-bord` | Moyenne générale, moyennes par matière, dernières notes | UI/UX |
| F10 | `feature/detail-matiere` | Détail de toutes les évaluations d'une matière | UI/UX |
| F11 | `feature/emploi-du-temps` | Cours du jour, navigation du lundi au vendredi, mise en avant du cours en cours | UI/UX |
| F12 | `feature/profil` | Informations du parent, enfants rattachés, déconnexion | UI/UX |

### Finitions

| # | Branche | Contenu |
| --- | --- | --- |
| F13 | `feature/finitions-ui` | États vides, indicateurs de chargement, tirer pour rafraîchir, erreurs réseau |
| F14 | `docs/readme` | Finalisation de ce document |

### Suivi d'avancement

- [x] F1 : initialisation du projet
- [x] F2 : configuration Firebase
- [x] F3 : modèles de données
- [x] F4 : services et providers
- [x] F5 : authentification
- [x] F6 : peuplement des données fictives
- [x] F7 : stockage local
- [x] F8 : sélection de l'enfant
- [x] F9 : tableau de bord
- [x] F10 : détail d'une matière
- [x] F11 : emploi du temps
- [x] F12 : profil
- [ ] F13 : finitions de l'interface
- [ ] F14 : documentation

---

## 8. Les conventions de travail

### Les branches

| Branche | Rôle |
| --- | --- |
| `main` | Version de rendu. Aucun développement direct. |
| `develop` | Branche d'intégration. Toutes les fonctionnalités y sont fusionnées. |
| `feature/<domaine>` | Une fonctionnalité. Exemple : `feature/emploi-du-temps` |
| `fix/<domaine>` | Une correction. Exemple : `fix/tri-des-cours` |
| `docs/<sujet>` | Documentation. Exemple : `docs/readme` |

Les noms sont en **kebab-case**, sans accent.

### Le flux de travail

```
develop  →  feature/xxx  →  commits  →  merge --no-ff dans develop
                                        (à la fin)  develop  →  main
```

L'option `--no-ff` conserve un commit de fusion par fonctionnalité : l'historique
montre clairement le découpage du travail plutôt qu'une suite linéaire de commits.

### Les commits

Format **Conventional Commits**, description en français, à l'impératif, en
minuscules, sans point final :

```
<type>(<portée>): <description>
```

| Type | Usage |
| --- | --- |
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction d'un défaut |
| `refactor` | Réorganisation sans changement de comportement |
| `style` | Mise en forme, interface uniquement |
| `docs` | Documentation |
| `chore` | Configuration, dépendances |
| `test` | Ajout ou modification de tests |

**Portées utilisées :** `auth`, `modeles`, `firestore`, `stockage`, `notes`,
`edt`, `enfants`, `ui`, `theme`, `config`

**Exemples :**

```
feat(modeles): creer le modele Note avec conversion sur 20
feat(auth): ajouter la page de connexion et d inscription
feat(edt): afficher les cours du jour selectionne
fix(edt): corriger le tri des cours par heure de debut
style(theme): appliquer la palette nature aux cartes de note
docs(readme): rediger la justification de l architecture
```

### Les conventions de rédaction

- **Aucun tiret cadratin ni demi-cadratin** dans le code, les commentaires, les
  commits ou la documentation. On utilise les deux-points, la virgule, les
  parenthèses ou une phrase séparée.
- **Français partout** : noms de fichiers, de classes, de variables, de méthodes
  et de commentaires.
- **Fichiers en `snake_case`**, classes en `PascalCase`, variables et méthodes en
  `camelCase`.
- **Commentaires de documentation** avec `///` au-dessus de chaque classe et de
  chaque méthode publique.

---

## 9. Installation

```bash
# 1. Récupérer les dépendances
flutter pub get

# 2. Rattacher le projet à Firebase (une seule fois)
flutterfire configure

# 3. Lancer l'application
flutter run
```

**Prérequis côté console Firebase :**

1. Créer un projet sur [console.firebase.google.com](https://console.firebase.google.com)
2. Activer **Authentication**, puis le fournisseur **Email / Mot de passe**
3. Créer la base **Cloud Firestore**

Au premier lancement, créer un compte puis utiliser le bouton « Générer mes
données de démo » pour remplir la base avec les enfants, les notes et les cours
fictifs.

---

## 10. Les difficultés rencontrées

_Cette section est complétée au fil du développement._

### Les index composites de Firestore

Associer un filtre `where` et un tri `orderBy` portant sur deux champs
différents oblige Firestore à disposer d'un **index composite**, créé à la main
dans la console. Sans lui, la requête ne renvoie pas de résultat vide : elle
échoue à l'exécution. Trier les notes par date tout en filtrant sur l'enfant
aurait donc imposé cette manipulation à toute personne clonant le dépôt.

**Contournement :** les requêtes filtrent côté serveur et **trient côté Dart**,
dans `ServiceFirestore`. Le volume de données d'un enfant se compte en dizaines
de documents, le coût du tri en mémoire est négligeable, et le projet démarre
sans aucune configuration supplémentaire dans la console.

### Le passage à Riverpod 3

Depuis la version 3, **tous les providers sont automatiquement supprimés dès
qu'ils n'ont plus d'auditeur**. Les premiers tests des providers expiraient au
bout de trente secondes : le flux des enfants était fermé avant même d'avoir
émis sa première valeur, et l'attente ne se terminait jamais.

**Contournement :** ouvrir un abonnement avec `container.listen` avant de lire
la valeur dans les tests. Dans l'application, ce rôle est tenu naturellement par
les widgets qui observent les providers, le comportement par défaut n'y pose
donc aucun problème.

Autre conséquence du passage à la version 3 : `StateProvider` est passé dans les
API héritées. L'état modifiable est donc porté par des classes `Notifier`
(`SelectionEnfant`, `JourSelectionne`), ce qui présente l'avantage de regrouper
l'état et les méthodes qui le modifient dans une même classe.
