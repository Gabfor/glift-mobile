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

L'icône source est stockée sous forme vectorielle pour éviter les binaires dans Git : `assets/images/app_icon.svg`.

1. Mettez à jour le fichier SVG si nécessaire (format 1024×1024 conseillé).
2. Installez les dépendances puis générez les icônes locales :

   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

Les icônes générées sont ignorées par Git (`.gitignore`) afin d'éviter les diffs binaires dans les demandes d'extraction. Pensez à lancer la commande après chaque mise à jour du SVG pour que toutes les plateformes disposent de la bonne icône.
