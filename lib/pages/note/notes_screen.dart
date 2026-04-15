import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../theme/theme.dart';
import '../../models/note_model.dart';
import '../../services/note_service.dart';
import '../../utils/error_helper.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NoteService _noteService = NoteService();
  final TextEditingController _searchController = TextEditingController();

  List<NoteModel> _notes = [];
  bool _isLoading = true;
  String? _selectedCategory;
  List<String> _categories = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final result = await _noteService.getNotes(
      limit: 100,
      category: _selectedCategory,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _notes = result['data'] as List<NoteModel>;
        }
      });
    }
  }

  Future<void> _loadCategories() async {
    final result = await _noteService.getCategories();
    if (mounted && result['success']) {
      setState(() {
        _categories = result['data'] as List<String>;
      });
    }
  }

  List<NoteModel> get _sortedNotes {
    final pinned = _notes.where((n) => n.isPinned).toList();
    final unpinned = _notes.where((n) => !n.isPinned).toList();
    pinned.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    unpinned.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return [...pinned, ...unpinned];
  }

  Future<void> _deleteNote(NoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Catatan', style: AppTextStyles.headingSmall),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${note.title}"?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppTextStyles.labelMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _noteService.deleteNote(note.id);
      if (mounted) {
        if (result['success']) {
          _showSnackBar('Catatan berhasil dihapus', isError: false);
          _loadNotes();
        } else {
          _showSnackBar(result['message'] ?? 'Gagal menghapus', isError: true);
        }
      }
    }
  }

  Future<void> _togglePin(NoteModel note) async {
    final result = await _noteService.togglePin(note.id);
    if (mounted) {
      if (result['success']) {
        final pinned = !(note.isPinned);
        _showSnackBar(
          pinned ? 'Catatan disematkan' : 'Catatan tidak disematkan',
          isError: false,
        );
        _loadNotes();
      } else {
        _showSnackBar(result['message'] ?? 'Gagal mengubah pin', isError: true);
      }
    }
  }

  Future<void> _exportAsPdf(NoteModel note) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                note.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                if (note.category != null && note.category!.isNotEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      note.category!,
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.blue),
                    ),
                  ),
                pw.SizedBox(width: 12),
                pw.Text(
                  'Diperbarui: ${DateFormat('dd MMM yyyy, HH:mm', 'id').format(note.updatedAt)}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Text(
              note.content,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 6),
            ),
          ],
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Diekspor dari Bukadita',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey500,
              ),
            ),
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: '${note.title}.pdf',
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal mengekspor PDF. ${friendlyErrorMessage(e)}', isError: true);
      }
    }
  }

  Future<void> _shareToNativeNotes(NoteModel note) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${note.title}.txt');
      final buffer = StringBuffer();
      buffer.writeln(note.title);
      buffer.writeln('=' * note.title.length);
      if (note.category != null && note.category!.isNotEmpty) {
        buffer.writeln('Kategori: ${note.category}');
      }
      buffer.writeln(
        'Diperbarui: ${DateFormat('dd MMM yyyy, HH:mm').format(note.updatedAt)}',
      );
      buffer.writeln();
      buffer.writeln(note.content);
      await file.writeAsString(buffer.toString());

      await SharePlus.instance.share(
        ShareParams(
          text: '${note.title}\n\n${note.content}',
          subject: note.title,
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal membagikan catatan. ${friendlyErrorMessage(e)}', isError: true);
      }
    }
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

  void _openEditor({NoteModel? note}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    );
    if (result == true) {
      _loadNotes();
      _loadCategories();
    }
  }

  void _showNoteActions(NoteModel note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  note.title,
                  style: AppTextStyles.headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.edit_outlined,
                label: 'Edit Catatan',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  _openEditor(note: note);
                },
              ),
              _buildActionTile(
                icon: note.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                label: note.isPinned ? 'Lepas Pin' : 'Sematkan',
                color: AppColors.orange600,
                onTap: () {
                  Navigator.pop(ctx);
                  _togglePin(note);
                },
              ),
              _buildActionTile(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Ekspor sebagai PDF',
                color: AppColors.red500,
                onTap: () {
                  Navigator.pop(ctx);
                  _exportAsPdf(note);
                },
              ),
              _buildActionTile(
                icon: Icons.share_outlined,
                label: 'Bagikan / Simpan ke Aplikasi Lain',
                color: AppColors.green600,
                onTap: () {
                  Navigator.pop(ctx);
                  _shareToNativeNotes(note);
                },
              ),
              const Divider(height: 16),
              _buildActionTile(
                icon: Icons.delete_outline,
                label: 'Hapus Catatan',
                color: AppColors.red600,
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteNote(note);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: AppTextStyles.labelMedium),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppColors.secondary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Catatan Saya',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.secondary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _sortedNotes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotes,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _sortedNotes.length,
                          itemBuilder: (context, index) {
                            final note = _sortedNotes[index];
                            final showPinnedHeader = index == 0 && note.isPinned;
                            final showOtherHeader = note.isPinned == false &&
                                (index == 0 ||
                                    _sortedNotes[index - 1].isPinned);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showPinnedHeader)
                                  _buildSectionHeader(
                                    'Disematkan',
                                    Icons.push_pin,
                                  ),
                                if (showOtherHeader)
                                  _buildSectionHeader(
                                    'Catatan Lainnya',
                                    Icons.notes,
                                  ),
                                _buildNoteCard(note),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: AppColors.white, size: 28),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Cari catatan...',
                hintStyle: AppTextStyles.hint,
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.gray400,
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.gray400,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _loadNotes();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onSubmitted: (_) => _loadNotes(),
            ),
          ),
          const SizedBox(height: 10),
          // Category filter chips
          if (_categories.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip(
                    label: 'Semua',
                    isSelected: _selectedCategory == null,
                    onTap: () {
                      setState(() => _selectedCategory = null);
                      _loadNotes();
                    },
                  ),
                  ..._categories.map(
                    (cat) => _buildFilterChip(
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        _loadNotes();
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? AppColors.white : AppColors.gray600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gray500),
          const SizedBox(width: 6),
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.gray500,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(note.updatedAt);

    return GestureDetector(
      onTap: () => _openEditor(note: note),
      onLongPress: () => _showNoteActions(note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: note.isPinned
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.gray200,
            width: note.isPinned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (note.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.push_pin,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                Expanded(
                  child: Text(
                    note.title,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showNoteActions(note),
                  child: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.gray500,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (note.category != null && note.category!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.category!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                Icon(Icons.access_time, size: 12, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.gray400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.note_alt_outlined,
                size: 56,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != null
                  ? 'Catatan tidak ditemukan'
                  : 'Belum ada catatan',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != null
                  ? 'Coba ubah pencarian atau filter Anda'
                  : 'Ketuk tombol + untuk menambahkan catatan baru',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
