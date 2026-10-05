import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deve não existir código em test/golden que escreva em cases/', () {
    final writers = RegExp(r'writeAsString|writeAsBytes|openWrite|\.createSync|\.create\(');
    final offenders = [
      for (final f in Directory('test/golden').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') &&
            !f.path.endsWith('no_generator_test.dart') &&
            writers.hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(offenders, isEmpty);
  });
}
