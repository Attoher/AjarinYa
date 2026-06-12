// ignore_for_file: avoid_print
import 'dart:io';
void main() {
  final f = File('lib/views/answer_question_screen.dart');
  f.writeAsStringSync(f.readAsStringSync().replaceAll('      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),\n', ''));
  print('Fixed.');
}
