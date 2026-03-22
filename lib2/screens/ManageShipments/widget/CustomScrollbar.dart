import 'package:adaptive_scrollbar/adaptive_scrollbar.dart';
import 'package:flutter/material.dart';

class CustomScrollbar extends StatefulWidget {
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;
  final Widget child;
  final double contentWidth;

  CustomScrollbar({
    super.key,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    required this.child,
    this.contentWidth = 2000.0, // Default fallback
  });

  @override
  State<CustomScrollbar> createState() => _CustomScrollbarState();
}

class _CustomScrollbarState extends State<CustomScrollbar> {
  late ScrollController _syncedHorizontalController;

  @override
  void initState() {
    super.initState();
    _syncedHorizontalController = ScrollController();

    //Sync the two horizontal controllers
    widget.horizontalScrollController.addListener(_syncScrollPositions);
    _syncedHorizontalController.addListener(_syncScrollPositions);
  }

  void _syncScrollPositions() {
    if (widget.horizontalScrollController.hasClients &&
        _syncedHorizontalController.hasClients) {
      if (widget.horizontalScrollController.offset !=
          _syncedHorizontalController.offset) {
        if (widget
            .horizontalScrollController.position.isScrollingNotifier.value) {
          _syncedHorizontalController
              .jumpTo(widget.horizontalScrollController.offset);
        } else if (_syncedHorizontalController
            .position.isScrollingNotifier.value) {
          widget.horizontalScrollController
              .jumpTo(_syncedHorizontalController.offset);
        }
      }
    }
  }

  @override
  void dispose() {
    widget.horizontalScrollController.removeListener(_syncScrollPositions);
    _syncedHorizontalController.removeListener(_syncScrollPositions);
    _syncedHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AdaptiveScrollbar(
            position: ScrollbarPosition.left,
            underColor: Colors.blueGrey.withOpacity(0.3),
            sliderDefaultColor: Colors.grey.withOpacity(0.7),
            sliderActiveColor: Colors.grey,
            controller: widget.verticalScrollController,
            child: SingleChildScrollView(
              controller: widget.verticalScrollController,
              scrollDirection: Axis.vertical,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  controller: widget.horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
        // Fixed horizontal scrollbar at the bottom
        Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
              ),
            ),
            child: Scrollbar(
              controller: _syncedHorizontalController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _syncedHorizontalController,
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: widget.contentWidth,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
