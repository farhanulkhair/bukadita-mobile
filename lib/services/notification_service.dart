import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'message_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final MessageService _messageService = MessageService();

  Timer? _pollingTimer;
  int? _lastKnownCount; // null = first poll (baseline, don't show popup)
  bool _initialized = false;

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  VoidCallback? onNotificationTapped;

  static const String _channelId = 'bukadita_messages';
  static const String _channelName = 'Pesan Admin';
  static const String _channelDesc = 'Notifikasi pesan dari admin BukaDita';

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        onNotificationTapped?.call();
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
        await androidPlugin.requestNotificationsPermission();
      }
    }

    _initialized = true;
  }

  void startPolling({Duration interval = const Duration(seconds: 15)}) {
    stopPolling();
    _pollNow();
    _pollingTimer = Timer.periodic(interval, (_) => _pollNow());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollNow() async {
    try {
      final result = await _messageService.getUnreadCount();
      if (result['success'] != true) return;

      final newCount = result['count'] as int? ?? 0;

      unreadCount.value = newCount;

      if (_lastKnownCount == null) {
        // First poll: just set baseline, don't show notification
        _lastKnownCount = newCount;
        return;
      }

      if (newCount > _lastKnownCount!) {
        final diff = newCount - _lastKnownCount!;
        await _showLocalNotification(
          title: 'Pesan Baru dari Admin',
          body: diff == 1
              ? 'Kamu memiliki 1 pesan baru'
              : 'Kamu memiliki $diff pesan baru',
        );
      }

      _lastKnownCount = newCount;
    } catch (_) {}
  }

  Future<void> refreshCount() async {
    try {
      final result = await _messageService.getUnreadCount();
      if (result['success'] == true) {
        final count = result['count'] as int? ?? 0;
        unreadCount.value = count;
        _lastKnownCount = count;
      }
    } catch (_) {}
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      ticker: 'Pesan baru BukaDita',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  void dispose() {
    stopPolling();
  }
}
