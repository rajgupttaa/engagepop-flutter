import 'package:flutter/services.dart';

/// EngagePop Flutter SDK — native push + in-app messages, bridging the native
/// iOS + Android SDKs via platform channels. No delivery logic lives in Dart, so
/// behaviour matches the native SDKs (and web) exactly.
class EngagePop {
  EngagePop._();

  static const MethodChannel _channel = MethodChannel('engagepop');
  static const EventChannel _deepLinkChannel = EventChannel('engagepop/deeplinks');
  static const EventChannel _inboxChannel = EventChannel('engagepop/inbox');

  /// Configure the SDK. Call once, as early as possible.
  static Future<void> configure(
    String siteKey,
    String appKey, {
    String? apiBaseUrl,
    bool debugLogging = false,
    bool autoShowInAppMessages = true,
  }) {
    return _channel.invokeMethod('configure', <String, dynamic>{
      'siteKey': siteKey,
      'appKey': appKey,
      if (apiBaseUrl != null) 'apiBaseUrl': apiBaseUrl,
      'debugLogging': debugLogging,
      'autoShowInAppMessages': autoShowInAppMessages,
    });
  }

  /// Ask for notification permission; resolves true if granted.
  static Future<bool> requestPushPermission() async {
    final granted = await _channel.invokeMethod<bool>('requestPushPermission');
    return granted ?? false;
  }

  /// Identify the current user for targeting + `{{merge tags}}`.
  static Future<void> identify(Map<String, String> attributes) {
    return _channel.invokeMethod('identify', <String, dynamic>{'attributes': attributes});
  }

  /// Record a custom event (e.g. a purchase).
  static Future<void> track(String event, {Map<String, String>? properties}) {
    return _channel.invokeMethod('track', <String, dynamic>{
      'event': event,
      'properties': properties ?? <String, String>{},
    });
  }

  /// Record a purchase; pass [campaignId] to attribute it to a campaign.
  static Future<void> convert(double value, {String? order, int? campaignId}) {
    return _channel.invokeMethod('convert', <String, dynamic>{
      'value': value,
      'order': order,
      'campaignId': campaignId ?? 0,
    });
  }

  /// Forget the current user's identify attributes (e.g. on logout).
  static Future<void> reset() => _channel.invokeMethod('reset');

  /// Re-check for in-app popups to show.
  static Future<void> refreshInAppMessages() => _channel.invokeMethod('refreshInAppMessages');

  /// Deep-link URLs from tapped pushes / popups. Listen to route the user.
  static Stream<String> get deepLinks =>
      _deepLinkChannel.receiveBroadcastStream().map((dynamic e) => e as String);

  // --- Notification inbox / bell ---

  /// All captured notifications, newest first.
  static Future<List<EngagePopMessage>> getInbox() async {
    final list = await _channel.invokeMethod<List<dynamic>>('getInbox') ?? <dynamic>[];
    return list
        .map((dynamic e) => EngagePopMessage.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Unread count — bind to your bell badge.
  static Future<int> unreadCount() async =>
      await _channel.invokeMethod<int>('unreadCount') ?? 0;

  static Future<void> markRead(String id) =>
      _channel.invokeMethod('markRead', <String, dynamic>{'id': id});

  static Future<void> markAllRead() => _channel.invokeMethod('markAllRead');

  static Future<void> removeMessage(String id) =>
      _channel.invokeMethod('removeMessage', <String, dynamic>{'id': id});

  static Future<void> clearInbox() => _channel.invokeMethod('clearInbox');

  /// Emits whenever the inbox changes — refresh your bell.
  static Stream<void> get inboxChanges =>
      _inboxChannel.receiveBroadcastStream().map((dynamic _) {});
}

/// One captured notification, for the in-app inbox / bell.
class EngagePopMessage {
  EngagePopMessage({
    required this.id,
    required this.title,
    required this.body,
    this.url,
    required this.receivedAt,
    required this.read,
  });

  final String id;
  final String title;
  final String body;
  final String? url;

  /// Seconds since epoch (iOS) / millis since epoch (Android) — treat as a sort key.
  final num receivedAt;
  final bool read;

  factory EngagePopMessage.fromMap(Map<String, dynamic> map) => EngagePopMessage(
        id: map['id'] as String,
        title: (map['title'] as String?) ?? '',
        body: (map['body'] as String?) ?? '',
        url: map['url'] as String?,
        receivedAt: (map['receivedAt'] as num?) ?? 0,
        read: (map['read'] as bool?) ?? false,
      );
}
