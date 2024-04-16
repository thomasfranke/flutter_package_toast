import 'dart:async';
import 'package:flutter/material.dart';
import 'package:toast/widgets/toast_widget.dart';
import '/exports.dart';

enum FToastPosition { top, bottom, center, topLeft, topRight, bottomLeft, bottomRight, centerLeft, centerRight, snackbarBottom, snackbarTop, none }

enum FToastType { all, warning, fail }

/// Signature for a function to buildCustom Toast
typedef PositionedToastBuilder = Widget Function(BuildContext context, Widget child);

class FToast {
  BuildContext? context;
  FToast._internal();

  OverlayEntry? _entry;
  final List<_ToastEntry> _overlayQueue = [];
  Timer? _timer;
  Timer? _fadeTimer;

  static final FToast _instance = FToast._internal();

  /// Prmary Constructor for FToast
  factory FToast() {
    return _instance;
  }

  /// Take users Context and saves to avariable
  FToast init(BuildContext context) {
    _instance.context = context;
    return _instance;
  }

  void showToast({
    // required Widget child,
    required String message,
    required bool serverStatus,
    required bool responseStatus,
    required FToastType type,
    PositionedToastBuilder? positionedToastBuilder,
    Duration toastDuration = const Duration(milliseconds: 1500),
    FToastPosition? position,
    Duration fadeDuration = const Duration(milliseconds: 200),
    bool ignorePointer = false,
    bool isDismissable = true,
  }) {
    if (responseStatus && serverStatus && type == FToastType.warning || serverStatus && type == FToastType.fail) {
      log('- ShowToast: DISMISSED | response: $responseStatus | server: $serverStatus | type: $type | message: $message | $message');
      return;
    }

    log('- ShowToast: SHOW | response: $responseStatus | server: $serverStatus | type: $type | message: $message | $message');
    if (context == null) throw ("Error: Context is null, Please call init(context) before showing toast.");

    Widget theWidget = ToastWidget(
      message: message,
      responseStatus: responseStatus,
      serverStatus: serverStatus,
      type: type,
      fToast: this,
      position: position ?? FToastPosition.bottom,
    );

    Widget newChild = _ToastStateFul(theWidget, toastDuration, fadeDuration, ignorePointer, !isDismissable ? null : () => removeCustomToast());
    if (position == FToastPosition.bottom) {
      if (MediaQuery.of(context!).viewInsets.bottom != 0) {
        position = FToastPosition.center;
      }
    }
    OverlayEntry newEntry = OverlayEntry(builder: (context) {
      if (positionedToastBuilder != null) return positionedToastBuilder(context, newChild);
      return _getPostionWidgetBasedOnPosition(newChild, position);
    });

    _overlayQueue.add(_ToastEntry(entry: newEntry, duration: toastDuration, fadeDuration: fadeDuration));

    if (_timer == null) {
      _showOverlay();
    }
  }

  _showOverlay() {
    if (_overlayQueue.isEmpty) {
      _entry = null;
      return;
    }
    if (context == null) {
      removeQueuedCustomToasts();
      throw ("Error: Context is null, Please call init(context) before showing toast.");
    }

    if (context?.mounted != true) {
      removeQueuedCustomToasts();
      return; // Or maybe thrown error too
    }
    OverlayState overlay;
    try {
      overlay = Overlay.of(context!);
    } catch (err) {
      removeQueuedCustomToasts();
      throw ("Error: Overlay is null.");
    }

    /// Create entry only after all checks
    _ToastEntry toastEntry = _overlayQueue.removeAt(0);
    _entry = toastEntry.entry;
    overlay.insert(_entry!);

    _timer = Timer(toastEntry.duration, () => _fadeTimer = Timer(toastEntry.fadeDuration, () => removeCustomToast()));
  }

  removeCustomToast() {
    _timer?.cancel();
    _fadeTimer?.cancel();
    _timer = null;
    _fadeTimer = null;
    _entry?.remove();
    _entry = null;
    _showOverlay();
  }

  removeQueuedCustomToasts() {
    _timer?.cancel();
    _fadeTimer?.cancel();
    _timer = null;
    _fadeTimer = null;
    _overlayQueue.clear();
    _entry?.remove();
    _entry = null;
  }

  _getPostionWidgetBasedOnPosition(Widget child, FToastPosition? position) {
    switch (position) {
      case FToastPosition.top:
        return Positioned(top: 100.0, left: 24.0, right: 24.0, child: child);
      case FToastPosition.topLeft:
        return Positioned(top: 100.0, left: 24.0, child: child);
      case FToastPosition.topRight:
        return Positioned(top: 100.0, right: 24.0, child: child);
      case FToastPosition.center:
        return Positioned(top: 50.0, bottom: 50.0, left: 24.0, right: 24.0, child: child);
      case FToastPosition.centerLeft:
        return Positioned(top: 50.0, bottom: 50.0, left: 24.0, child: child);
      case FToastPosition.centerRight:
        return Positioned(top: 50.0, bottom: 50.0, right: 24.0, child: child);
      case FToastPosition.bottomLeft:
        return Positioned(bottom: 50.0, left: 24.0, child: child);
      case FToastPosition.bottomRight:
        return Positioned(bottom: 50.0, right: 24.0, child: child);
      case FToastPosition.snackbarTop:
        return Positioned(top: 0, left: 0, right: 0, child: child);
      case FToastPosition.snackbarBottom:
        return Positioned(bottom: 0, left: 0, right: 0, child: child);
      case FToastPosition.none:
        return Positioned.fill(child: child);
      case FToastPosition.bottom:
      default:
        return Positioned(bottom: 50.0, left: 24.0, right: 24.0, child: child);
    }
  }
}

class _ToastEntry {
  final OverlayEntry entry;
  final Duration duration;
  final Duration fadeDuration;

  _ToastEntry({required this.entry, required this.duration, required this.fadeDuration});
}

class _ToastStateFul extends StatefulWidget {
  const _ToastStateFul(this.child, this.duration, this.fadeDuration, this.ignorePointer, this.onDismiss);

  final Widget child;
  final Duration duration;
  final Duration fadeDuration;
  final bool ignorePointer;
  final VoidCallback? onDismiss;

  @override
  ToastStateFulState createState() => ToastStateFulState();
}

/// State for [_ToastStateFul]
class ToastStateFulState extends State<_ToastStateFul> with SingleTickerProviderStateMixin {
  /// Start the showing animations for the toast
  showIt() {
    _animationController!.forward();
  }

  /// Start the hidding animations for the toast
  hideIt() {
    _animationController!.reverse();
    _timer?.cancel();
  }

  /// Controller to start and hide the animation
  AnimationController? _animationController;
  late Animation _fadeAnimation;

  Timer? _timer;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController!, curve: Curves.easeIn);
    super.initState();

    showIt();
    _timer = Timer(widget.duration, () {
      hideIt();
    });
  }

  @override
  void deactivate() {
    _timer?.cancel();
    _animationController!.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss == null ? null : () => widget.onDismiss!(),
      behavior: HitTestBehavior.translucent,
      child: IgnorePointer(
        ignoring: widget.ignorePointer,
        child: FadeTransition(
          opacity: _fadeAnimation as Animation<double>,
          child: Center(
            child: Material(color: Colors.transparent, child: widget.child),
          ),
        ),
      ),
    );
  }
}
