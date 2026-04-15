import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache freshness states
enum CacheFreshness { fresh, stale, expired, none }

/// Central caching service using SharedPreferences.
///
/// Strategy: stale-while-revalidate
/// - FRESH  (< freshDuration)  → return cache, skip API
/// - STALE  (< staleDuration)  → return cache, background API refresh
/// - EXPIRED (> staleDuration) → return cache while fetching, force API
/// - NONE                      → no cache, must fetch from API
class CacheService {
  // Singleton
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _prefix = 'cache_';

  static const Duration defaultFreshDuration = Duration(minutes: 5);
  static const Duration defaultStaleDuration = Duration(hours: 2);

  // In-memory hot cache for the current session
  final Map<String, _CacheEntry> _memoryCache = {};

  /// Get cached data. Returns null if nothing cached.
  Future<Map<String, dynamic>?> get(String key) async {
    // Check memory first
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!.data;
    }

    // Then check disk
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;

      final envelope = json.decode(raw) as Map<String, dynamic>;
      final data = envelope['data'] as Map<String, dynamic>;
      final cachedAt = DateTime.parse(envelope['cached_at'] as String);

      // Populate memory cache
      _memoryCache[key] = _CacheEntry(data: data, cachedAt: cachedAt);

      return data;
    } catch (_) {
      return null;
    }
  }

  /// Save data to both memory and disk cache.
  Future<void> set(String key, Map<String, dynamic> data) async {
    final now = DateTime.now();

    // Memory
    _memoryCache[key] = _CacheEntry(data: data, cachedAt: now);

    // Disk
    try {
      final prefs = await SharedPreferences.getInstance();
      final envelope = json.encode({
        'data': data,
        'cached_at': now.toIso8601String(),
      });
      await prefs.setString('$_prefix$key', envelope);
    } catch (_) {
      // Disk write failure is non-critical
    }
  }

  /// Check the freshness of a cached entry.
  Future<CacheFreshness> freshness(
    String key, {
    Duration freshDuration = defaultFreshDuration,
    Duration staleDuration = defaultStaleDuration,
  }) async {
    DateTime cachedAt;

    // Check memory
    if (_memoryCache.containsKey(key)) {
      cachedAt = _memoryCache[key]!.cachedAt;
    } else {
      // Check disk
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('$_prefix$key');
        if (raw == null) return CacheFreshness.none;

        final envelope = json.decode(raw) as Map<String, dynamic>;
        cachedAt = DateTime.parse(envelope['cached_at'] as String);
      } catch (_) {
        return CacheFreshness.none;
      }
    }

    final age = DateTime.now().difference(cachedAt);

    if (age < freshDuration) return CacheFreshness.fresh;
    if (age < staleDuration) return CacheFreshness.stale;
    return CacheFreshness.expired;
  }

  /// Remove a specific cache entry.
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
    } catch (_) {}
  }

  /// Remove all entries whose key starts with [prefix].
  Future<void> removeByPrefix(String prefix) async {
    _memoryCache.removeWhere((k, _) => k.startsWith(prefix));
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((k) => k.startsWith('$_prefix$prefix'));
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  /// Clear ALL cache entries (call on logout).
  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      for (final k in keys.toList()) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}

class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  _CacheEntry({required this.data, required this.cachedAt});
}
