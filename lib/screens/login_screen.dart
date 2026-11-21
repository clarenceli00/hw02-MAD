import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../user_record_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onRegistrationChanged});
  final ValueChanged<bool>? onRegistrationChanged;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  final _profiles = UserRecordService();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _role = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _register = false;
  User? _pendingUser;
  bool _busy = false;
  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; });
    try {
      if (_register) {
        // Keep this form visible until both account and profile are saved.
        widget.onRegistrationChanged?.call(true);
        if (_pendingUser == null) {
          final credential = await _auth.register(
            email: _email.text,
            password: _password.text,
          );
          _pendingUser = credential.user;
          if (_pendingUser == null) {
            throw StateError('Account creation returned no user.');
          }
        }
        await _profiles.saveUserRecord(
          _pendingUser!,
          firstName: _firstName.text,
          lastName: _lastName.text,
          role: _role.text,
        );
        if (mounted) widget.onRegistrationChanged?.call(false);
      } else {
        await _auth.signIn(email: _email.text, password: _password.text);
      }
    } on FirebaseAuthException catch (error) {
      if (const bool.fromEnvironment('USE_EMULATORS')) {
        debugPrint('Local authentication failed: ${error.code}');
      }
      if (mounted) widget.onRegistrationChanged?.call(false);
      final message = switch (error.code) {
        'network-request-failed' => 'Check your connection and try again.',
        'email-already-in-use' => 'That email already has an account. Try signing in.',
        'weak-password' => 'Choose a stronger password.',
        'invalid-email' => 'Enter a valid email address.',
        'operation-not-allowed' => 'Email/password sign-in is not enabled in Firebase.',
        _ => 'Sign-in or registration failed. Check your details and try again.',
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
            'Account created, but profile could not be saved. Check your connection and Firestore setup, then retry saving your profile.',
          )),
        );
      }
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Board')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_register ? 'Create account' : 'Sign in', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 24),
                    if (_register) ...[
                      _profileField(_firstName, 'First name'),
                      const SizedBox(height: 16),
                      _profileField(_lastName, 'Last name'),
                      const SizedBox(height: 16),
                      _profileField(_role, 'Role'),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _email,
                      enabled: !_busy && _pendingUser == null,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Enter your email.';
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy && _pendingUser == null,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter your password.';
                        if (_register && value.length < 6) return 'Use at least 6 characters.';
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_register) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPassword,
                        enabled: !_busy && _pendingUser == null,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value != _password.text
                            ? 'Passwords must match.' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_pendingUser != null ? 'Retry saving profile' : _register ? 'Create Account' : 'Sign In'),
                    ),
                    TextButton(
                      onPressed: _busy || _pendingUser != null ? null : () {
                        _formKey.currentState?.reset();
                        setState(() { _register = !_register; });
                      },
                      child: Text(_register ? 'Already have an account? Sign in' : 'Create an account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _profileField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      enabled: !_busy,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Enter your ${label.toLowerCase()}.' : null,
    );
  }
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _role.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }
}
