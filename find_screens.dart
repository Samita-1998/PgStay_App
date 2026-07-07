import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true);
  for (var file in files) {
    if (file is File && file.path.endsWith('screen.dart')) {
      print(file.path);
    }
  }
}
