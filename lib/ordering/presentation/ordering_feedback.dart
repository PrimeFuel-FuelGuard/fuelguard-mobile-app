import 'package:material_ui/material_ui.dart';

import '../../shared/infrastructure/i18n/translate_service.dart';

/// Diálogo de confirmación; `true` solo si el usuario confirma.
Future<bool> confirmAction(
  BuildContext context, {
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.tr('confirm.title')),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(dialogContext.tr('confirm.cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Hoja inferior para escribir un texto obligatorio (motivo, referencia). Devuelve el texto sin
/// espacios o `null` si se cierra sin confirmar.
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  String? message,
  int? maxLength = 240,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _TextInputSheet(
    title: title,
    label: label,
    confirmLabel: confirmLabel,
    message: message,
    maxLength: maxLength,
  ),
);

/// Muestra cada aviso nuevo del store (clave i18n) como SnackBar, una sola vez por aviso.
mixin NoticeSnackBars<T extends StatefulWidget> on State<T> {
  String _shownNotice = '';

  void showNotice(String notice) {
    if (notice.isEmpty) {
      _shownNotice = '';
      return;
    }
    if (notice == _shownNotice || !mounted) return;
    _shownNotice = notice;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr(notice))));
  }
}

class _TextInputSheet extends StatefulWidget {
  const _TextInputSheet({
    required this.title,
    required this.label,
    required this.confirmLabel,
    this.maxLength,
    this.message,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final String? message;
  final int? maxLength;

  @override
  State<_TextInputSheet> createState() => _TextInputSheetState();
}

class _TextInputSheetState extends State<_TextInputSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          if (widget.message != null) Text(widget.message!),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            maxLength: widget.maxLength,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
            ),
          ),
          FilledButton(
            onPressed: text.isEmpty ? null : () => Navigator.pop(context, text),
            child: Text(widget.confirmLabel),
          ),
        ],
      ),
    );
  }
}
