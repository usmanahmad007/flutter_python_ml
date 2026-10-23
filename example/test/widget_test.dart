import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_python_ml_example/main.dart';

void main() {
  testWidgets('Renders FlutterPythonMlApp home screen and tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FlutterPythonMlApp());

    expect(find.text('Flutter Python ML'), findsOneWidget);
    expect(find.text('Iris Classifier'), findsOneWidget);
    expect(find.text('House Regression'), findsOneWidget);
    expect(find.text('NLP Sentiment'), findsOneWidget);
    expect(find.text('Python Console'), findsOneWidget);
  });
}
