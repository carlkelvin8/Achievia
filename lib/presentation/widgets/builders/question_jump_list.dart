import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

/// A lazily built list of exam questions with a slim draggable scrollbar on
/// the right edge.
///
/// Dragging the rounded handle shows "Question 425 of 600" next to it and
/// jumps straight to that question, even hundreds of items away. On release
/// the question is aligned to the top of the list. The bar is faint while
/// reading and fully visible while it is touched or the list scrolls.
///
/// Questions have different heights, so each one's height is measured as it
/// is built; jumps use those heights and the average for the rest, then the
/// target is aligned exactly once it is on screen.
class QuestionJumpList extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;

  /// "Question" in "Question 425 of 600".
  final String itemLabel;

  const QuestionJumpList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.itemLabel = 'Question',
  });

  @override
  State<QuestionJumpList> createState() => _QuestionJumpListState();
}

class _QuestionJumpListState extends State<QuestionJumpList> {
  static const double _trackWidth = 28;
  static const double _handleWidth = 6;
  static const double _handleHeight = 44;
  static const double _idleOpacity = 0.35;

  final _controller = ScrollController();
  final Map<int, double> _heights = {};
  final Map<int, GlobalKey> _keys = {};

  /// Set while the handle is held: the question it points at.
  int? _dragIndex;
  double _dragFraction = 0;
  bool _active = false;
  Timer? _fade;
  int _alignToken = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _fade?.cancel();
    _controller.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int index) => _keys.putIfAbsent(index, GlobalKey.new);

  double get _averageHeight => _heights.isEmpty
      ? 240
      : _heights.values.reduce((a, b) => a + b) / _heights.length;

  double get _topPadding =>
      widget.padding?.resolve(Directionality.of(context)).top ?? 0;

  /// Where question [index] starts: measured heights where known, the
  /// average for the rest.
  double _offsetOf(int index) {
    final average = _averageHeight;
    var offset = _topPadding;
    for (var i = 0; i < index; i++) {
      offset += _heights[i] ?? average;
    }
    return offset;
  }

  void _wake() {
    _fade?.cancel();
    if (!_active) setState(() => _active = true);
    if (_dragIndex != null) return;
    _fade = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _dragIndex == null) setState(() => _active = false);
    });
  }

  void _onScroll() {
    if (_dragIndex == null) {
      _wake();
      setState(() {});
    }
  }

  void _jumpTo(double offset) {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    _controller.jumpTo(offset.clamp(0, position.maxScrollExtent));
  }

  void _drag(double dy, double trackHeight) {
    final travel = trackHeight - _handleHeight;
    final fraction = travel <= 0
        ? 0.0
        : ((dy - _handleHeight / 2) / travel).clamp(0.0, 1.0);
    final index = (fraction * (widget.itemCount - 1)).round();
    _fade?.cancel();
    setState(() {
      _active = true;
      _dragFraction = fraction;
      _dragIndex = index;
    });
    _jumpTo(_offsetOf(index));
  }

  void _release() {
    final index = _dragIndex;
    setState(() => _dragIndex = null);
    _wake();
    if (index != null) _alignTo(index);
  }

  /// Puts question [index] at the top. It may not be built yet after the
  /// first jump (estimated heights), so this repeats with the heights
  /// measured meanwhile until the item exists, then aligns it exactly.
  void _alignTo(int index, {int attempt = 0}) {
    final token = ++_alignToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || token != _alignToken) return;
      final itemContext = _keys[index]?.currentContext;
      if (itemContext != null) {
        Scrollable.ensureVisible(itemContext, alignment: 0);
        return;
      }
      if (attempt >= 6) return;
      _jumpTo(_offsetOf(index));
      _alignTo(index, attempt: attempt + 1);
    });
  }

  double get _scrollFraction {
    if (!_controller.hasClients) return 0;
    final position = _controller.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      return 0;
    }
    return (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = ListView.builder(
      controller: _controller,
      padding: widget.padding,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => _MeasuredItem(
        key: _keyFor(index),
        onHeight: (height) => _heights[index] = height,
        child: widget.itemBuilder(context, index),
      ),
    );
    if (widget.itemCount < 2) return list;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = constraints.maxHeight;
        final fraction = _dragIndex != null ? _dragFraction : _scrollFraction;
        final handleTop = fraction * (trackHeight - _handleHeight);
        final dragging = _dragIndex != null;
        return Stack(
          children: [
            Positioned.fill(child: list),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: _trackWidth,
              child: GestureDetector(
                key: const ValueKey('question-jump-track'),
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: (d) =>
                    _drag(d.localPosition.dy, trackHeight),
                onVerticalDragUpdate: (d) =>
                    _drag(d.localPosition.dy, trackHeight),
                onVerticalDragEnd: (_) => _release(),
                onVerticalDragCancel: _release,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _active ? 1 : _idleOpacity,
                  child: Stack(
                    children: [
                      Positioned(
                        top: handleTop,
                        right: 4,
                        child: AnimatedContainer(
                          key: const ValueKey('question-jump-handle'),
                          duration: const Duration(milliseconds: 120),
                          width: dragging ? _handleWidth + 2 : _handleWidth,
                          height: _handleHeight,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (dragging)
              Positioned(
                top: (handleTop + _handleHeight / 2 - 16).clamp(
                  0.0,
                  (trackHeight - 32).clamp(0.0, double.infinity),
                ),
                right: _trackWidth + 4,
                child: IgnorePointer(
                  child: Material(
                    key: const ValueKey('question-jump-indicator'),
                    elevation: 3,
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      child: Text(
                        '${widget.itemLabel} ${_dragIndex! + 1} of '
                        '${widget.itemCount}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Reports its child's height after every layout.
class _MeasuredItem extends SingleChildRenderObjectWidget {
  final ValueChanged<double> onHeight;

  const _MeasuredItem({
    super.key,
    required this.onHeight,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasured(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasured renderObject) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderMeasured extends RenderProxyBox {
  _RenderMeasured(this.onHeight);

  ValueChanged<double> onHeight;

  @override
  void performLayout() {
    super.performLayout();
    onHeight(size.height);
  }
}
