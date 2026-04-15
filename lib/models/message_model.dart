class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final MessageSender? sender;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.title,
    required this.message,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'])
          : null,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      sender: json['sender'] != null
          ? MessageSender.fromJson(json['sender'])
          : null,
    );
  }
}

class MessageSender {
  final String id;
  final String fullName;
  final String role;
  final String? profilUrl;

  MessageSender({
    required this.id,
    required this.fullName,
    required this.role,
    this.profilUrl,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? '',
      profilUrl: json['profil_url'],
    );
  }
}
