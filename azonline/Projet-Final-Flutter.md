.IPSSI

# Projet Final Flutter - Cahier des Charges

**Intervenant :** Théo Delaporte

**Module :** Dart & Flutter

## 1. Le Concept

L'objectif de ce projet est de vous permettre de mobiliser vos compétences autour d'une thématique qui suscite votre intérêt. Le choix du sujet est par conséquent entièrement libre.

La seule exigence requise est que l'application présente une véritable proposition de valeur ou d'utilité. À ce titre, le développement d'un jeu mobile est tout à fait autorisé, la dimension ludique répondant parfaitement à ce critère.

Veillez cependant à délimiter rigoureusement le périmètre de votre projet : prenez en considération les délais impartis afin d'éviter toute complexité technique démesurée au regard du temps alloué.

## 2. Les Critères Techniques Obligatoires

Pour valider ce module, votre projet devra impérativement intégrer les éléments techniques suivants :

- **Architecture structurée :** Vous devez respecter les principes de **Clean Architecture** (séparation claire entre l'interface utilisateur, la logique métier et l'accès aux données). Un code où tout est mélangé dans le même fichier sera pénalisé.
- **Programmation Orientée Objet (POO) :** Le code doit être proprement structuré avec des classes. Les données provenant de l'extérieur (comme Firebase) ne doivent pas être manipulées sous forme brute. Vous devez impérativement créer vos modèles de données et utiliser des constructeurs dédiés pour transformer vos documents en objets Dart.
- **Authentification :** Mise en place d'un système d'inscription et de connexion fonctionnel via Firebase Auth.
- **Base de données distante :** Utilisation de Cloud Firestore avec la création et la manipulation d'au moins une collection de données.
- **Stockage local :** Sauvegarde de certaines données directement sur le téléphone (via SharedPreferences, Hive, ou autre solution abordée lors de la séance 7).
- **Interface et Expérience (UI/UX) :** Un effort est attendu sur le design et la fluidité de l'application. Vous êtes des développeurs et non des designers experts, mais l'application doit être propre, ergonomique et éviter les erreurs basiques.

## 3. Modalités de Travail

- **Taille des groupes :** 2 à 3 personnes maximum par équipe.

---

.IPSSI

- **Collaboration Git** : Le travail doit être collaboratif. Les commits sur le dépôt de code doivent être **équilibrés** entre chaque membre du groupe pour prouver l'implication de tous.

## 4. Les Livrables

Le rendu final s'effectuera en m'envoyant un message privé sur **Teams** (1 message par groupe) contenant le lien de votre dépôt GitHub. **Il est à rendre impérativement pour le 05/08 23h59 maximum.**

Votre dépôt GitHub devra **obligatoirement** contenir un fichier **README.md** propre et structuré, incluant :

- L'objectif principal du projet (à quoi sert votre application / jeu ?).
- La composition de votre groupe (Noms et Prénoms).
- La stack technique mise en place (Packages Flutter utilisés, etc.).
- **La justification de l'architecture** : Expliquez quelle architecture vous avez choisie de mettre en place et pourquoi.
- Les éventuelles difficultés rencontrées durant le développement et comment vous les avez contournées.