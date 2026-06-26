import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptItem {
  const ReceiptItem({required this.name, required this.amount});

  final String name;
  final double amount;
}

class ParsedReceipt {
  const ParsedReceipt({
    required this.rawText,
    required this.storeName,
    required this.transactionDate,
    required this.items,
    required this.totalAmount,
    required this.category,
    required this.amountCandidates,
  });

  final String rawText;
  final String? storeName;
  final DateTime? transactionDate;
  final List<ReceiptItem> items;
  final double? totalAmount;
  final String category;
  final List<double> amountCandidates;

  String get transactionTitle {
    final name = storeName?.trim();
    if (name == null || name.isEmpty) return 'Belanja dari Struk';
    return 'Belanja di $name';
  }

  String get note {
    final buffer = StringBuffer('Input dari scan struk');
    final name = storeName?.trim();
    if (name != null && name.isNotEmpty) {
      buffer.write('\nToko: $name');
    }
    if (items.isNotEmpty) {
      buffer.write('\nItem:');
      for (final item in items.take(8)) {
        buffer.write('\n- ${item.name} (${_formatAmount(item.amount)})');
      }
      if (items.length > 8) {
        buffer.write('\n- ${items.length - 8} item lainnya');
      }
    }
    return buffer.toString();
  }

  static String _formatAmount(double amount) {
    return amount.toStringAsFixed(0);
  }
}

