import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/logo/logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final manager = AppManager.instance;
  final username = TextEditingController();
  final password = TextEditingController();
  final email = TextEditingController();
  bool registering = false;
  bool busy = false;
  String? error;

  Future<void> openDeveloperOptions() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DeveloperOptionsDialog(
        initialApiUrl: manager.api.baseUrl,
        debugBuild: kDebugMode,
        onApiUrlChanged: (value) => manager.api.baseUrl = value,
        onTokenLogin: (value) async {
          await manager.loginWithToken(value);
          if (dialogContext.mounted) Navigator.pop(dialogContext, true);
        },
      ),
    );
    if (result == true && mounted) setState(() => error = null);
  }

  Future<void> submit() async {
    final l10n = context.l10n;
    if (username.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = l10n.usernamePasswordRequired);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (registering) {
        await manager.register(
          username.text.trim(),
          password.text,
          email.text.trim(),
        );
      } else {
        await manager.login(username.text.trim(), password.text);
      }
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (exception) {
      if (mounted) {
        setState(() => error = l10n.couldNotConnect(exception.toString()));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onLongPress: openDeveloperOptions,
                    child: Logo(variant: LogoVariant.textWithBgAlt, height: 76),
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  registering
                      ? l10n.loginCreateAccountTitle
                      : l10n.loginWelcomeBackTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  registering
                      ? l10n.loginJoinConversation
                      : l10n.loginSignInConversations,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: username,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.username,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: true,
                  onSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (registering) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.optionalEmail,
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(error!, style: TextStyle(color: colors.error)),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: busy ? null : submit,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(registering ? l10n.createAccount : l10n.signIn),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          registering = !registering;
                          error = null;
                        }),
                  child: Text(
                    registering ? l10n.alreadyHaveAccount : l10n.newToQutty,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    email.dispose();
    super.dispose();
  }
}

class _DeveloperOptionsDialog extends StatefulWidget {
  final String initialApiUrl;
  final bool debugBuild;
  final ValueChanged<String> onApiUrlChanged;
  final Future<void> Function(String) onTokenLogin;

  const _DeveloperOptionsDialog({
    required this.initialApiUrl,
    required this.debugBuild,
    required this.onApiUrlChanged,
    required this.onTokenLogin,
  });

  @override
  State<_DeveloperOptionsDialog> createState() =>
      _DeveloperOptionsDialogState();
}

class _DeveloperOptionsDialogState extends State<_DeveloperOptionsDialog> {
  late final TextEditingController apiUrl;
  final token = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    apiUrl = TextEditingController(text: widget.initialApiUrl);
  }

  Future<void> loginWithToken() async {
    final l10n = context.l10n;
    if (token.text.trim().isEmpty) {
      setState(() => error = l10n.enterJwtToken);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onTokenLogin(token.text);
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) setState(() => error = l10n.couldNotValidateToken);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.debugBuild
          ? context.l10n.quttyApiServiceDebugging
          : context.l10n.developerOptions,
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.debugBuild) ...[
          TextField(
            controller: apiUrl,
            keyboardType: TextInputType.url,
            onChanged: widget.onApiUrlChanged,
            decoration: InputDecoration(
              labelText: context.l10n.apiUrl,
              prefixIcon: Icon(Icons.cloud_outlined),
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: token,
          maxLines: 1,
          obscureText: true,
          decoration: InputDecoration(
            labelText: context.l10n.jwtToken,
            prefixIcon: Icon(Icons.key_outlined),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(error!, style: TextStyle(color: Colors.red)),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton.icon(
        onPressed: busy ? null : loginWithToken,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.login),
        label: Text(context.l10n.loginByToken),
      ),
    ],
  );

  @override
  void dispose() {
    apiUrl.dispose();
    token.dispose();
    super.dispose();
  }
}
