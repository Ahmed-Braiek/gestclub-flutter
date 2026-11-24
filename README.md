# Championnat Pro — Flutter + SQLite

Application Flutter de gestion de clubs et joueurs, en français, avec stockage **local et hors ligne**.

## Fonctionnalités
- Drawer / barre latérale adaptative selon la largeur d'écran.
- CRUD clubs et joueurs, photo, date de naissance et numéro de téléphone.
- Liste des joueurs par club, recherche globale nom / prénom / téléphone / club.
- Appel téléphonique (`tel:`) sur appareil compatible.
- **3 ajouts** : tableau de bord et statistiques, favoris, export CSV (séparateur `;`, encodage UTF-8 BOM pour Excel).
- Quelques données de démonstration au **premier lancement uniquement**.
- Protection d'intégrité : impossible de supprimer un club qui contient des joueurs ; transférer ou supprimer ces joueurs auparavant.

## Installation (Windows / Android)
Avoir Flutter (version récente, Dart >= 3.10), Android SDK et Android Studio ou VS Code.

Ce dossier contient les sources. Générez les fichiers plateforme Flutter manquants :

```powershell
git clone https://github.com/Ahmed-Braiek/gestclub-flutter.git
cd gestclub-flutter
flutter create --platforms=android,windows .
flutter pub get
flutter devices
flutter run
```

Pour la première démonstration, **préférez un téléphone Android** connecté avec débogage USB : les appels et la galerie photo sont plus naturels sur téléphone.

Pour Windows Desktop : activer **Developer Mode** dans Windows si Flutter le demande, installer les outils C++ de Visual Studio si absents, puis `flutter run -d windows`.

SQLite **ne nécessite aucun serveur**. Le fichier `championnat.db` est créé automatiquement dans le dossier Documents de l'application au premier démarrage. Sur Windows `sqflite_common_ffi` est utilisé, sur Android `sqflite`. Chrome/web n'est pas ciblé.

## Architecture
- `Club`, `Player` : modèles.
- `Store` : tables SQLite, clés étrangères et CRUD.
- `HomeScreen` : navigation, dashboard, recherche, filtres, export et actions.
- `PlayerDialog` : formulaire validé et sélection de photo.

## Notes de démonstration
1. Ouvrir le tableau de bord et examiner les effectifs.
2. Ajouter un club et un joueur avec photo.
3. Rechercher le joueur et changer son club.
4. Marquer favori ; vérifier l'écran Favoris.
5. Exporter CSV et ouvrir le fichier dans Excel.
6. Appeler sur téléphone physique (le simulateur / Windows peut ne pas disposer d'application de téléphonie).
7. Fermer / rouvrir l'application pour confirmer la persistance SQLite.

Les numéros fournis dans les données de démonstration sont **fictifs**, ne pas les appeler.

## Limites
Le projet n'a pas été compilé dans l'environnement de génération (Flutter SDK absent). Lancer `flutter analyze` et `flutter run` localement après `flutter pub get`. Pas de synchronisation cloud ni de multi-utilisateur.
