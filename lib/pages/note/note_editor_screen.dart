import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/theme.dart';
import '../../models/note_model.dart';
import '../../services/note_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NoteService _noteService = NoteService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final FocusNode _contentFocus = FocusNode();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;
    if (_isEditing) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _categoryController.text = widget.note!.category ?? '';
    }

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
    _categoryController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final category = _categoryController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('Judul catatan tidak boleh kosong', isError: true);
      return;
    }
    if (content.isEmpty) {
      _showSnackBar('Isi catatan tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    Map<String, dynamic> result;

    if (_isEditing) {
      result = await _noteService.updateNote(
        noteId: widget.note!.id,
        title: title,
        content: content,
        category: category.isNotEmpty ? category : null,
      );
    } else {
      result = await _noteService.createNote(
        title: title,
        content: content,
        category: category.isNotEmpty ? category : null,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success']) {
        _showSnackBar(
          _isEditing ? 'Catatan berhasil diperbarui' : 'Catatan berhasil dibuat',
          isError: false,
        );
        Navigator.pop(context, true);
      } else {
        _showSnackBar(result['message'] ?? 'Gagal menyimpan', isError: true);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Buang Perubahan?', style: AppTextStyles.headingSmall),
        content: Text(
          'Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin keluar?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Tetap Edit', style: AppTextStyles.labelMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Buang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red500 : AppColors.green600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: AppColors.secondary,
            onPressed: () async {
              if (!_hasChanges) {
                Navigator.pop(context);
                return;
              }
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _isEditing ? 'Edit Catatan' : 'Catatan Baru',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.secondary,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _isSaving ? null : _saveNote,
                icon: _isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(Icons.check, size: 20, color: AppColors.primary),
                label: Text(
                  'Simpan',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextField(
                controller: _titleController,
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Judul Catatan',
                  hintStyle: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.gray300,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _contentFocus.requestFocus(),
              ),

              const SizedBox(height: 8),

              // Category field
              Row(
                children: [
                  Icon(Icons.label_outline, size: 18, color: AppColors.gray400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Kategori (opsional)',
                        hintStyle: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gray400,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),

              // Date info for existing notes
              if (_isEditing) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Diperbarui ${DateFormat('dd MMM yyyy, HH:mm').format(widget.note!.updatedAt)}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.gray400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              Container(
                height: 1,
                color: AppColors.gray200,
              ),
              const SizedBox(height: 16),

              // Content field
              TextField(
                controller: _contentController,
                focusNode: _contentFocus,
                style: AppTextStyles.body.copyWith(
                  height: 1.7,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Mulai menulis catatan...',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.gray300,
                    height: 1.7,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                minLines: 20,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
