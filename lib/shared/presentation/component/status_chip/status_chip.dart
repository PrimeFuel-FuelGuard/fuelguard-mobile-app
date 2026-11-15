import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

enum StatusTone { neutral, pending, info, success, danger }

/// Etiqueta de estado coloreada (equivale a `.dl-badge.st-*`).
///
/// Pasa [status] (`PENDING`, `PAID`, …) para inferir el tono, o [tone] explícito.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.status, this.tone});

  final String label;
  final String? status;
  final StatusTone? tone;

  static StatusTone toneFor(String? status) =>
      switch ((status ?? '').toLowerCase()) {
        'pending' ||
        'created' ||
        'pending_payment' ||
        'pending_approval' => StatusTone.pending,
        'confirmed' || 'dispatched' || 'in_progress' => StatusTone.info,
        'paid' ||
        'delivered' ||
        'accepted' ||
        'approved' ||
        'completed' => StatusTone.success,
        'cancelled' || 'rejected' || 'failed' || 'revoked' => StatusTone.danger,
        _ => StatusTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone ?? toneFor(status)) {
      StatusTone.pending => (const Color(0xFFFFF1D6), const Color(0xFF7A4100)),
      StatusTone.info => (const Color(0xFFE6EDFF), FgColors.primary),
      StatusTone.success => (const Color(0xFFDFF3E6), const Color(0xFF14532D)),
      StatusTone.danger => (const Color(0xFFFDE8E8), const Color(0xFF8A1C1C)),
      StatusTone.neutral => (const Color(0xFFECEFF1), const Color(0xFF37474F)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
