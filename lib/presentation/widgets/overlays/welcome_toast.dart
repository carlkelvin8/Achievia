import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets app-level toasts share one screen position: the toast with the higher
/// priority wins, so two cards are never stacked or left with two barriers.
class ToastSlot {
  VoidCallback? _release;
  int _priority = -1;

  bool get isOccupied => _release != null;

  /// Returns false if a toast of equal or higher priority is already visible.
  bool claim(int priority, VoidCallback dismiss) {
    final previous = _release;
    if (previous != null && priority <= _priority) return false;
    _release = dismiss;
    _priority = priority;
    previous?.call();
    return true;
  }

  void release(VoidCallback dismiss) {
    if (_release == dismiss) {
      _release = null;
      _priority = -1;
    }
  }
}

final toastSlotProvider = Provider<ToastSlot>((ref) => ToastSlot());

/// Shows and dismisses the floating welcome message on the enclosing
/// [Overlay]. At most one entry exists at a time; [dismissNow] and [dispose]
/// remove it immediately. Wrap the owning screen in [WelcomeToastHost] so the
/// message is also removed when that screen stops being the current route.
class WelcomeToastController {
  WelcomeToastController({ToastSlot? slot, this.priority = 0}) : _slot = slot;

  final ToastSlot? _slot;
  final int priority;
  OverlayEntry? _entry;

  bool get isShowing => _entry != null;

  void show(BuildContext context, String message) =>
      showIn(Overlay.maybeOf(context), message);

  /// Inserts the toast into [overlay]. Ignored while a toast of equal or
  /// higher priority owns the shared [ToastSlot]; a lower one is dismissed.
  void showIn(OverlayState? overlay, String message) {
    if (_entry != null || overlay == null) return;
    if (_slot?.claim(priority, dismissNow) == false) return;
    final entry = OverlayEntry(
      builder: (_) => WelcomeToast(message: message, onFinished: _remove),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  void _remove() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    _slot?.release(dismissNow);
    entry.remove();
    entry.dispose();
  }

  /// Removes the message immediately, skipping the fade-out.
  void dismissNow() => _remove();

  void dispose() => _remove();
}

/// Ties a [WelcomeToastController] to the route that contains [child]: the
/// message is removed as soon as that route is no longer the current one
/// (another page or dialog was pushed) and when the route is disposed.
class WelcomeToastHost extends StatefulWidget {
  const WelcomeToastHost({
    super.key,
    required this.controller,
    required this.child,
  });

  final WelcomeToastController controller;
  final Widget child;

  @override
  State<WelcomeToastHost> createState() => _WelcomeToastHostState();
}

class _WelcomeToastHostState extends State<WelcomeToastHost> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.isCurrentOf(context) == false) {
      widget.controller.dismissNow();
    }
  }

  @override
  void dispose() {
    widget.controller.dismissNow();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class WelcomeToast extends StatefulWidget {
  const WelcomeToast({
    super.key,
    required this.message,
    required this.onFinished,
    this.visibleFor = const Duration(seconds: 5),
  });

  final String message;
  final VoidCallback onFinished;
  final Duration visibleFor;

  @override
  State<WelcomeToast> createState() => _WelcomeToastState();
}

class _WelcomeToastState extends State<WelcomeToast>
    with SingleTickerProviderStateMixin {
  static const _fade = Duration(milliseconds: 250);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _fade,
    reverseDuration: _fade,
  );
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.visibleFor, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    setState(() => _dismissing = true);
    _timer?.cancel();
    try {
      await _controller.reverse().orCancel;
    } on TickerCanceled {
      return;
    }
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Semi-transparent gray backdrop that dims the screen behind the
        // greeting. It is also the barrier: the first pointer outside the
        // card only dismisses the message and is never delivered to the
        // screen beneath. Once dismissal starts the barrier ignores hits, so
        // the fade-out never blocks scrolling, taps or navigation.
        IgnorePointer(
          ignoring: _dismissing,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _dismiss(),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ),
              child: const SizedBox.expand(
                child: ColoredBox(
                  key: ValueKey('welcome-backdrop'),
                  color: Color(0x99424242),
                ),
              ),
            ),
          ),
        ),
        // Exact center of the screen (not of the safe area), horizontally
        // and vertically, on every screen size.
        Center(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (width - 32).clamp(200.0, 360.0),
                ),
                child: Material(
                  key: const ValueKey('welcome-card'),
                  color: theme.colorScheme.surface,
                  elevation: 6,
                  shadowColor: Colors.black38,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
