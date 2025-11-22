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

1. Préparez une image PNG carrée (au moins 1024×1024) et convertissez-la en texte pour éviter d'ajouter des binaires au dépôt :

   ```bash
   base64 /chemin/vers/mon_icon.png > assets/images/app_icon.b64.txt
   ```

   Si vous partez du logo vectoriel existant (`assets/images/logo_app.svg`), exportez-le en PNG avant de l'encoder. Le fichier texte reste traçable dans Git alors que les variantes générées sont ignorées.
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

3. Mettez à jour les dépendances puis générez les icônes (dans un dossier ignoré ou directement dans les ressources locales) :

   ```bash
   flutter pub get
   python tool/generate_icons.py --export-dir build/generated_icons
   # ou, si vous voulez remplir les répertoires de plateforme locaux sans les committer :
   python tool/generate_icons.py
   ```

La commande remplace les icônes sur toutes les plateformes (Android, iOS, Web et desktop). Seul le fichier texte `assets/images/app_icon.b64.txt` doit être committé : les ressources générées sont listées dans `.gitignore` pour éviter les diffs binaires dans les demandes d'extraction. Joignez les artefacts exportés au besoin lors de vos revues.
