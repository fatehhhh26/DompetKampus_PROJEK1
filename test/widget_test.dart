import 'package:dompet_kampus/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DompetKampus shows splash screen', (tester) async {
    await tester.pumpWidget(const DompetKampusApp());

    expect(find.text('DompetKampus'), findsOneWidget);
    expect(find.text('Catatan keuangan mahasiswa'), findsOneWidget);
  });
}
