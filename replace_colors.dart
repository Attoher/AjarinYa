import 'dart:io';

void main() {
  final files = [
    'lib/views/question_forum_screen.dart',
    'lib/views/answer_question_screen.dart'
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    if (!content.contains('import \'package:ajarin_ya/theme/app_theme.dart\';')) {
      content = content.replaceFirst('import \'package:flutter/material.dart\';', 
          'import \'package:flutter/material.dart\';\nimport \'package:ajarin_ya/theme/app_theme.dart\';');
    }

    content = content.replaceAll('Colors.orange.shade800', 'AppTheme.primaryColor');
    content = content.replaceAll('Colors.orange.shade900', 'AppTheme.primaryDark');
    content = content.replaceAll('Colors.orange.shade100', 'AppTheme.primaryColor.withOpacity(0.1)');
    content = content.replaceAll('Colors.orange.shade50', 'AppTheme.primaryColor.withOpacity(0.05)');
    content = content.replaceAll('Colors.orange.shade200', 'AppTheme.primaryColor.withOpacity(0.2)');
    content = content.replaceAll('backgroundColor: Colors.grey.shade50,', 'backgroundColor: AppTheme.backgroundColor,');
    
    final targetCardStr = '''      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,''';
      
    final replacementCardStr = '''      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shadowColor: AppTheme.primaryColor.withOpacity(0.1),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      borderOnForeground: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),''';
      
    content = content.replaceAll(targetCardStr, replacementCardStr);
    
    file.writeAsStringSync(content);
  }
  print('Done applying AppTheme colors to forum screens.');
}
