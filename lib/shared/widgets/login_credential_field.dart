import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Login username/password input. Android uses a normal [TextField]. iOS uses the
/// same [TextField] but cached so [UITextInput] is not recreated when the tree
/// rebuilds (keyboard insets, scroll, etc.).
class LoginCredentialField extends StatefulWidget {
  const LoginCredentialField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  static const fieldStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  /// iOS needs a stable editable subtree; Android does not.
  static bool get useIosStableTextInput =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @Deprecated('Use useIosStableTextInput')
  static bool get useCupertinoOnThisPlatform => useIosStableTextInput;

  @override
  State<LoginCredentialField> createState() => _LoginCredentialFieldState();
}

class _LoginCredentialFieldState extends State<LoginCredentialField> {
  Widget? _iosCachedRoot;
  var _iosCacheReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LoginCredentialField.useIosStableTextInput && !_iosCacheReady) {
      _rebuildIosCache();
      _iosCacheReady = true;
    }
  }

  @override
  void didUpdateWidget(covariant LoginCredentialField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!LoginCredentialField.useIosStableTextInput || !_iosCacheReady) {
      return;
    }
    if (oldWidget.obscureText != widget.obscureText ||
        oldWidget.hint != widget.hint) {
      _rebuildIosCache();
    }
  }

  Widget _buildMaterialField() {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      style: LoginCredentialField.fieldStyle,
      cursorColor: AppColors.textPrimary,
      obscureText: widget.obscureText,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      keyboardType: TextInputType.text,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hint,
        suffixIcon: widget.suffix,
      ),
    );
  }

  void _rebuildIosCache() {
    _iosCachedRoot = MediaQuery.removeViewInsets(
      context: context,
      removeLeft: true,
      removeTop: true,
      removeRight: true,
      removeBottom: true,
      child: _buildMaterialField(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (LoginCredentialField.useIosStableTextInput) {
      if (_iosCachedRoot == null) {
        return const SizedBox(height: 52);
      }
      return _iosCachedRoot!;
    }
    return _buildMaterialField();
  }
}
