import 'package:flutter/material.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/l10n/l10n.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showUnhandledApiError(Object error, [StackTrace? stackTrace]) {
  if (error is! ApiException) return;

  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  final theme = rootScaffoldMessengerKey.currentContext != null
      ? Theme.of(rootScaffoldMessengerKey.currentContext!)
      : null;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: theme?.colorScheme.error ?? Colors.red.shade700,
        content: ApiErrorFooter(exception: error, stackTrace: stackTrace),
        duration: const Duration(days: 1),
        padding: EdgeInsets.zero,
      ),
    );
}

class ApiErrorFooter extends StatefulWidget {
  final ApiException exception;
  final StackTrace? stackTrace;

  const ApiErrorFooter({super.key, required this.exception, this.stackTrace});

  @override
  State<ApiErrorFooter> createState() => _ApiErrorFooterState();
}

class _ApiErrorFooterState extends State<ApiErrorFooter> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final detail = [
      l10n.errorHttpStatus(widget.exception.statusCode),
      widget.exception.message,
      if (widget.stackTrace != null) widget.stackTrace.toString(),
    ].join('\n');

    final onError = Theme.of(context).colorScheme.onError;

    return Semantics(
      button: true,
      label: l10n.errorShowDetails,
      child: InkWell(
        onTap: () => setState(() => expanded = !expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 12),
                child: Icon(Icons.error_outline, size: 20, color: onError),
              ),
              Expanded(
                child: expanded
                    ? SelectableText(
                        detail,
                        style: textTheme.bodyMedium?.copyWith(color: onError),
                      )
                    : Text(
                        widget.exception.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(color: onError),
                      ),
              ),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: onError,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
