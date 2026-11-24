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
flutter create --platforms=android,windows,web .
flutter pub get
flutter devices
flutter run
```

Pour la première démonstration, **préférez un téléphone Android** connecté avec débogage USB : les appels et la galerie photo sont plus naturels sur téléphone.

Pour Windows Desktop : activer **Developer Mode** dans Windows si Flutter le demande, installer les outils C++ de Visual Studio si absents, puis `flutter run -d windows`.

SQLite **ne nécessite aucun serveur**. Le fichier `championnat.db` est créé automatiquement dans le dossier Documents de l'application au premier démarrage. Sur Windows `sqflite_common_ffi` est utilisé, sur Android `sqflite`, sur Chrome SQLite WebAssembly + IndexedDB.

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

## Tests et livraison continue
Le dépôt contient `test/models_test.dart` et `test/sqlite_constraints_test.dart`. Les validations automatiques exécutent :

```powershell
flutter create --platforms=android,windows --project-name championnat_pro .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Dans GitHub, ouvrir **Actions → Flutter CI** pour consulter le résultat. Le fichier `app-debug.apk` sera téléchargeable dans **Artifacts** après un job réussi. L'APK est une version de démonstration (debug), pas une publication sur Play Store.

### Contrôles manuels indispensables
- [ ] Sur Android, ajout / modification / suppression de clubs et joueurs, avec validation des formulaires
- [ ] Recherche par nom, prénom, numéro et club ; filtre des joueurs par club
- [ ] Ajout d'une photo depuis la galerie, puis relancement de l'application
- [ ] Appel : ouvre le composeur téléphonique sur un appareil physique
- [ ] Favoris conservés après fermeture et réouverture
- [ ] CSV exporté et lisible dans Excel
- [ ] Navigation vérifiée sur téléphone étroit et fenêtre Windows large
- [ ] Suppression d'un club peuplé refusée ; transfert de ses joueurs possible

### Points à retenir
La base et les photos sont **stockées sur l'appareil**. Elles ne sont pas synchronisées entre Windows et Android. Les données de démonstration sont insérées uniquement lors de la création initiale de la base. L'application est conçue pour Android et Windows, et non pour Chrome / Flutter Web.

## Lancer sur Chrome (SQLite persistante dans le navigateur)
Depuis PowerShell, dans le dossier du projet :

```powershell
flutter create --platforms=android,windows,web --project-name championnat_pro .
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter run -d chrome --web-port 8080
```

Le setup génère `web/sqlite3.wasm` et `web/sqflite_sw.js`, nécessaires au navigateur. La base SQLite est persistée dans IndexedDB pour **la même origine** (ici `localhost:8080`). Ne changez pas de port à chaque exécution si vous voulez retrouver les mêmes données. Pour livrer le site : `flutter build web` après le setup.

> Chrome ne peut pas ouvrir la base native Android/Windows ; chaque plateforme a sa propre base locale. Photos stockées dans SQLite en Base64 pour fonctionner sur toutes les plateformes. L'appel téléphonique dépend de l'appareil ; il n'est généralement pas disponible dans Chrome sur PC. Les fichiers de galerie et le partage CSV utilisent des interfaces compatibles Web.

## Animations et design
- Transition fondu + léger glissement entre les écrans (320 ms).
- Compteurs de statistiques animés (720 ms).
- Apparition progressive des cartes clubs/joueurs.
- Étoiles favorites animées au changement d'état.
- Navigation adaptative : drawer étroit / sidebar large.


## Version 2: images, statistiques et calendrier
- CRUD Clubs : ajouter/remplacer le logo via un lien HTTP(S) ou importer un fichier image.
- CRUD Joueurs : photos via URL/fichier ; buts, passes décisives, apparitions, cartons jaunes.
- Nouveau menu **Statistiques** : tableau des meilleurs buteurs, graphique des buts, synthèse des performances.
- Nouveau menu **Matchs** : créer, modifier ou supprimer une rencontre avec deux clubs, date, heure, lieu, statut, score lorsque terminée.
- La migration SQLite de version 1 vers version 2 se fait automatiquement, **sans supprimer la base**. La suppression d'un club lié à des joueurs ou rencontres reste bloquée.
- Les images importées sont compressées et stockées en Base64 dans SQLite, max. 1,5 Mo chacune. Les URL nécessitent un accès Internet, et sur Chrome certains hôtes peuvent refuser le chargement des images.
- **Attention : DEMO uniquement.** Les clubs sont réels mais les joueurs, statistiques et matchs sont fictifs. Les portraits de Random User illustrent des profils de démonstration et ne représentent pas les personnes nommées.
- Les logos du Club Africain, l'ancien emblème de l'Espérance et le écusson historique de l'Étoile du Sahel sont chargés depuis Wikimedia Commons ; ils ne sont pas tous les écussons actuels.

### Mise à jour de votre projet déjà installé
Dans le dossier existant :
```powershell
git pull origin main
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter run -d chrome --web-port 8080
```

### Sources des illustrations de démonstration
- Club Africain : https://commons.wikimedia.org/wiki/File:Club_africain.logo.png
- Espérance (historique) : https://commons.wikimedia.org/wiki/File:Logo_1987.jpg
- Étoile du Sahel (écusson historique) : https://commons.wikimedia.org/wiki/File:Logo_historique_de_l%27Etoile_Sportive_du_Sahel_-_1925.jpg
- Portraits fictifs : https://randomuser.me/

## Interface modernisée
Design system partagé : `lib/design_system.dart` (`AppTheme`, `AppPalette`, `SectionTitle`, `EmptyPanel`, `CrudActions`, `StatusPill`, `StatPanel`, `PressableCard`).

**Palette :** bleu nuit `#101C34`, bleu action `#315BDB`, fond `#F4F7FC`, vert `#099879`, rouge suppression `#D84255`, or favori `#E6A13D`.

**UX :** navigation latérale / drawer responsive, accueil avec actions rapides et prochains matchs, cartes statistiques, clubs avec logos et accès aux effectifs, joueurs avec recherche, filtres et actions lisibles, matchs avec scores, badges et actions CRUD. Les formulaires regroupent les informations et les suppressions demandent confirmation.

Test sur Chrome après mise à jour : `git pull origin main`, puis `flutter pub get`, `dart run sqflite_common_ffi_web:setup`, `flutter run -d chrome --web-port 8080`.
