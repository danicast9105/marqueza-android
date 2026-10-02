import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum MarquezaAlertType { success, error, warning, info }

Future<void> showMarquezaAlert(
  BuildContext context, {
  required String title,
  required String text,
  required MarquezaAlertType type,
  String confirmText = 'OK',
}) {
  final cfg = _cfg(type);
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cfg.color.withValues(alpha: 0.35),
                  width: 4,
                ),
              ),
              child: Icon(cfg.icon, color: cfg.color, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  confirmText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

({Color color, IconData icon}) _cfg(MarquezaAlertType t) {
  switch (t) {
    case MarquezaAlertType.success:
      return (color: const Color(0xFF22C55E), icon: Icons.check_rounded);
    case MarquezaAlertType.error:
      return (color: const Color(0xFFEF4444), icon: Icons.close_rounded);
    case MarquezaAlertType.warning:
      return (
        color: const Color(0xFFF59E0B),
        icon: Icons.priority_high_rounded,
      );
    case MarquezaAlertType.info:
      return (color: const Color(0xFF3B82F6), icon: Icons.info_outline_rounded);
  }
}
