# engagepop (Flutter)

EngagePop for Flutter — native push notifications and in-app messages, bridging
the native EngagePop iOS + Android SDKs via platform channels.

## Install

```yaml
dependencies:
  engagepop: ^0.1.0
```

Platform prerequisites: **iOS** — Push Notifications capability; **Android** —
Firebase (`google-services.json` + the Google Services plugin).

## Usage

```dart
import 'package:engagepop/engagepop.dart';

await EngagePop.configure('ep_…', 'epm_…');

final granted = await EngagePop.requestPushPermission();

await EngagePop.identify({'name': 'Sarah', 'plan': 'Pro'});
await EngagePop.track('purchase', properties: {'product': 'Blue Sneakers'});
await EngagePop.convert(49.99, order: 'order-1234', campaignId: 12);

EngagePop.deepLinks.listen((url) {
  // navigate to url
});

await EngagePop.refreshInAppMessages();
```

## Notification inbox / bell

```dart
final messages = await EngagePop.getInbox();   // newest first
final unread   = await EngagePop.unreadCount(); // bind to a badge

await EngagePop.markRead(message.id);
await EngagePop.markAllRead();
await EngagePop.clearInbox();

// Refresh your bell when it changes:
EngagePop.inboxChanges.listen((_) { /* reload */ });
```

To control where/when in-app popups appear, pass
`autoShowInAppMessages: false` to `configure` and call
`EngagePop.refreshInAppMessages()` on the screens where a popup is appropriate.

## Native glue

Same small wiring as any push plugin:

### iOS — forward the APNs token (AppDelegate)

```swift
override func application(
  _ application: UIApplication,
  didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
  EngagePop.setDeviceToken(deviceToken)
}
```

### Android — forward taps (MainActivity)

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
  super.onCreate(savedInstanceState)
  EngagePop.handleNotificationOpen(intent)
}
override fun onNewIntent(intent: Intent) {
  super.onNewIntent(intent)
  EngagePop.handleNotificationOpen(intent)
}
```

## Notes

- No delivery logic lives in Dart — the plugin delegates to the native cores, so
  push, targeting, A/B, and in-app rendering behave identically to the native
  SDKs and web.
- Published from the monorepo (`sdks/flutter`) to pub.dev.
