import 'package:calc_recisao/presentation/screens/about/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('deve descrever coleta com consentimento na política de privacidade', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Se você aceitar'), findsOneWidget);
    expect(find.textContaining('não são personalizados até você aceitar'), findsOneWidget);
    expect(find.textContaining('não coleta dados pessoais'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
