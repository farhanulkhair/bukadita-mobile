import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/theme.dart';
import '../../models/message_model.dart';
import '../../services/message_service.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final MessageService _messageService = MessageService();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _isLoading = true;
        _error = null;
      });
    }

    final result = await _messageService.getMyMessages(page: _page);

    if (!mounted) return;

    if (result['success'] == true) {
      final items = result['data'] as List<MessageModel>;
      setState(() {
        if (refresh || _page == 1) {
          _messages = items;
        } else {
          _messages.addAll(items);
        }
        _unreadCount = result['unread_count'] ?? 0;
        NotificationService().unreadCount.value = _unreadCount;
        final pagination = result['pagination'];
        if (pagination != null) {
          _totalPages = pagination['totalPages'] ?? 1;
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _error = result['message'] ?? 'Gagal memuat notifikasi';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _page >= _totalPages) return;
    setState(() {
      _isLoadingMore = true;
      _page++;
    });
    await _loadMessages();
  }

  Future<void> _markAsRead(MessageModel msg) async {
    if (msg.isRead) return;
    final result = await _messageService.markAsRead(msg.id);
    if (result['success'] == true && mounted) {
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx != -1) {
          _messages[idx] = MessageModel(
            id: msg.id,
            senderId: msg.senderId,
            receiverId: msg.receiverId,
            title: msg.title,
            message: msg.message,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: msg.createdAt,
            sender: msg.sender,
          );
          if (_unreadCount > 0) _unreadCount--;
          NotificationService().unreadCount.value = _unreadCount;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final result = await _messageService.markAllAsRead();
    if (result['success'] == true && mounted) {
      setState(() {
        _messages = _messages
            .map((m) => MessageModel(
                  id: m.id,
                  senderId: m.senderId,
                  receiverId: m.receiverId,
                  title: m.title,
                  message: m.message,
                  isRead: true,
                  readAt: DateTime.now(),
                  createdAt: m.createdAt,
                  sender: m.sender,
                ))
            .toList();
        _unreadCount = 0;
        NotificationService().unreadCount.value = 0;
      });
    }
  }

  Future<bool> _confirmDelete(MessageModel msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Notifikasi'),
        content: const Text('Notifikasi ini akan dihapus dari daftar Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _messageService.deleteMessage(msg.id);
      if (result['success'] == true && mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == msg.id);
          if (!msg.isRead) {
            _unreadCount = (_unreadCount - 1).clamp(0, 999);
            NotificationService().unreadCount.value = _unreadCount;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifikasi dihapus'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return true;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menghapus'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return false;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(
                LucideIcons.checkCheck,
                size: 16,
                color: AppColors.white,
              ),
              label: Text(
                'Baca Semua',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _error != null
              ? _buildError()
              : _messages.isEmpty
                  ? _buildEmpty()
                  : _buildMessageList(),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 180,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.wifiOff,
              size: 56,
              color: AppColors.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadMessages(refresh: true),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.bell,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Belum Ada Notifikasi',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.gray800,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Notifikasi terbaru Anda akan muncul di sini',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray500,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadMessages(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _messages.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final msg = _messages[index];
            return Dismissible(
              key: Key(msg.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDelete(msg),
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(LucideIcons.trash2, color: Colors.white, size: 22),
              ),
              child: _buildMessageCard(msg),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageCard(MessageModel msg) {
    return GestureDetector(
      onTap: () {
        _markAsRead(msg);
        _showMessageDetail(msg);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: msg.isRead ? AppColors.white : AppColors.blue50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: msg.isRead ? AppTheme.gray200 : AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: msg.isRead
                      ? AppTheme.gray100
                      : AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  msg.isRead ? LucideIcons.mailOpen : LucideIcons.mail,
                  size: 20,
                  color: msg.isRead ? AppTheme.gray400 : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            msg.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight:
                                  msg.isRead ? FontWeight.w500 : FontWeight.w700,
                              color: AppColors.gray800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!msg.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      msg.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray500,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: AppColors.gray400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(msg.createdAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gray400,
                            fontSize: 11,
                          ),
                        ),
                        if (msg.sender != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            LucideIcons.user,
                            size: 12,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            msg.sender!.fullName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.gray400,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageDetail(MessageModel msg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            LucideIcons.megaphone,
                            size: 24,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.title,
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: AppColors.gray800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(msg.createdAt),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (msg.sender != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gray50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.userCheck,
                              size: 14,
                              color: AppColors.gray500,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dari: ${msg.sender!.fullName}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.gray600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Divider(color: AppTheme.gray200),
                    const SizedBox(height: 20),
                    Text(
                      msg.message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray700,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
