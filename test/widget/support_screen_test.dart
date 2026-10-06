import 'package:calc_recisao/presentation/screens/support/support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('deve mostrar o e-mail de suporte e não o card de FAQ', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: SupportScreen()));
    await tester.pumpAndSettle();

    expect(find.text('caioguimaraes12@outlook.com'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Perguntas Frequentes'), findsNothing);
    expect(find.text('Encontre respostas rápidas'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
