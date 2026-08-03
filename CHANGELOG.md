# Changelog

## 0.3.0

- Device attestation: the underlying native SDKs now prove app authenticity via
  App Attest (iOS) / Play Integrity (Android) when the app's attestation mode is
  enabled in the EngagePop dashboard. No Dart-side changes required.

## 0.2.5

- Initial public release: native push notifications, in-app popups, notification
  inbox, deep links, identify/track/convert — bridging the native EngagePop
  iOS and Android SDKs via platform channels.
