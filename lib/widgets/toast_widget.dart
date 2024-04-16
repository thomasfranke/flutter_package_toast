import 'package:flutter/material.dart';
import '/exports.dart';

class ToastWidget extends StatelessWidget {
  final bool serverStatus;
  final bool responseStatus;
  final String message;
  final FToastType type;
  final Icon? icon;
  final FToast fToast;
  final FToastPosition position;
  const ToastWidget({
    super.key,
    required this.message,
    required this.responseStatus,
    required this.fToast,
    required this.position,
    this.icon,
    required this.type,
    required this.serverStatus,
  });

  @override
  Widget build(BuildContext context) {
    double safeAreaBottom = 12;
    if (position == FToastPosition.snackbarBottom) safeAreaBottom = MediaQuery.of(context).padding.bottom + safeAreaBottom;
    double safeAreaTop = 12;
    if (position == FToastPosition.snackbarTop) safeAreaTop = MediaQuery.of(context).padding.top + safeAreaTop;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 10.0, right: 10.0, top: safeAreaTop, bottom: safeAreaBottom),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.black.withOpacity(0.9),
      ),
      child: Row(
        children: [
          const SizedBox(width: 5.0),
          icon ??
              (!responseStatus || !serverStatus
                  ? const Icon(Icons.cancel, color: Colors.red, size: 30.0)
                  : const Icon(Icons.check_circle, color: Colors.green, size: 30.0)),
          const SizedBox(width: 15.0),
          Expanded(
            child: Center(
                child: Padding(
              padding: const EdgeInsets.only(right: 50.0),
              child: Text(message, textAlign: TextAlign.center),
            )),
          ),
        ],
      ),
    );
  }
}
