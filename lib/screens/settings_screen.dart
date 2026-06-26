import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/saving_goal_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/remote_reset_service.dart';
import '../widgets/app_feedback_dialog.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const appVersion = '2.3.0';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isResetting = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileCard(
                isDarkMode: themeProvider.isDarkMode,
                name: authProvider.name ?? 'Mahasiswa',
                email: authProvider.email ?? 'mahasiswa@dompetkampus.id',
                onEdit: () => _showEditProfileDialog(context),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark mode'),
                      subtitle: const Text('Gunakan tema gelap aplikasi'),
                      value: themeProvider.isDarkMode,
                      onChanged: themeProvider.setDarkMode,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('Tentang Aplikasi'),
                      subtitle: const Text(
                        'DompetKampus versi ${SettingsScreen.appVersion}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showAboutDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Logout'),
                      subtitle: const Text('Keluar dari akun Supabase'),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Aplikasi',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Reset akan menghapus semua transaksi, target tabungan, budget, dan tagihan milik akun ini.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.expense,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isResetting
                              ? null
                              : () => _confirmReset(context),
                          icon: _isResetting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.delete_forever_rounded),
                          label: Text(
                            _isResetting
                                ? 'Menghapus data...'
                                : 'Reset Semua Data',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Versi aplikasi: ${SettingsScreen.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset semua data?'),
          content: const Text(
            'Semua transaksi, target tabungan, budget, dan tagihan akun ini akan dihapus permanen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Ya, Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    setState(() => _isResetting = true);

    try {
      await RemoteResetService().resetAllUserData();
      if (!context.mounted) return;
      await context.read<TransactionProvider>().loadTransactions();
      if (!context.mounted) return;
      await context.read<SavingGoalProvider>().loadSavingGoals();
      if (!context.mounted) return;
      await context.read<BudgetProvider>().loadBudgets();
      if (!context.mounted) return;
      await context.read<BillProvider>().loadBills();
      if (!context.mounted) return;

      await AppFeedbackDialog.showSuccess(
        context,
        message: 'Semua data berhasil dihapus.',
      );
    } catch (_) {
      if (!context.mounted) return;
      await AppFeedbackDialog.showError(
        context,
        message: 'Gagal menghapus data. Periksa koneksi internet.',
      );
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final success = await context.read<AuthProvider>().logout();
    if (!context.mounted) return;

    if (success) {
      context.read<TransactionProvider>().clear();
      context.read<SavingGoalProvider>().clear();
      context.read<BudgetProvider>().clear();
      context.read<BillProvider>().clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      final errorMessage = context.read<AuthProvider>().errorMessage;
      await AppFeedbackDialog.showError(
        context,
        message: errorMessage ?? 'Logout gagal.',
      );
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _EditProfileDialog(),
    );
  }

  void _showAboutDialog(BuildContext context) {
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
          'DompetKampus adalah aplikasi manajemen keuangan mahasiswa untuk mencatat pemasukan, pengeluaran, target tabungan, grafik keuangan, dan laporan PDF.',
        ),
        SizedBox(height: 12),
        Text('Dibuat oleh: Brilian Fatih Wicaksono'),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.isDarkMode,
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final bool isDarkMode;
  final String name;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final avatarBackground = isDarkMode
        ? AppColors.darkSurfaceVariant
        : AppColors.background;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: avatarBackground,
              child: const Icon(
                Icons.person_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit profil',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog();

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController = TextEditingController(text: authProvider.name ?? '');
    _emailController = TextEditingController(text: authProvider.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AlertDialog(
      title: const Text('Edit Profil'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email wajib diisi';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: authProvider.isLoading
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: authProvider.isLoading ? null : _saveProfile,
          child: Text(authProvider.isLoading ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      await AppFeedbackDialog.showSuccess(
        context,
        message: 'Profil berhasil diperbarui.',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      await AppFeedbackDialog.showError(
        context,
        message: authProvider.errorMessage ?? 'Gagal memperbarui profil.',
      );
    }
  }
}
