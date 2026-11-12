# TPL Maps Flutter Plugin — Sample App

A sample Flutter application demonstrating the features of
[`tplmapsflutterplugin`](https://pub.dev/packages/tplmapsflutterplugin)
version **2.0.7**. It's organized as six screens, each focused on one area
of the plugin's API:

| Screen | Demonstrates |
|---|---|
| Map Settings & Gestures | Day/night mode, zoom controls, gestures, POIs, compass, a custom "locate me" button |
| Markers | Plain markers, resized default pins, custom image markers, markers with info windows, draggable markers |
| Shapes | Circles and polygons |
| Polylines | Straight and multi-point polylines |
| Routing | Turn-by-turn-style route drawing with distance/time, multi-stop optimal routing |
| Search & Reverse-Geocode | Place search with live autocomplete, tap-to-get-directions, reverse geocoding (Android only) |

This repo exists to give a working reference for every major plugin call —
including a few native plugin bugs this project found and worked around
(see **Known plugin gotchas** below), so you don't have to rediscover them.

## Quick start — run this demo

1. Clone the repo and check out this branch.
2. Add your own TPL Maps API key in **both** of these places (they must match):
   - `android/app/src/main/AndroidManifest.xml` — the `com.tplmaps.android.sdk.API_KEY` meta-data value.
   - `lib/config/app_config.dart` — the `AppConfig.apiKey` constant.
3. Run it:
   ```
   flutter pub get
   flutter run
   ```

Android is the fully-supported platform here — a few screens explicitly say
"Android only" where the plugin itself has no iOS handler (see below).

## Using `tplmapsflutterplugin` in your own project

### 1. Add the dependency

```yaml
dependencies:
  tplmapsflutterplugin: 2.0.7
```

### 2. Android setup

Add your API key as `AndroidManifest.xml` meta-data, inside `<application>`:

```xml
<meta-data android:name="com.tplmaps.android.sdk.API_KEY"
    android:value="YOUR_TPL_MAPS_API_KEY" />
```

Add location permissions if you'll use the device's own GPS position for
anything (the plugin's own my-location button doesn't work — see below):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

If you enable R8/ProGuard for release builds, add this rule
(`android/app/proguard-rules.pro`) — without it, release builds fail with
"Missing classes" errors from an optional TLS provider pulled in
transitively by the plugin's networking stack:

```proguard
-dontwarn org.bouncycastle.jsse.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
```

### 3. iOS setup

The plugin's iOS support is noticeably thinner than Android's in 2.0.7 —
custom base64 markers without an info window, `setZoomFixedCenter`,
`cancelMapRequest`/`pauseMapRequest`, and the entire place-search channel
have no native iOS handler at all. Budget for Android-first development if
you need those.

### 4. Minimal usage example

```dart
TplMapsView(
  isShowBuildings: true,
  isZoomEnabled: true,
  showZoomControls: true,
  // Leave both of these false — see "my-location crashes" below.
  myLocationButtonEnabled: false,
  setMyLocationEnabled: false,
  tplMapsViewCreatedCallback: (controller) {
    controller.setCameraPositionAnimated(24.8607, 67.0011, 14.0);
  },
)
```
  firing them concurrently — see `lib/screens/search_screen.dart`'s
  `_queueSearch`/`_pendingQuery` for a working pattern.
