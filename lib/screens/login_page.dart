import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:xpensia/screens/home/home_screen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // If users type phone without +CC, prepend this:
  static const String defaultCc = '+91';

  // --- Utility Methods ---

  bool _isEmail(String v) => v.contains('@');

  String _normalizePhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    return '$defaultCc$cleaned';
  }

  /// Maps technical Amplify exceptions to user-friendly messages.
  String _handleAuthError(AuthException e) {
    // Using debugPrint for logging, which is standard in Flutter.
    debugPrint('Auth Error: ${e.message}');
    // Comparing runtimeType is more robust than comparing strings.
    switch (e.runtimeType.toString()) {
      case 'UserNotFoundException':
        return 'No account found with that username. Please sign up.';
      case 'NotAuthorizedException':
        return 'Incorrect password or username. Please try again.';
      case 'UserNotConfirmedException':
        return 'Your account is not confirmed. Please use the confirmation screen.';
      case 'CodeMismatchException':
        return 'Invalid confirmation code. Please try again.';
      case 'LimitExceededException':
        return 'Too many attempts. Please try again later.';
      case 'InvalidParameterException':
        return 'Invalid input. Please check your email or phone number.';
      case 'UsernameExistsException':
        return 'An account with this username already exists.';
      default:
        // Return the default message for unhandled exceptions.
        return e.message;
    }
  }

  // --- Authentication Logic ---

  Future<String?> _authUser(LoginData data) async {
    try {
      final raw = data.name.trim();
      final username = _isEmail(raw) ? raw : _normalizePhone(raw);

      final result = await Amplify.Auth.signIn(
        username: username,
        password: data.password,
      );

      if (result.isSignedIn) {
        return null; // Success, onLogin will handle navigation.
      }

      // Handle next steps if sign-in is not complete (e.g., MFA).
      final step = result.nextStep.signInStep;
      switch (step) {
        case AuthSignInStep.confirmSignUp:
          return 'Your account isn’t confirmed. Please use the confirmation screen.';
        case AuthSignInStep.resetPassword:
          return 'Password reset required. Use the "Forgot Password" flow.';
        default:
          return 'Login not complete. Next step: ${step.name}';
      }
    } on UserNotConfirmedException {
      // This is the key to triggering the confirmation screen.
      return 'Your account is not confirmed. Please check your email/SMS for a code.';
    } on AuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    try {
      final raw = (data.name ?? '').trim();

      final isEmail = _isEmail(raw);

      final username = isEmail ? raw : _normalizePhone(raw);

      final attrs = <AuthUserAttributeKey, String>{};

      if (isEmail) {
        attrs[AuthUserAttributeKey.email] = raw;
      } else {
        attrs[AuthUserAttributeKey.phoneNumber] = username;
      }

      final res = await Amplify.Auth.signUp(
        username: username,

        password: data.password!,

        options: SignUpOptions(userAttributes: attrs),
      );

      if (res.isSignUpComplete) {
        // This typically won't happen if confirmation is required.

        return null;
      }

      // Return null on successful sign-up initiation.
      // Because `loginAfterSignUp` is true, flutter_login will automatically
      // call `onLogin`. The `_authUser` function will then catch the
      // UserNotConfirmedException and return a message, which will reliably
      // trigger the confirmation code screen. This creates a seamless flow.
      return null;
    } on AuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  Future<String?> _confirmSignUp(String code, LoginData data) async {
    try {
      final raw = data.name.trim();
      final username = _isEmail(raw) ? raw : _normalizePhone(raw);
      final res = await Amplify.Auth.confirmSignUp(
        username: username,
        confirmationCode: code,
      );
      return res.isSignUpComplete ? null : 'Confirmation failed. Try again.';
    } on AuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  // CORRECTED: The callback provides the username string directly.
  Future<String?> _resendCode(String username) async {
    try {
      final raw = username.trim();
      final userToResend = _isEmail(raw) ? raw : _normalizePhone(raw);
      await Amplify.Auth.resendSignUpCode(username: userToResend);
      // This message is shown to the user in the UI.
      return 'A new confirmation code has been sent.';
    } on AuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  Future<String?> _recoverPassword(String name) async {
    try {
      final raw = name.trim();
      final username = _isEmail(raw) ? raw : _normalizePhone(raw);
      await Amplify.Auth.resetPassword(username: username);
      // Return null on success to allow flutter_login to transition
      // to the confirm password screen.
      return null;
    } on AuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  Future<String?> _confirmRecover(String code, LoginData data) async {
    try {
      final raw = data.name.trim();
      final username = _isEmail(raw) ? raw : _normalizePhone(raw);
      await Amplify.Auth.confirmResetPassword(
        username: username,
        newPassword: data.password,
        confirmationCode: code,
      );
      return null; // Success
    } on AuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  void _onLoginSuccess() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'XPENSIA',
      userValidator: (value) {
        if (value == null || value.isEmpty) {
          return 'Field cannot be empty.';
        }
        return null;
      },
      passwordValidator: (value) {
        if (value == null || value.length < 8) {
          return 'Password must be at least 8 characters.';
        }
        return null;
      },
      onLogin: (data) async {
        final result = await _authUser(data);
        if (result == null && mounted) {
          _onLoginSuccess();
        }
        return result;
      },
      onSignup: _signupUser,
      onConfirmSignup: _confirmSignUp,
      // CORRECTED: The onResendCode expects a SignupCallback (SignupData).
      onResendCode: (SignupData data) => _resendCode(data.name ?? ''),
      onRecoverPassword: _recoverPassword,
      onConfirmRecover: _confirmRecover,
      validateUserImmediately: true,
      loginAfterSignUp: true,
      onSubmitAnimationCompleted: () async {
        try {
          final session = await Amplify.Auth.fetchAuthSession();
          if (session.isSignedIn) {
            _onLoginSuccess();
          }
        } on AuthException {
          // Not signed in, do nothing.
        }
      },

      theme: LoginTheme(
        primaryColor: Theme.of(context).colorScheme.primary,
        accentColor: Theme.of(context).colorScheme.secondary,
        buttonTheme: LoginButtonTheme(
          backgroundColor: Theme.of(context).colorScheme.primary,
          splashColor: Theme.of(context).colorScheme.secondary,
        ),
        cardTheme: CardTheme(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
