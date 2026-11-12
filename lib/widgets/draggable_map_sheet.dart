import 'package:flutter/material.dart';

/// Full-bleed map with a draggable bottom sheet of controls over it.
///
/// Dragging the sheet to [minSize] leaves at least `1 - minSize` of the
/// screen as visible map (defaults to 0.12, i.e. ~88% map — comfortably
/// over the "at least 70%" target). Dragging it to [maxSize] surfaces the
/// rest of a screen's controls when they don't fit at [initialSize].
class DraggableMapSheet extends StatelessWidget {
  const DraggableMapSheet({
    super.key,
    required this.map,
    required this.children,
    this.overlayChildren = const <Widget>[],
    this.initialSize = 0.35,
    this.minSize = 0.12,
    this.maxSize = 0.85,
  });

  final Widget map;
  final List<Widget> children;
  final List<Widget> overlayChildren;
  final double initialSize;
  final double minSize;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: map),
        ...overlayChildren,
        DraggableScrollableSheet(
          initialChildSize: initialSize,
          minChildSize: minSize,
          maxChildSize: maxSize,
          builder: (BuildContext context, ScrollController scrollController) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Colors.black26, blurRadius: 8.0),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40.0,
                      height: 4.0,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  ...children,
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
