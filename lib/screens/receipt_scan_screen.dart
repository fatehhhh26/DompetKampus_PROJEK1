import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/transaction_model.dart';
import '../services/receipt_ocr_service.dart';
import '../widgets/app_feedback_dialog.dart';
import '../widgets/custom_button.dart';
import 'add_transaction_screen.dart';

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  final _ocrService = ReceiptOcrService();
  final _amountController = TextEditingController();

  XFile? _selectedImage;
  String _ocrText = '';
  List<double> _amountCandidates = [];
  ParsedReceipt? _parsedReceipt;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Struk')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Scan Struk',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Foto struk belanja untuk membantu mengisi transaksi.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickFromCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Ambil Foto'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri'),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_selectedImage!.path),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: _isProcessing ? 'Memproses...' : 'Proses Struk',
                icon: Icons.document_scanner_outlined,
                onPressed: _isProcessing ? null : _processReceipt,
              ),
            ],
            if (_ocrText.isNotEmpty) ...[
              const SizedBox(height: 16),
              if (_parsedReceipt != null)
                _ReceiptSummaryCard(receipt: _parsedReceipt!),
              if (_parsedReceipt != null) const SizedBox(height: 16),
              _OcrTextCard(text: _ocrText),
            ],
            const SizedBox(height: 16),
            _AmountSection(
              candidates: _amountCandidates,
              amountController: _amountController,
              onCandidateSelected: (amount) {
                setState(() {
                  _amountController.text = amount.toStringAsFixed(0);
                });
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Buat Transaksi',
              icon: Icons.receipt_long_outlined,
              onPressed: _canCreateTransaction ? _openAddTransaction : null,
            ),
          ],
        ),
      ),
    );
  }

  bool get _canCreateTransaction {
    final amount = _parseAmount(_amountController.text);
    return amount > 0 && !_isProcessing;
  }

  Future<void> _pickFromCamera() async {
    await _pickImage(_ocrService.pickImageFromCamera);
  }

  Future<void> _pickFromGallery() async {
    await _pickImage(_ocrService.pickImageFromGallery);
  }

  Future<void> _pickImage(Future<XFile?> Function() picker) async {
    try {
      final image = await picker();
      if (image == null) return;

      setState(() {
        _selectedImage = image;
        _ocrText = '';
        _amountCandidates = [];
        _parsedReceipt = null;
        _amountController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      await AppFeedbackDialog.showError(
        context,
        message: 'Tidak bisa membuka kamera/galeri. Periksa izin aplikasi.',
      );
    }
  }

  Future<void> _processReceipt() async {
    final selectedImage = _selectedImage;
    if (selectedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final text = await _ocrService.recognizeTextFromImage(selectedImage.path);
      final receipt = _ocrService.parseReceipt(text);
      final bestAmount = receipt.totalAmount;

      setState(() {
        _ocrText = text;
        _parsedReceipt = receipt;
        _amountCandidates = receipt.amountCandidates;
        if (bestAmount != null) {
          _amountController.text = bestAmount.toStringAsFixed(0);
        }
      });

      if (!mounted) return;
      if (bestAmount == null) {
        await AppFeedbackDialog.showInfo(
          context,
          message: 'Nominal tidak terdeteksi. Silakan isi manual.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      await AppFeedbackDialog.showError(
        context,
        message: 'Gagal membaca struk. Coba foto yang lebih jelas.',
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _openAddTransaction() {
    final receipt = _parsedReceipt;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          initialType: TransactionModel.expenseType,
          initialTitle: receipt?.transactionTitle ?? 'Belanja dari Struk',
          initialAmount: _parseAmount(_amountController.text),
          initialCategory: receipt?.category ?? 'Belanja',
          initialNote: receipt?.note ?? 'Input dari scan struk',
          initialDate: receipt?.transactionDate ?? DateTime.now(),
        ),
      ),
    );
  }

  double _parseAmount(String value) {
    final normalized = value.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }
}

class _ReceiptSummaryCard extends StatelessWidget {
  const _ReceiptSummaryCard({required this.receipt});

  final ParsedReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final date = receipt.transactionDate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detail Struk Terdeteksi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetectedRow(
              label: 'Nama toko',
              value: receipt.storeName ?? 'Belum terdeteksi',
            ),
            _DetectedRow(
              label: 'Tanggal',
              value: date == null
                  ? 'Belum terdeteksi'
                  : DateFormat('dd MMMM yyyy', 'id_ID').format(date),
            ),
            _DetectedRow(label: 'Kategori', value: receipt.category),
            _DetectedRow(
              label: 'Total',
              value: receipt.totalAmount == null
                  ? 'Belum terdeteksi'
                  : CurrencyFormatter.format(receipt.totalAmount!),
            ),
            const SizedBox(height: 12),
            Text(
              'Item belanja',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (receipt.items.isEmpty)
              const Text(
                'Item belum terbaca. Total tetap bisa dipakai untuk membuat transaksi.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              for (final item in receipt.items.take(5))
                _ReceiptItemRow(item: item),
            if (receipt.items.length > 5) ...[
              const SizedBox(height: 6),
              Text(
                '+${receipt.items.length - 5} item lainnya masuk ke catatan transaksi',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetectedRow extends StatelessWidget {
  const _DetectedRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItemRow extends StatelessWidget {
  const _ReceiptItemRow({required this.item});

  final ReceiptItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(item.amount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _OcrTextCard extends StatelessWidget {
  const _OcrTextCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.text_snippet_outlined),
        title: const Text('Hasil OCR'),
        subtitle: const Text('Teks yang terbaca dari struk'),
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 180),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              child: Text(
                text.isEmpty ? '-' : text,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountSection extends StatelessWidget {
  const _AmountSection({
    required this.candidates,
    required this.amountController,
    required this.onCandidateSelected,
  });

  final List<double> candidates;
  final TextEditingController amountController;
  final ValueChanged<double> onCandidateSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nominal Transaksi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (candidates.isEmpty)
              const Text(
                'Nominal belum terdeteksi. Kamu tetap bisa mengisi manual.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final amount in candidates.take(6))
                    ActionChip(
                      label: Text(CurrencyFormatter.format(amount)),
                      onPressed: () => onCandidateSelected(amount),
                    ),
                ],
              ),
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal manual',
                hintText: 'Contoh: 25000',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
