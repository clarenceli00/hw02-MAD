import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'user_record_service.dart';
import 'screens/board_screen.dart';

class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key, required this.user});
  final User user;
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  final _service = UserRecordService();
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _role = TextEditingController();
  late Future<UserRecord?> _profile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<UserRecord?> _load() async {
    final record = await _service.getUserRecord(widget.user.uid);
    if (mounted && record != null) {
      _first.text = record.firstName;
      _last.text = record.lastName;
      _role.text = record.role;
    }
    return record;
  }

  void _retry() => setState(() {
    _profile = _load();
  });

  void _error(String message) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
    });
    try {
      await _service.saveUserRecord(
        widget.user,
        firstName: _first.text,
        lastName: _last.text,
        role: _role.text,
      );
      if (mounted) _retry();
    } on FirebaseException {
      _error(
        'Could not save your profile. Check your connection and try again.',
      );
    } finally {
      if (mounted)
        setState(() {
          _saving = false;
        });
    }
  }

  Future<void> _signOut() async {
    try {
      await AuthService().signOut();
    } on FirebaseAuthException {
      _error('Could not sign out. Try again.');
    }
  }

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'This field is required.'
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<UserRecord?>(
    future: _profile,
    builder: (context, snapshot) {
      final profile = snapshot.data;
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError &&
          profile != null &&
          profile.isComplete &&
          profile.uid == widget.user.uid) {
        return BoardScreen(user: widget.user, profile: profile);
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _signOut,
              child: const Text('Sign Out'),
            ),
          ],
        ),
        body: snapshot.connectionState != ConnectionState.done
            ? const Center(child: CircularProgressIndicator())
            : snapshot.hasError
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load your profile.'),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : Center(
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
                          Text(
                            'Complete your profile',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Save your profile before opening the message board.',
                          ),
                          const SizedBox(height: 24),
                          _field(_first, 'First name'),
                          _field(_last, 'Last name'),
                          _field(_role, 'Role'),
                          ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: Text(_saving ? 'Saving…' : 'Save Profile'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      );
    },
  );

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _role.dispose();
    super.dispose();
  }
}
