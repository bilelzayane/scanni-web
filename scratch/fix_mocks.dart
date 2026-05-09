import 'dart:io';

void main() {
  final files = [
    'lib/presentation/features/history/history_screen_mock.dart',
    'lib/presentation/features/home/home_screen_mock.dart',
    'lib/presentation/features/account/profile_screen_mock.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      print('Not found: $path');
      continue;
    }
    
    var content = file.readAsStringSync();
    
    content = content.replaceAllMapped(
      RegExp(r"(name|genericName|description|unit|factContent|legalReference):\s*['\x22]([^'\x22]*)['\x22]"),
      (match) {
        final field = match.group(1);
        final val = match.group(2);
        return "$field: const LocalizedText(en: '$val', fr: '$val', ar: '$val', arTn: '$val')";
      }
    );
    
    if (content.contains('LocalizedText') && !content.contains('localized_text.dart')) {
      content = "import '../../../domain/models/localized_text.dart';\n" + content;
    }
    
    file.writeAsStringSync(content);
    print('Updated $path');
  }
}
