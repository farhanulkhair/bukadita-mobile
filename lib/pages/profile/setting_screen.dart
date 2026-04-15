import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  static const String _notifEnabledKey = 'settings_notifications_enabled';
  static const String _emailNotifKey = 'settings_email_notifications';

  bool _notificationsEnabled = true;
  bool _emailNotifications = false;
  bool _systemPermissionGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSystemPermission();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final permStatus = await Permission.notification.status;

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notifEnabledKey) ?? true;
      _emailNotifications = prefs.getBool(_emailNotifKey) ?? false;
      _systemPermissionGranted = permStatus.isGranted;
      _isLoading = false;
    });
  }

  Future<void> _checkSystemPermission() async {
    final permStatus = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _systemPermissionGranted = permStatus.isGranted;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (!mounted) return;
        setState(() {
          _systemPermissionGranted = result.isGranted;
        });
        if (!result.isGranted) {
          if (result.isPermanentlyDenied) {
            _showOpenSettingsDialog();
          }
          return;
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifEnabledKey, value);
    if (!value) {
      await prefs.setBool(_emailNotifKey, false);
    }

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = value;
      if (!value) _emailNotifications = false;
    });

    _showSnackBar(
      value ? 'Notifikasi diaktifkan' : 'Notifikasi dinonaktifkan',
    );
  }

  Future<void> _toggleEmailNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailNotifKey, value);
    if (!mounted) return;
    setState(() {
      _emailNotifications = value;
    });
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Izin Notifikasi Diperlukan',
            style: AppTextStyles.headingSmall),
        content: Text(
          'Izin notifikasi telah ditolak secara permanen. '
          'Silakan buka Pengaturan perangkat untuk mengaktifkannya.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.gray500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: Text('Buka Pengaturan',
                style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Notifikasi'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      children: [
                        _buildSwitchTile(
                          title: 'Aktifkan Notifikasi',
                          subtitle: _systemPermissionGranted
                              ? 'Terima notifikasi dari aplikasi'
                              : 'Izin notifikasi belum diberikan',
                          value: _notificationsEnabled && _systemPermissionGranted,
                          onChanged: _toggleNotifications,
                        ),
                        if (!_systemPermissionGranted && _notificationsEnabled)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: GestureDetector(
                              onTap: () async {
                                final result =
                                    await Permission.notification.request();
                                if (result.isPermanentlyDenied) {
                                  _showOpenSettingsDialog();
                                }
                                _checkSystemPermission();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.orange50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.orange500
                                          .withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 18, color: AppColors.orange500),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Ketuk untuk memberikan izin notifikasi',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.orange600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_notificationsEnabled && _systemPermissionGranted) ...[
                          _buildDivider(),
                          _buildSwitchTile(
                            title: 'Notifikasi Email',
                            subtitle: 'Terima notifikasi via email',
                            value: _emailNotifications,
                            onChanged: _toggleEmailNotifications,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Tentang'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      children: [
                        _buildNavigationTile(
                          icon: Icons.info_outline,
                          title: 'Tentang Aplikasi',
                          onTap: _showAboutDialog,
                        ),
                        _buildDivider(),
                        _buildNavigationTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Kebijakan Privasi',
                          onTap: () => _showSnackBar('Halaman Kebijakan Privasi'),
                        ),
                        _buildDivider(),
                        _buildNavigationTile(
                          icon: Icons.description_outlined,
                          title: 'Syarat & Ketentuan',
                          onTap: () =>
                              _showSnackBar('Halaman Syarat & Ketentuan'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.labelLarge.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.gray700,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray500.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gray600, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: AppColors.gray200,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tentang Bukadita', style: AppTextStyles.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versi: 1.0.0', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Bukadita adalah aplikasi pembelajaran digital yang membantu Anda belajar dengan lebih efektif.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray600),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tutup',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
