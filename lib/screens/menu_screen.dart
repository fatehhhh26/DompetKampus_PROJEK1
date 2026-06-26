import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'chart_screen.dart';
import 'receipt_scan_screen.dart';
import 'report_screen.dart';
import 'saving_goal_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Menu',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Akses fitur lainnya di DompetKampus',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _MenuSection(
              title: 'Keuangan',
              children: [
                _MenuItem(
                  icon: Icons.document_scanner_outlined,
                  title: 'Scan Struk',
                  subtitle: 'Buat draft pengeluaran dari foto struk',
                  onTap: () => _open(context, const ReceiptScanScreen()),
                ),
                _MenuItem(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Grafik Pengeluaran',
                  subtitle: 'Lihat komposisi pengeluaran per kategori',
                  onTap: () => _open(context, const ChartScreen()),
                ),
                _MenuItem(
                  icon: Icons.savings_outlined,
                  title: 'Target Tabungan',
                  subtitle: 'Pantau progres target tabungan mahasiswa',
                  onTap: () => _open(context, const SavingGoalScreen()),
                ),
                _MenuItem(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Laporan',
                  subtitle: 'Preview, share, dan export laporan PDF',
                  onTap: () => _open(context, const ReportScreen()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MenuSection(
              title: 'Pengaturan',
              children: [
                _MenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Profil, dark mode, reset data, dan logout',
                  onTap: () => _open(context, const SettingsScreen()),
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Tentang Aplikasi',
                  subtitle: 'Informasi versi dan deskripsi DompetKampus',
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'DompetKampus',
      applicationVersion: SettingsScreen.appVersion,
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/images/logo.png', width: 48, height: 48),
      ),
      children: const [
        SizedBox(height: 8),
        Text(
          'DompetKampus adalah aplikasi manajemen keuangan mahasiswa untuk mencatat pemasukan, pengeluaran, target tabungan, budget, tagihan, grafik keuangan, dan laporan PDF.',
        ),
        SizedBox(height: 12),
        Text('Dibuat oleh: Brilian Fatih Wicaksono'),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
