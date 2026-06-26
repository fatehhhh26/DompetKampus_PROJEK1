import 'package:dompet_kampus/services/receipt_ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = ReceiptOcrService();

  test('parses store name, date, items, total, and food category', () {
    const text = '''
WARUNG MAHASISWA
Jl. Kampus No 10
Tanggal 24/06/2026
Nasi Ayam 18.000
Es Teh 5.000
Subtotal 23.000
Total 23.000
Tunai 25.000
''';

    final receipt = service.parseReceipt(text);

    expect(receipt.storeName, 'Warung Mahasiswa');
    expect(receipt.transactionDate, DateTime(2026, 6, 24));
    expect(receipt.totalAmount, 23000);
    expect(receipt.category, 'Makanan');
    expect(receipt.items.map((item) => item.name), contains('Nasi Ayam'));
    expect(receipt.items.map((item) => item.name), contains('Es Teh'));
  });

  test('infers transport category from receipt text', () {
    const text = '''
SPBU 34.12345
2026-06-20
Pertalite 50.000
Total 50.000
''';

    final receipt = service.parseReceipt(text);

    expect(receipt.transactionDate, DateTime(2026, 6, 20));
    expect(receipt.category, 'Transportasi');
    expect(receipt.totalAmount, 50000);
  });

  test('infers print task category from receipt text', () {
    const text = '''
FOTOCOPY KAMPUS
24 Juni 2026
Print Tugas 12.000
Jilid 8.000
Total 20.000
''';

    final receipt = service.parseReceipt(text);

    expect(receipt.storeName, 'Fotocopy Kampus');
    expect(receipt.transactionDate, DateTime(2026, 6, 24));
    expect(receipt.category, 'Print/Tugas');
    expect(receipt.items.length, 2);
    expect(receipt.totalAmount, 20000);
  });
}
