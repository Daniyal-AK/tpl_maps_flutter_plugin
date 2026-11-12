# tplmaps_flutter_demo

TPL Maps Flutter Plugin Sample Application to Demonstrate Features (plugin version 2.0.7).

## Setup

This repo ships without an API key. Before running the app, add your own TPL Maps API key in **both** of these places (they must match):

1. `android/app/src/main/AndroidManifest.xml` — the `com.tplmaps.android.sdk.API_KEY` meta-data value.
2. `lib/config/app_config.dart` — the `AppConfig.apiKey` constant.

Then:

```
flutter pub get
flutter run
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
