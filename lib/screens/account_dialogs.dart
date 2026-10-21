import 'package:flutter/material.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/l10n/l10n.dart';

/// A reusable account dialog used by Settings to change password or email.
class _AccountDialog extends StatefulWidget {
  final ApiService api;
  final bool emailMode;
  final String? initialEmail;

  const _AccountDialog({
    required this.api,
    required this.emailMode,
    this.initialEmail,
  });

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  late final TextEditingController first = TextEditingController(
    text: widget.emailMode ? (widget.initialEmail ?? '') : '',
  );
  late final TextEditingController second = TextEditingController();
  bool busy = false;
  String? error;

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.emailMode) {
        await widget.api.changeEmail(first.text.trim(), second.text);
      } else {
        await widget.api.changePassword(first.text, second.text);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.emailMode;
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        isEmail ? l10n.settingsChangeEmail : l10n.settingsChangePassword,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: first,
            obscureText: !isEmail,
            keyboardType: isEmail
                ? TextInputType.emailAddress
                : TextInputType.text,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: isEmail
                  ? l10n.accountNewEmail
                  : l10n.accountCurrentPassword,
              prefixIcon: Icon(
                isEmail ? Icons.alternate_email : Icons.lock_outline,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: second,
            obscureText: true,
            decoration: InputDecoration(
              labelText: isEmail
                  ? l10n.accountConfirmPassword
                  : l10n.accountNewPassword,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? l10n.commonSaving : l10n.commonSave),
        ),
      ],
    );
  }

  @override
  void dispose() {
    first.dispose();
    second.dispose();
    super.dispose();
  }
}

class PasswordDialog extends StatelessWidget {
  final ApiService api;
  const PasswordDialog({super.key, required this.api});

  @override
  Widget build(BuildContext context) =>
      _AccountDialog(api: api, emailMode: false);
}

class EmailDialog extends StatelessWidget {
  final ApiService api;
  final String? currentEmail;
  const EmailDialog({super.key, required this.api, this.currentEmail});

  @override
  Widget build(BuildContext context) =>
      _AccountDialog(api: api, emailMode: true, initialEmail: currentEmail);
}
