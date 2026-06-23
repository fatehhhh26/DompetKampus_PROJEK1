# DompetKampus

DompetKampus adalah aplikasi Flutter untuk membantu mahasiswa mencatat dan memantau keuangan harian. Aplikasi ini berjalan tanpa backend dan menyimpan data secara lokal menggunakan Hive.

## Deskripsi Aplikasi

DompetKampus dibuat sebagai aplikasi manajemen keuangan mahasiswa. Pengguna dapat mencatat pemasukan, pengeluaran, melihat saldo, memantau grafik pengeluaran berdasarkan kategori, membuat target tabungan, serta membuat laporan PDF dari data transaksi.

## Fitur Utama

- Splash screen, login, dan register dummy.
- Dashboard saldo, total pemasukan, total pengeluaran, dan transaksi terbaru.
- Tambah, edit, hapus, dan simpan transaksi secara lokal.
- Riwayat transaksi lengkap.
- Grafik pengeluaran berdasarkan kategori.
- Target tabungan dengan progress, deadline, tambah nominal, dan status tercapai.
- Export, preview, dan share laporan PDF.
- Format mata uang Rupiah.
- Penyimpanan lokal menggunakan Hive.

## Teknologi yang Digunakan

- Flutter
- Dart
- Provider
- Hive dan Hive Flutter
- fl_chart
- pdf
- printing
- intl
- uuid

## Struktur Folder

```text
lib/
+-- main.dart
+-- app.dart
+-- core/
|   +-- constants/
|   |   +-- app_colors.dart
|   +-- theme/
|   |   +-- app_theme.dart
|   +-- utils/
|       +-- currency_formatter.dart
+-- models/
|   +-- transaction_model.dart
|   +-- saving_goal_model.dart
+-- providers/
|   +-- auth_provider.dart
|   +-- transaction_provider.dart
|   +-- saving_goal_provider.dart
+-- services/
|   +-- local_storage_service.dart
|   +-- pdf_service.dart
+-- screens/
|   +-- splash_screen.dart
|   +-- login_screen.dart
|   +-- register_screen.dart
|   +-- main_navigation_screen.dart
|   +-- dashboard_screen.dart
|   +-- add_transaction_screen.dart
|   +-- transaction_history_screen.dart
|   +-- chart_screen.dart
|   +-- saving_goal_screen.dart
|   +-- report_screen.dart
+-- widgets/
    +-- balance_card.dart
    +-- transaction_card.dart
    +-- custom_button.dart
    +-- empty_state_widget.dart
```

## Cara Menjalankan Aplikasi

1. Pastikan Flutter SDK sudah terpasang.
2. Ambil dependency:

```bash
flutter pub get
```

3. Jalankan aplikasi:

```bash
flutter run
```

## Cara Menjalankan Test

Jalankan test Flutter:

```bash
flutter test
```

Jalankan analisis kode:

```bash
flutter analyze
```

## Screenshot Aplikasi

Screenshot belum ditambahkan ke repository.

Rekomendasi folder:

```text
assets/screenshots/
+-- dashboard.png
+-- transaction_history.png
+-- chart.png
+-- saving_goal.png
+-- report.png
```

Setelah screenshot tersedia, tambahkan preview seperti ini:

```md
![Dashboard](assets/screenshots/dashboard.png)
```

## Rencana Pengembangan

- Filter transaksi berdasarkan tanggal, kategori, dan jenis transaksi.
- Pencarian transaksi.
- Budget bulanan per kategori.
- Backup dan restore data lokal.
- PIN atau biometric lock.
- Dark mode.
- Statistik bulanan dan tahunan.
- Export laporan dengan rentang tanggal.
- Pengujian widget dan provider yang lebih lengkap.
