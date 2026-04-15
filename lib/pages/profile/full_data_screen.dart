import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/theme.dart';
import '../../services/storage_service.dart';
import '../../services/profile_service.dart';
import '../../models/user_model.dart';
import '../../utils/error_helper.dart';

/// Full Data Screen - Halaman untuk melihat data lengkap user
class FullDataScreen extends StatefulWidget {
  const FullDataScreen({super.key});

  @override
  State<FullDataScreen> createState() => _FullDataScreenState();
}

class _FullDataScreenState extends State<FullDataScreen> {
  final StorageService _storageService = StorageService();
  final ProfileService _profileService = ProfileService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _storageService.getUserData();

      if (mounted) {
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshFromAPI() async {
    try {
      await _profileService.getCurrentUserProfile();
      await _loadUserData();
    } catch (_) {}
  }

  /// Format tanggal untuk ditampilkan
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Belum diisi';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Show dialog untuk edit field
  Future<void> _showEditDialog(
    String fieldType,
    String fieldName,
    String? currentValue, {
    bool isMultiline = false,
  }) async {
    final controller = TextEditingController(text: currentValue ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Edit $fieldName', style: AppTextStyles.headingSmall),
              ],
            ),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                maxLines: isMultiline ? 3 : 1,
                keyboardType:
                    fieldType == 'phone'
                        ? TextInputType.phone
                        : isMultiline
                        ? TextInputType.multiline
                        : TextInputType.text,
                decoration: InputDecoration(
                  labelText: fieldName,
                  hintText: 'Masukkan $fieldName',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.gray50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$fieldName tidak boleh kosong';
                  }
                  if (fieldType == 'phone' &&
                      !RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(value)) {
                    return 'Nomor HP tidak valid';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Batal',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop(controller.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Simpan',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      await _updateField(fieldType, result);
    }
  }

  /// Show date picker untuk tanggal lahir
  Future<void> _showDatePicker() async {
    DateTime? currentDate;
    if (_currentUser?.date_of_birth != null) {
      try {
        currentDate = DateTime.parse(_currentUser!.date_of_birth!);
      } catch (e) {
        currentDate = null;
      }
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      final formattedDate =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      await _updateField('date_of_birth', formattedDate);
    }
  }

  /// Update field ke API
  Future<void> _updateField(String fieldType, String value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _profileService.updateProfile(
        name: fieldType == 'name' ? value : null,
        phone: fieldType == 'phone' ? value : null,
        address: fieldType == 'address' ? value : null,
        date_of_birth: fieldType == 'date_of_birth' ? value : null,
      );

      if (result['success'] == true) {
        await _loadUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.white),
                  const SizedBox(width: 12),
                  Text('Data berhasil diupdate'),
                ],
              ),
              backgroundColor: AppColors.green600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(friendlyErrorMessage(e))),
              ],
            ),
            backgroundColor: AppColors.red600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Data Lengkap',
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refreshFromAPI,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Info Card
                      _buildInfoCard(),

                      const SizedBox(height: 24),

                      // Info text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.blue50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.blue200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.info,
                              size: 18,
                              color: AppColors.blue600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tap ikon edit untuk mengubah informasi',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.blue700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray500.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.user, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Informasi Pribadi',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInfoField(
            'Nama Lengkap',
            _currentUser?.name ?? '-',
            LucideIcons.user,
            () => _showEditDialog('name', 'Nama Lengkap', _currentUser?.name),
          ),
          const SizedBox(height: 12),
          _buildInfoField(
            'Email',
            _currentUser?.email ?? '-',
            LucideIcons.mail,
            null,
          ),
          const SizedBox(height: 12),
          _buildInfoField(
            'Nomor HP',
            _currentUser?.phone ?? '-',
            LucideIcons.phone,
            () => _showEditDialog('phone', 'Nomor HP', _currentUser?.phone),
          ),
          const SizedBox(height: 12),
          _buildInfoField(
            'Alamat',
            _currentUser?.address ?? '-',
            LucideIcons.mapPin,
            () => _showEditDialog(
              'address',
              'Alamat',
              _currentUser?.address,
              isMultiline: true,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoField(
            'Tanggal Lahir',
            _formatDate(_currentUser?.date_of_birth),
            LucideIcons.cake,
            () => _showDatePicker(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    String value,
    IconData icon,
    VoidCallback? onEdit,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isNotEmpty ? value : 'Belum diisi',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color:
                        value.isNotEmpty
                            ? AppColors.gray700
                            : AppColors.gray400,
                  ),
                  maxLines: label == 'Alamat' ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Icon(Icons.edit, size: 16, color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
