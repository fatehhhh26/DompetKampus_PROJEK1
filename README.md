# DompetKampus

DompetKampus adalah aplikasi manajemen keuangan mahasiswa berbasis Flutter dan Supabase untuk mencatat pemasukan, pengeluaran, target tabungan, budget bulanan, tagihan, grafik, insight keuangan, export laporan PDF, dan export laporan Excel.

Project ini dikembangkan sebagai aplikasi portofolio mahasiswa TRPL dengan fokus pada pengelolaan data keuangan pribadi, autentikasi user, penyimpanan cloud berbasis Supabase, dan tampilan mobile yang rapi serta mudah digunakan.

## Download APK

Versi Android DompetKampus V2.0.0 dapat diunduh melalui halaman release:

[Download DompetKampus V2.0.0](https://github.com/fatehhhh26/DompetKampus_PROJEK1/releases/tag/v2.0.0)

## Fitur Utama

- Register/Login Supabase
- Logout
- Dashboard saldo
- Tambah, edit, hapus, dan detail transaksi
- Search transaksi
- Filter transaksi per bulan
- Grafik pengeluaran
- Target tabungan
- Budget bulanan
- Notifikasi tagihan
- Insight keuangan otomatis
- Export laporan PDF
- Export laporan Excel
- Dark mode
- Reset semua data per user
- Custom launcher icon

## Teknologi yang Digunakan

- Flutter
- Dart
- Provider
- Supabase Auth
- Supabase PostgreSQL
- Row Level Security
- Hive untuk preferensi lokal
- fl_chart
- pdf
- printing
- excel
- share_plus
- flutter_local_notifications
- timezone
- flutter_launcher_icons
- flutter_test

## Struktur Folder Project

```text
lib/
+-- main.dart
+-- app.dart
+-- core/
|   +-- config/
|   |   +-- supabase_config.dart
|   +-- constants/
|   |   +-- app_colors.dart
|   +-- theme/
|   |   +-- app_theme.dart
|   +-- utils/
|       +-- currency_formatter.dart
+-- models/
|   +-- budget_model.dart
|   +-- bill_model.dart
|   +-- saving_goal_model.dart
|   +-- transaction_model.dart
+-- providers/
|   +-- auth_provider.dart
|   +-- bill_provider.dart
|   +-- budget_provider.dart
|   +-- saving_goal_provider.dart
|   +-- theme_provider.dart
|   +-- transaction_provider.dart
+-- services/
|   +-- auth_service.dart
|   +-- local_storage_service.dart
|   +-- notification_service.dart
|   +-- pdf_service.dart
|   +-- excel_service.dart
|   +-- remote_bill_service.dart
|   +-- remote_budget_service.dart
|   +-- remote_reset_service.dart
|   +-- remote_saving_goal_service.dart
|   +-- remote_transaction_service.dart
+-- screens/
|   +-- add_transaction_screen.dart
|   +-- bill_screen.dart
|   +-- budget_screen.dart
|   +-- chart_screen.dart
|   +-- dashboard_screen.dart
|   +-- login_screen.dart
|   +-- main_navigation_screen.dart
|   +-- register_screen.dart
|   +-- report_screen.dart
|   +-- saving_goal_screen.dart
|   +-- settings_screen.dart
|   +-- splash_screen.dart
|   +-- transaction_detail_screen.dart
|   +-- transaction_history_screen.dart
+-- widgets/
    +-- balance_card.dart
    +-- custom_button.dart
    +-- empty_state_widget.dart
    +-- transaction_card.dart
```

## Struktur Tabel Supabase

Database Supabase menggunakan PostgreSQL dengan Row Level Security agar setiap user hanya dapat mengakses data miliknya sendiri.

### profiles

Menyimpan data profil user yang terhubung dengan Supabase Auth.

```text
id uuid primary key
name text
email text
created_at timestamp
updated_at timestamp
```

### transactions

Menyimpan data pemasukan dan pengeluaran user.

```text
id uuid primary key
user_id uuid references auth.users(id)
title text
amount numeric
type text
category text
date date
note text
created_at timestamp
updated_at timestamp
```

### saving_goals

Menyimpan target tabungan user.

```text
id uuid primary key
user_id uuid references auth.users(id)
title text
target_amount numeric
current_amount numeric
deadline date
note text
is_completed boolean
created_at timestamp
updated_at timestamp
```

### budgets

Menyimpan budget bulanan per kategori.

```text
id uuid primary key
user_id uuid references auth.users(id)
category text
month int
year int
limit_amount numeric
note text
created_at timestamp
updated_at timestamp
```

### bills

Menyimpan tagihan dan jadwal pengingat lokal milik user.

```text
id uuid primary key
user_id uuid references auth.users(id)
title text
amount numeric
due_date date
category text
note text
is_paid boolean
reminder_days_before int
created_at timestamp
updated_at timestamp
```

## Cara Setup

1. Install dependency Flutter.

```bash
flutter pub get
```

2. Buat project Supabase melalui dashboard Supabase.

3. Masukkan URL dan publishable key Supabase ke file:

```text
lib/core/config/supabase_config.dart
```

Contoh:

```dart
class SupabaseConfig {
  static const String url = 'https://project-id.supabase.co';
  static const String anonKey = 'sb_publishable_xxx';
}
```

4. Jalankan SQL untuk membuat tabel:

- `profiles`
- `transactions`
- `saving_goals`
- `budgets`
- `bills`

5. Aktifkan Row Level Security dan buat policy agar data hanya dapat diakses oleh user pemilik data.

6. Jalankan aplikasi.

```bash
flutter run
```

## Cara Testing

Jalankan analisis kode:

```bash
flutter analyze
```

Jalankan test:

```bash
flutter test
```

## Cara Build APK

Build APK release:

```bash
flutter build apk --release
```

File APK hasil build biasanya berada di:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Screenshot Aplikasi

Screenshot dapat ditempatkan pada folder `screenshots/`.

```text
screenshots/
+-- splash.png
+-- login.png
+-- dashboard.png
+-- history.png
+-- chart.png
+-- saving_goal.png
+-- budget.png
+-- settings.png
+-- report.png
```

Placeholder preview:

```md
![Splash](screenshots/splash.png)
![Login](screenshots/login.png)
![Dashboard](screenshots/dashboard.png)
![Riwayat](screenshots/history.png)
![Grafik](screenshots/chart.png)
![Target Tabungan](screenshots/saving_goal.png)
![Budget](screenshots/budget.png)
![Settings](screenshots/settings.png)
![Laporan](screenshots/report.png)
```

## Rencana Pengembangan

- Notifikasi tagihan
- Scan struk
- AI financial insight
- Export Excel
- Deployment web
- Publish Play Store

## Status Project

DompetKampus V2.2 sudah memakai Supabase untuk autentikasi dan penyimpanan data utama, termasuk tagihan per user. Versi ini juga mendukung export laporan Excel multi-sheet untuk transaksi, target tabungan, budget, dan tagihan. Hive tetap digunakan untuk preferensi lokal seperti dark mode, sehingga aplikasi tetap ringan dan responsif untuk penggunaan harian mahasiswa.