class ReceiptOcrService {
  ReceiptOcrService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<XFile?> pickImageFromCamera() {
    return _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );
  }

  Future<XFile?> pickImageFromGallery() {
    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
  }

  Future<String> recognizeTextFromImage(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (_) {
      throw Exception('Gagal membaca struk. Coba foto yang lebih jelas.');
    } finally {
      await textRecognizer.close();
    }
  }

  ParsedReceipt parseReceipt(String ocrText) {
    return ParsedReceipt(
      rawText: ocrText,
      storeName: extractStoreName(ocrText),
      transactionDate: extractTransactionDate(ocrText),
      items: extractItems(ocrText),
      totalAmount: extractBestTotalAmount(ocrText),
      category: inferCategory(ocrText),
      amountCandidates: extractAmountCandidates(ocrText),
    );
  }

  List<double> extractAmountCandidates(String ocrText) {
    final amounts = <double>{};
    final normalizedText = ocrText.toLowerCase();
    final amountPattern = RegExp(
      r'(?:rp\s*)?(\d{1,3}(?:[.,]\d{3})+|\d{4,9})(?:,\d{2})?',
      caseSensitive: false,
    );

    for (final match in amountPattern.allMatches(normalizedText)) {
      final amount = _parseAmount(match.group(0) ?? '');
      if (_isReasonableAmount(amount)) {
        amounts.add(amount);
      }
    }

    final candidates = amounts.toList()..sort((a, b) => b.compareTo(a));
    return candidates;
  }

  String? extractStoreName(String ocrText) {
    final lines = _cleanLines(ocrText);
    for (final line in lines.take(8)) {
      final lowerLine = line.toLowerCase();
      if (_looksLikeReceiptNoise(lowerLine)) continue;
      if (_largestAmountInText(line) != null) continue;
      if (RegExp(r'\d{2,}').hasMatch(line)) continue;
      return _toTitleCase(line);
    }

    return null;
  }

  DateTime? extractTransactionDate(String ocrText) {
    final lines = _cleanLines(ocrText);
    for (final line in lines) {
      final date = _parseDateFromText(line);
      if (date != null) return date;
    }

    return null;
  }

  List<ReceiptItem> extractItems(String ocrText) {
    final items = <ReceiptItem>[];
    final lines = _cleanLines(ocrText);

    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (_looksLikeReceiptNoise(lowerLine)) continue;
      if (_isTotalLine(lowerLine)) continue;
      if (_parseDateFromText(line) != null) continue;

      final amount = _largestAmountInText(line);
      if (amount == null || !_isReasonableAmount(amount)) continue;

      final name = line
          .replaceAll(
            RegExp(
              r'(?:rp\s*)?\d{1,3}(?:[.,]\d{3})+(?:,\d{2})?',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'\b\d{4,9}\b'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (name.length < 3) continue;
      if (RegExp(r'^[xX]?\d+\s*$').hasMatch(name)) continue;

      items.add(ReceiptItem(name: _toTitleCase(name), amount: amount));
    }

    final uniqueItems = <String, ReceiptItem>{};
    for (final item in items) {
      uniqueItems.putIfAbsent('${item.name}-${item.amount}', () => item);
    }

    return uniqueItems.values.take(20).toList(growable: false);
  }

  String inferCategory(String ocrText) {
    final text = ocrText.toLowerCase();

    if (_containsAny(text, [
      'grab',
      'gojek',
      'maxim',
      'taxi',
      'parkir',
      'tol',
      'transport',
      'bensin',
      'pertamina',
      'spbu',
    ])) {
      return 'Transportasi';
    }

    if (_containsAny(text, [
      'print',
      'fotocopy',
      'photocopy',
      'copy',
      'jilid',
      'atk',
      'kertas',
      'pulpen',
      'buku',
      'tugas',
      'kampus',
    ])) {
      return 'Print/Tugas';
    }

    if (_containsAny(text, [
      'makan',
      'ayam',
      'nasi',
      'mie',
      'bakso',
      'soto',
      'kopi',
      'cafe',
      'resto',
      'restaurant',
      'warung',
      'martabak',
      'roti',
      'minum',
      'teh',
      'juice',
      'jus',
      'kfc',
      'mcd',
      'burger',
      'pizza',
    ])) {
      return 'Makanan';
    }

    return 'Belanja';
  }

  double? extractBestTotalAmount(String ocrText) {
    final keywordAmount = _extractAmountAfterKeyword(ocrText);
    if (keywordAmount != null) return keywordAmount;

    final candidates = extractAmountCandidates(ocrText);
    if (candidates.isEmpty) return null;
    return candidates.first;
  }

  double? _extractAmountAfterKeyword(String ocrText) {
    final keywords = [
      'grand total',
      'total belanja',
      'total',
      'jumlah',
      'bayar',
      'tunai',
      'subtotal',
    ];
    final lines = ocrText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (final keyword in keywords) {
      for (final line in lines) {
        final lowerLine = line.toLowerCase();
        if (!lowerLine.contains(keyword)) continue;

        final amount = _largestAmountInText(line);
        if (amount != null) return amount;
      }
    }

    return null;
  }

  double? _largestAmountInText(String text) {
    final matches = RegExp(
      r'(?:rp\s*)?(\d{1,3}(?:[.,]\d{3})+|\d{4,9})(?:,\d{2})?',
      caseSensitive: false,
    ).allMatches(text);
    final amounts =
        matches
            .map((match) => _parseAmount(match.group(0) ?? ''))
            .where(_isReasonableAmount)
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (amounts.isEmpty) return null;
    return amounts.first;
  }

  bool _isReasonableAmount(double amount) {
    return amount >= 1000 && amount <= 100000000;
  }

  double _parseAmount(String rawValue) {
    var value = rawValue
        .toLowerCase()
        .replaceAll('rp', '')
        .replaceAll(RegExp(r'[^0-9.,]'), '')
        .trim();

    if (value.isEmpty) return 0;

    if (value.contains('.') && value.contains(',')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if (value.contains(',')) {
      final commaParts = value.split(',');
      if (commaParts.length == 2 && commaParts.last.length == 2) {
        value = commaParts.first.replaceAll('.', '');
      } else {
        value = value.replaceAll(',', '');
      }
    } else {
      value = value.replaceAll('.', '');
    }

    return double.tryParse(value) ?? 0;
  }

  List<String> _cleanLines(String ocrText) {
    return ocrText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  bool _looksLikeReceiptNoise(String lowerLine) {
    return _containsAny(lowerLine, [
      'telp',
      'telepon',
      'phone',
      'wa ',
      'whatsapp',
      'npwp',
      'alamat',
      'address',
      'kasir',
      'cashier',
      'receipt',
      'struk',
      'nota',
      'invoice',
      'member',
      'customer',
      'terima kasih',
      'thank you',
    ]);
  }

  bool _isTotalLine(String lowerLine) {
    return _containsAny(lowerLine, [
      'grand total',
      'total belanja',
      'total',
      'subtotal',
      'jumlah',
      'bayar',
      'tunai',
      'cash',
      'kembali',
      'change',
      'diskon',
      'discount',
      'pajak',
      'tax',
      'ppn',
    ]);
  }

  DateTime? _parseDateFromText(String text) {
    final numericDate = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b',
    ).firstMatch(text);
    if (numericDate != null) {
      return _buildDate(
        day: int.tryParse(numericDate.group(1) ?? ''),
        month: int.tryParse(numericDate.group(2) ?? ''),
        year: _normalizeYear(int.tryParse(numericDate.group(3) ?? '')),
      );
    }

    final isoDate = RegExp(
      r'\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b',
    ).firstMatch(text);
    if (isoDate != null) {
      return _buildDate(
        day: int.tryParse(isoDate.group(3) ?? ''),
        month: int.tryParse(isoDate.group(2) ?? ''),
        year: int.tryParse(isoDate.group(1) ?? ''),
      );
    }

    final textDate = RegExp(
      r'\b(\d{1,2})\s+([a-zA-Z]+)\s+(\d{2,4})\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (textDate != null) {
      return _buildDate(
        day: int.tryParse(textDate.group(1) ?? ''),
        month: _monthNumber(textDate.group(2) ?? ''),
        year: _normalizeYear(int.tryParse(textDate.group(3) ?? '')),
      );
    }

    return null;
  }

  DateTime? _buildDate({int? day, int? month, int? year}) {
    if (day == null || month == null || year == null) return null;
    if (year < 2000 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  int? _normalizeYear(int? year) {
    if (year == null) return null;
    if (year < 100) return 2000 + year;
    return year;
  }

  int? _monthNumber(String rawMonth) {
    final month = rawMonth.toLowerCase();
    const months = {
      'jan': 1,
      'januari': 1,
      'january': 1,
      'feb': 2,
      'februari': 2,
      'february': 2,
      'mar': 3,
      'maret': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'mei': 5,
      'may': 5,
      'jun': 6,
      'juni': 6,
      'june': 6,
      'jul': 7,
      'juli': 7,
      'july': 7,
      'agu': 8,
      'agustus': 8,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'okt': 10,
      'oct': 10,
      'oktober': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'des': 12,
      'dec': 12,
      'desember': 12,
      'december': 12,
    };
    return months[month];
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  String _toTitleCase(String value) {
    return value
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
          final trimmed = word.trim();
          if (trimmed.length <= 2 && trimmed == trimmed.toUpperCase()) {
            return trimmed;
          }
          return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
