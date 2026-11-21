import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _busy = false;
  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; });
    try {
      await _auth.signIn(
        email: _email.text,
        password: _password.text,
      );
    } on FirebaseAuthException catch (error) {
      final message = error.code == 'network-request-failed'
          ? 'Check your connection and try again.'
          : 'Sign-in failed. Check your details and sign-in setup.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
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
                    Text('Sign in', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
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
                      enabled: !_busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password.'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In'),
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
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
