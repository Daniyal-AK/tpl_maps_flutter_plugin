import 'package:flutter/foundation.dart';

/// Several TPL Maps plugin features (custom base64 markers without an info
/// window, setZoomFixedCenter, cancelMapRequest/pauseMapRequest, and the
/// entire Places-search channel) only have a native handler on Android.
/// Uses the same `defaultTargetPlatform` check the plugin's own widget uses
/// internally, rather than `dart:io.Platform` (which throws on web).
bool get isTplMapsAndroid => defaultTargetPlatform == TargetPlatform.android;
