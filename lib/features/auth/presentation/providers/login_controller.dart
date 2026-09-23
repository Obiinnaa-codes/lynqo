import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginState {
  const LoginState({
    this.username = '',
    this.password = '',
    this.obscurePassword = true,
    this.usernameError,
    this.passwordError,
    this.isSubmitting = false,
  });

  final String username;
  final String password;
  final bool obscurePassword;
  final String? usernameError;
  final String? passwordError;
  final bool isSubmitting;

  LoginState copyWith({
    String? username,
    String? password,
    bool? obscurePassword,
    String? usernameError,
    String? passwordError,
    bool? isSubmitting,
    bool clearUsernameError = false,
    bool clearPasswordError = false,
  }) {
    return LoginState(
      username: username ?? this.username,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      usernameError: clearUsernameError
          ? null
          : (usernameError ?? this.usernameError),
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  void setUsername(String value) {
    state = state.copyWith(username: value, clearUsernameError: true);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value, clearPasswordError: true);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> connect() async {
    if (state.isSubmitting) {
      return;
    }

    state = state.copyWith(isSubmitting: true);

    final username = state.username.trim();
    final password = state.password;

    String? usernameError;
    String? passwordError;

    if (username.isEmpty) {
      usernameError = 'Username is required';
    }
    if (password.isEmpty) {
      passwordError = 'Password is required';
    }

    if (usernameError != null || passwordError != null) {
      state = state.copyWith(
        isSubmitting: false,
        usernameError: usernameError,
        passwordError: passwordError,
      );
      return;
    }

    // TODO: router authentication (Step 2)

    state = state.copyWith(
      isSubmitting: false,
      clearUsernameError: true,
      clearPasswordError: true,
    );
  }
}

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);
