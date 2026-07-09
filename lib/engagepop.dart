import 'package:flutter/services.dart';

/// EngagePop Flutter SDK — native push + in-app messages, bridging the native
/// iOS + Android SDKs via platform channels. No delivery logic lives in Dart, so
/// behaviour matches the native SDKs (and web) exactly.
class EngagePop {
  EngagePop._();

  static const MethodChannel _channel = MethodChannel('engagepop');
  static const EventChannel _deepLinkChannel = EventChannel('engagepop/deeplinks');

  /// Configure the SDK. Call once, as early as possible.
  static Future<void> configure(
    String siteKey,
    String appKey, {
    String? apiBaseUrl,
    bool debugLogging = false,
  }) {
    return _channel.invokeMethod('configure', <String, dynamic>{
      'siteKey': siteKey,
      'appKey': appKey,
      if (apiBaseUrl != null) 'apiBaseUrl': apiBaseUrl,
      'debugLogging': debugLogging,
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
}
