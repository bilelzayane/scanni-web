import 'dart:io';

void main() {
  // Fix history_screen_mock.dart
  final path1 = 'lib/presentation/features/history/history_screen_mock.dart';
  var content1 = File(path1).readAsStringSync();
  content1 = content1.replaceAll("name: const LocalizedText(en: 'Tunisian Harissa', fr: 'Tunisian Harissa', ar: 'Tunisian Harissa', arTn: 'Tunisian Harissa'),", "name: 'Tunisian Harissa',");
  content1 = content1.replaceAll("name: const LocalizedText(en: 'Strawberry Yogurt', fr: 'Strawberry Yogurt', ar: 'Strawberry Yogurt', arTn: 'Strawberry Yogurt'),", "name: 'Strawberry Yogurt',");
  File(path1).writeAsStringSync(content1);

  // Fix scan_repository.dart
  final path2 = 'lib/data/repositories/scan_repository.dart';
  var content2 = File(path2).readAsStringSync();
  
  // Replace all the fields that should be LocalizedText inside scan_repository.dart
  final fieldsToReplace = ['genericName', 'description', 'unit', 'factContent', 'legalReference'];
  for (var field in fieldsToReplace) {
    content2 = content2.replaceAllMapped(
      RegExp('$field:\\s*[\'"]([^\'"]*)[\'"]'),
      (m) => "$field: const LocalizedText(en: '${m.group(1)}', fr: '${m.group(1)}', ar: '${m.group(1)}', arTn: '${m.group(1)}')",
    );
  }
  
  // name inside ScientificLexicon
  content2 = content2.replaceAllMapped(
    RegExp(r"(name):\s*['\x22](Milk|Sugar|E120 \(Carmin\)|Wheat Flour|Palm Oil|Cocoa Flavor|Sodium Chloride|Anti-caking Agent|Cocoa|Stabilizers|Flavor Enhancer|Vitamin D Additive|Chili Pepper|Garlic|Olive Oil|Caraway Seeds|Apple|Natural Fructose|Dietary Fiber)['\x22]"),
    (m) => "${m.group(1)}: const LocalizedText(en: '${m.group(2)}', fr: '${m.group(2)}', ar: '${m.group(2)}', arTn: '${m.group(2)}')",
  );
  
  if (!content2.contains('localized_text.dart')) {
    content2 = "import '../../domain/models/localized_text.dart';\n" + content2;
  }
  
  File(path2).writeAsStringSync(content2);
}
