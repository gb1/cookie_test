import 'package:boats/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App boots to the splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(BoatsApp(prefs: prefs));

    expect(find.text('Cork Harbour Boats'), findsWidgets);
  });
}
