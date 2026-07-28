# CinéFlix - Mise en route

Le code est complet. Il ne manque que **tes** clés Firebase, que je ne peux pas
générer à ta place (ça passe par ton compte Google).

Compte 15 minutes la première fois.

---

## Étape 0 - Activer le Mode Développeur Windows (obligatoire)

Les plugins Firebase contiennent du code natif, et Flutter a besoin de créer des
liens symboliques. Sans ça, `flutter run` s'arrête net.

```
start ms-settings:developers
```

Bascule **« Mode développeur »** sur *Activé*, puis accepte l'avertissement.

Vérifie ensuite :

```
cd C:\Users\Lenovo\Desktop\Git\Dart-Flutter\evaluation-finale\cineflix
flutter pub get
```

Tu ne dois plus voir le message *« Building with plugins requires symlink support »*.

---

## Étape 1 - Installer les outils en ligne de commande

```
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

Puis connecte-toi (ça ouvre une page dans ton navigateur) :

```
firebase login
```

> Si `flutterfire` n'est pas reconnu ensuite, ajoute
> `C:\Users\Lenovo\AppData\Local\Pub\Cache\bin` à ton `PATH`.

---

## Étape 2 - Créer le projet Firebase

Sur [console.firebase.google.com](https://console.firebase.google.com) :

1. **Ajouter un projet** → nomme-le par exemple `cineflix-ipssi`
2. Google Analytics : tu peux le désactiver, il ne sert à rien ici

### Activer l'authentification

**Build → Authentication → Get started**, puis dans l'onglet **Sign-in method**,
active **Email/Password** (le premier interrupteur uniquement, pas le lien magique).

### Créer la base de données

**Build → Firestore Database → Create database**

- Emplacement : `eur3 (europe-west)`
- Démarre en **mode test**

---

## Étape 3 - Sécuriser la base (important pour la note)

Le mode test laisse la base ouverte à tout le monde et expire au bout de 30 jours.
Va dans **Firestore Database → Règles** et remplace tout par ceci :

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Le catalogue n'est lisible que par un utilisateur connecté.
    match /films/{filmId} {
      allow read, write: if request.auth != null;
    }

    // Chaque utilisateur n'accède qu'à son propre document.
    match /utilisateurs/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

**Publier.**

Ces règles prouvent côté serveur que « le catalogue est inaccessible sans être
connecté » - pas seulement côté interface.

---

## Étape 4 - Relier le projet Flutter à Firebase

Depuis le dossier du projet :

```
cd C:\Users\Lenovo\Desktop\Git\Dart-Flutter\evaluation-finale\cineflix
flutterfire configure
```

- Choisis le projet `cineflix-ipssi`
- Coche au minimum **web** (et **android** si tu veux le téléphone plus tard)

L'outil réécrit `lib/firebase_options.dart` avec tes vraies clés. À partir de là,
l'écran « Configuration Firebase requise » disparaît tout seul.

---

## Étape 5 - Lancer

```
flutter run -d chrome
```

1. Clique sur **« Pas encore de compte ? - S'inscrire »**
2. Crée un compte (mot de passe : 6 caractères minimum)
3. Le catalogue s'ouvre, vide, avec un bouton **« Peupler la base »**
4. Clique dessus : 8 films partent dans Firestore, la grille se remplit toute seule

Va voir dans la console Firebase : la collection `films` s'est créée.

---

## Structure de la base

```
films/{idAuto}
  titre        : string
  genre        : string
  ageMinimum   : number
  synopsis     : string
  imageUrl     : string

utilisateurs/{uid}
  email           : string
  dateInscription : timestamp
  favoris         : array<string>   (les identifiants des films)
```

Le catalogue est branché sur un flux temps réel : si tu modifies le titre d'un
film **directement dans la console Firebase**, il change dans l'application sans
recharger la page. C'est la meilleure démonstration que rien n'est codé en dur.

---

## Bon à savoir

- **Les affiches** utilisent `picsum.photos` (images libres, CORS ouvert). Comme
  les URL sont stockées en base, tu peux les remplacer par de vraies affiches en
  éditant simplement le champ `imageUrl` dans la console - aucun code à toucher.
- **`lib/outils/peupler_base.dart`** ne sert qu'à remplir la base au premier
  lancement. Une fois le catalogue en place, tu peux supprimer ce fichier et son
  import dans `page_catalogue.dart`.
- **Tests** : `flutter test` vérifie que la carte intelligente change bien de
  présentation selon la largeur disponible.
