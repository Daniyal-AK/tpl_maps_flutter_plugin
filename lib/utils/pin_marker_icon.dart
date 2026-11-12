import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Draws a simple colored map-pin (teardrop) icon at runtime and returns it
/// as a base64 PNG data URI, for use with
/// `TplMapsViewController.addCustomMarkerBase64`. Generated instead of
/// bundling per-color PNG assets so any color can be used without adding
/// new files.
Future<String> generatePinMarkerDataUri({
  required Color color,
  double size = 96,
}) async {
  final double width = size;
  final double height = size * 1.25;
  final double headRadius = width / 2 - 2;
  final Offset headCenter = Offset(width / 2, headRadius + 2);

  final Path head = Path()
    ..addOval(Rect.fromCircle(center: headCenter, radius: headRadius));

  final double tipHalfWidth = headRadius * 0.55;
  final Path tip = Path()
    ..moveTo(headCenter.dx - tipHalfWidth, headCenter.dy + headRadius * 0.75)
    ..lineTo(width / 2, height - 2)
    ..lineTo(headCenter.dx + tipHalfWidth, headCenter.dy + headRadius * 0.75)
    ..close();

  final Path pin = Path.combine(PathOperation.union, head, tip);

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

  canvas.drawPath(pin, Paint()..color = color);
  canvas.drawPath(
    pin,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.06,
  );
  canvas.drawCircle(headCenter, headRadius * 0.35, Paint()..color = Colors.white);

  final ui.Image image = await recorder.endRecording().toImage(
        width.round(),
        height.round(),
      );
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List bytes = byteData!.buffer.asUint8List();
  return 'data:image/png;base64,${base64Encode(bytes)}';
}
