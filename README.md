# Glift

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Mettre à jour l'icône de l'application

1. Préparez une image PNG carrée (au moins 1024×1024) et placez-la par exemple dans `assets/images/app_icon.png`. Si vous partez du logo vectoriel existant (`assets/images/logo_app.svg`), exportez-le en PNG depuis votre outil de design.
2. Ajoutez la dépendance de génération d'icônes au fichier `pubspec.yaml` :

   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.14.1

   flutter_launcher_icons:
     image_path: "assets/images/app_icon.png"
     android: true
     ios: true
     web: true
     windows: true
     macos: true
     linux: true
   ```

3. Mettez à jour les dépendances puis générez les icônes :

   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

La commande remplace les icônes sur toutes les plateformes (Android, iOS, Web et desktop). Pensez à committer le nouveau PNG source ainsi que les fichiers générés.
