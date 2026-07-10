# engagepop (Flutter)

EngagePop for Flutter — native push notifications and in-app messages, bridging
the native EngagePop iOS + Android SDKs via platform channels.

## Install

```yaml
dependencies:
  engagepop: ^0.2.5
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

## Targeting

Attributes passed to `identify()` drive targeting across EngagePop:

- **Push audience filters** — in the dashboard push composer, add a filter like
  `plan is Pro`: the notification only reaches devices whose identify
  attributes match every filter.
- **Popup "User attribute" conditions** *(0.2.5+)* — popup campaigns can target
  the same attributes (e.g. show an offer only when `plan is Pro`). Older SDK
  versions skip the condition, so update before gating exclusive content on it.
- **`{{merge tags}}`** in popups.

## Delivery receipts

The dashboard's Sent → Delivered → Opened funnel needs a "delivered" signal
from the device:

- **Android** — automatic (reported when the FCM handler runs; pure
  background `notification`-type messages are counted when tapped).
- **iOS** — add a **Notification Service Extension** target in Xcode whose
  class subclasses `EngagePopNotificationService` (the same extension that
  enables rich push images — see the
  [iOS SDK README](https://github.com/rajgupttaa/engagepop-ios-SDK#delivery-receipts)
  for the two-line subclass).

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
