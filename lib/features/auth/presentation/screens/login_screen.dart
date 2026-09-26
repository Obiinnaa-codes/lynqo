import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_logo_placeholder.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/login_credential_field.dart';
import '../providers/login_controller.dart';

/// Debug-only character counts via console only (on-screen [ListenableBuilder]
/// rebuilds during typing and can disrupt iOS text input).
const _showLoginInputDiagnostics = false;

/// Login form with no Riverpod in the widget tree — avoids rebuilds that break
/// iOS Simulator text input. Router access uses [ProviderScope.containerOf].
///
/// [_LoginScreenState] never calls [setState]; loading and messages live in
/// [_LoginActionsPanel] so credential [TextField]s are not rebuilt on Connect.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _credentialsKey = GlobalKey<_LoginCredentialsPanelState>();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _usernameController.addListener(_logUsernameLength);
      _passwordController.addListener(_logPasswordLength);
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      _usernameController.removeListener(_logUsernameLength);
      _passwordController.removeListener(_logPasswordLength);
    }
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _logUsernameLength() {
    debugPrint(
      '[LoginInput] username length = ${_usernameController.text.length}',
    );
  }

  void _logPasswordLength() {
    debugPrint(
      '[LoginInput] password length = ${_passwordController.text.length}',
    );
  }

  Future<LoginConnectOutcome> _performConnect() {
    return ProviderScope.containerOf(context, listen: false)
        .read(loginControllerProvider)
        .connect(
          usernameFromField: _usernameController.text,
          passwordFromField: _passwordController.text,
        );
  }

  Future<LoginConnectOutcome> _handleConnect() async {
    _credentialsKey.currentState?.clearErrors();
    final result = await _performConnect();
    if (!mounted || result.didNavigate) {
      return result;
    }
    _credentialsKey.currentState?.applyValidationErrors(
      usernameError: result.usernameError,
      passwordError: result.passwordError,
    );
    if (result.unexpectedFailure && result.connectMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.connectMessage!)));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final useIosLayout = LoginCredentialField.useIosStableTextInput;

    final header = _LoginHeader(textTheme: textTheme);
    final formBlock = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LoginCredentialsPanel(
            key: _credentialsKey,
            usernameController: _usernameController,
            passwordController: _passwordController,
            onSubmit: () => _handleConnect(),
            showDiagnostics: _showLoginInputDiagnostics,
          ),
          const SizedBox(height: AppSpacing.xl),
          _LoginActionsPanel(onConnect: _handleConnect),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Router credentials are used to connect to your MiFi.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );

    if (!useIosLayout) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: AppSpacing.xxl),
                  formBlock,
                ],
              ),
            ),
          ),
        ),
      );
    }

    // iOS: keep text fields OUT of the scroll view so keyboard inset updates
    // do not rebuild the editable through Scrollable semantics.
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: header,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Center(child: formBlock),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Center(child: AppLogoPlaceholder()),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'MiFi',
          textAlign: TextAlign.center,
          style: textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Connect to your MiFi',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
      ],
    );
  }
}

/// Connect button + router message only — [setState] here does not rebuild fields.
class _LoginActionsPanel extends StatefulWidget {
  const _LoginActionsPanel({required this.onConnect});

  final Future<LoginConnectOutcome> Function() onConnect;

  @override
  State<_LoginActionsPanel> createState() => _LoginActionsPanelState();
}

class _LoginActionsPanelState extends State<_LoginActionsPanel> {
  bool _isSubmitting = false;
  String? _connectMessage;
  bool _connectMessageIsError = false;

  Future<void> _submitConnect() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _connectMessage = null;
      _connectMessageIsError = false;
    });

    final result = await widget.onConnect();

    if (!mounted || result.didNavigate) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _connectMessage = result.connectMessage;
      _connectMessageIsError = result.connectMessageIsError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPrimaryButton(
          label: 'Connect',
          isLoading: _isSubmitting,
          onPressed: _submitConnect,
        ),
        if (_connectMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _connectMessage!,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: _connectMessageIsError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _LoginCredentialsPanel extends StatefulWidget {
  const _LoginCredentialsPanel({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.onSubmit,
    required this.showDiagnostics,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Future<LoginConnectOutcome> Function() onSubmit;
  final bool showDiagnostics;

  @override
  State<_LoginCredentialsPanel> createState() => _LoginCredentialsPanelState();
}

class _LoginCredentialsPanelState extends State<_LoginCredentialsPanel> {
  final _usernameError = ValueNotifier<String?>(null);
  final _passwordError = ValueNotifier<String?>(null);
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _usernameError.dispose();
    _passwordError.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void clearErrors() {
    _usernameError.value = null;
    _passwordError.value = null;
  }

  void applyValidationErrors({String? usernameError, String? passwordError}) {
    _usernameError.value = usernameError;
    _passwordError.value = passwordError;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LoginUsernameField(
          controller: widget.usernameController,
          focusNode: _usernameFocus,
          passwordFocusNode: _passwordFocus,
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _usernameError,
          builder: (context, error, _) => _FieldErrorLine(message: error),
        ),
        const SizedBox(height: AppSpacing.lg),
        _LoginPasswordField(
          controller: widget.passwordController,
          focusNode: _passwordFocus,
          onSubmit: widget.onSubmit,
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _passwordError,
          builder: (context, error, _) => _FieldErrorLine(message: error),
        ),
        if (widget.showDiagnostics)
          _LoginInputDiagnostics(
            usernameController: widget.usernameController,
            passwordController: widget.passwordController,
          ),
      ],
    );
  }
}

/// Username field in its own [State] so password visibility toggles never rebuild it.
class _LoginUsernameField extends StatefulWidget {
  const _LoginUsernameField({
    required this.controller,
    required this.focusNode,
    required this.passwordFocusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode passwordFocusNode;

  @override
  State<_LoginUsernameField> createState() => _LoginUsernameFieldState();
}

class _LoginUsernameFieldState extends State<_LoginUsernameField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Username',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        LoginCredentialField(
          key: const ValueKey('login_username_input'),
          controller: widget.controller,
          focusNode: widget.focusNode,
          hint: 'Enter username',
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => widget.passwordFocusNode.requestFocus(),
        ),
      ],
    );
  }
}

/// Password field + visibility toggle — [setState] here does not rebuild username.
class _LoginPasswordField extends StatefulWidget {
  const _LoginPasswordField({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<LoginConnectOutcome> Function() onSubmit;

  @override
  State<_LoginPasswordField> createState() => _LoginPasswordFieldState();
}

class _LoginPasswordFieldState extends State<_LoginPasswordField> {
  var _obscurePassword = true;

  Future<void> _submitFromKeyboard() async {
    await widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Password',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        LoginCredentialField(
          key: const ValueKey('login_password_input'),
          controller: widget.controller,
          focusNode: widget.focusNode,
          hint: 'Enter password',
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitFromKeyboard(),
          suffix: _PasswordVisibilitySuffix(
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ],
    );
  }
}

class _PasswordVisibilitySuffix extends StatelessWidget {
  const _PasswordVisibilitySuffix({
    required this.obscure,
    required this.onToggle,
  });

  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscure ? 'Show password' : 'Hide password',
      onPressed: onToggle,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _FieldErrorLine extends StatelessWidget {
  const _FieldErrorLine({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message!,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

/// Debug-only character counts (never shows credential values).
class _LoginInputDiagnostics extends StatelessWidget {
  const _LoginInputDiagnostics({
    required this.usernameController,
    required this.passwordController,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([usernameController, passwordController]),
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(
            'Username characters: ${usernameController.text.length}\n'
            'Password characters: ${passwordController.text.length}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
