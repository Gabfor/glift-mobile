import 'dart:convert';
import 'dart:io';

/// Generates the platform launcher icons from the Base64 source asset.
///
/// The source image lives in [assets/images/app_icon.b64.txt] to keep binary
/// artifacts out of pull requests. Running this script will:
/// 1. Decode the Base64 string into [assets/images/app_icon.png].
/// 2. Invoke `flutter pub run flutter_launcher_icons:main` to regenerate the
///    platform-specific launcher assets.
Future<void> main() async {
  final sourcePath = 'assets/images/app_icon.b64.txt';
  final pngPath = 'assets/images/app_icon.png';

  final sourceFile = File(sourcePath);
  if (!await sourceFile.exists()) {
    stderr.writeln('Missing icon source: $sourcePath');
    exitCode = 1;
    return;
  }

  stdout.writeln('Decoding $sourcePath -> $pngPath');
  final base64Data = await sourceFile.readAsString();
  final bytes = base64.decode(base64Data.replaceAll(RegExp(r'\s+'), ''));
  await File(pngPath).writeAsBytes(bytes);

  stdout.writeln('Running flutter_launcher_icons...');
  final result = await Process.run(
    'flutter',
    ['pub', 'run', 'flutter_launcher_icons:main'],
    runInShell: true,
  );

  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode != 0) {
    stderr.writeln('flutter_launcher_icons failed with exit code ${result.exitCode}');
    exitCode = result.exitCode;
  } else {
    stdout.writeln('Launcher icons generated successfully.');
  }
}
