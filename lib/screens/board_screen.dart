import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../board_service.dart';
import '../message.dart';
import '../user_record_service.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.user, required this.profile});
  final User user;
  final UserRecord profile;
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _service = BoardService();
  final _text = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late Stream<List<Message>> _messages;
  bool _posting = false;
  String? _postId;
  String? _postText;
  bool _signingOut = false;
  final Set<String> _pending = {};

  @override
  void initState() {
    super.initState();
    _messages = _service.messageBoard();
  }

  void _error(String message) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _post() async {
    if (_posting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final text = _text.text.trim();
    // An unchanged draft keeps its ID after a failed/uncertain write.
    if (_postId == null || _postText != text) {
      _postId = _service.newMessageId();
      _postText = text;
    }
    final messageId = _postId!;
    setState(() {
      _posting = true;
    });
    try {
      Future<void> send() => _service.postMessage(
        messageId: messageId,
        authorUid: widget.user.uid,
        authorName: widget.profile.fullName,
        text: text,
      );
      const duplicateTest = bool.fromEnvironment('TEST_DUPLICATE_POSTS');
      const localEmulators = bool.fromEnvironment('USE_EMULATORS');
      if (duplicateTest && localEmulators) {
        await Future.wait([send(), send()]);
        debugPrint(
          'Spice 4: two calls completed with message ID $messageId. Verify one document in Emulator UI.',
        );
      } else {
        await send();
      }
      _postId = null;
      _postText = null;
      if (mounted) _text.clear();
    } on FirebaseException {
      _error('Could not post. Check your connection and message permissions.');
    } finally {
      if (mounted)
        setState(() {
          _posting = false;
        });
    }
  }

  Future<void> _edit(Message message) async {
    final newText = await showDialog<String>(
      context: context,
      builder: (_) => _EditDialog(text: message.text),
    );
    if (!mounted || newText == null || newText == message.text) return;
    await _mutate(
      message.id,
      () => _service.editMessage(messageId: message.id, newText: newText),
    );
  }

  Future<void> _delete(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _mutate(
      message.id,
      () => _service.deleteMessage(messageId: message.id),
    );
  }

  Future<void> _mutate(String id, Future<void> Function() action) async {
    if (_pending.contains(id)) return;
    setState(() {
      _pending.add(id);
    });
    try {
      await action();
    } on FirebaseException {
      _error(
        'Could not change this message. Check your connection and permissions. Only its author can edit or delete it.',
      );
    } finally {
      if (mounted)
        setState(() {
          _pending.remove(id);
        });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _signingOut = true;
    });
    try {
      await AuthService().signOut();
    } on FirebaseAuthException {
      _error('Could not sign out. Try again.');
    } finally {
      if (mounted)
        setState(() {
          _signingOut = false;
        });
    }
  }

  String _date(DateTime date) => date.toLocal().toString().split('.').first;

  Widget _messageList() => StreamBuilder<List<Message>>(
    stream: _messages,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Could not load messages. Check your connection and permissions.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => setState(() {
                  _messages = _service.messageBoard();
                }),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator());
      final messages = snapshot.data!;
      if (messages.isEmpty)
        return const Center(
          child: Text('No messages yet. Post the first one!'),
        );
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return Card(
            key: ValueKey(message.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(message.text),
                  const SizedBox(height: 8),
                  Text(
                    message.createdAt == null
                        ? 'Sending…'
                        : '${_date(message.createdAt!)}${message.editedAt != null ? ' · Edited' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (message.authorUid == widget.user.uid)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _pending.contains(message.id)
                              ? null
                              : () => _edit(message),
                          child: const Text('Edit'),
                        ),
                        TextButton(
                          onPressed: _pending.contains(message.id)
                              ? null
                              : () => _delete(message),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Message Board'),
        actions: [
          TextButton(
            onPressed: _signingOut ? null : _signOut,
            child: const Text('Sign Out'),
          ),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Messages'),
            Tab(text: 'My Profile'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          children: [
            Column(
              children: [
                Expanded(child: _messageList()),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _text,
                          enabled: !_posting,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Write a message',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a message.'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _posting ? null : _post,
                          child: Text(_posting ? 'Posting…' : 'Post'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  widget.profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(widget.user.email ?? 'Not provided'),
                ),
                ListTile(
                  title: const Text('First name'),
                  subtitle: Text(widget.profile.firstName),
                ),
                ListTile(
                  title: const Text('Last name'),
                  subtitle: Text(widget.profile.lastName),
                ),
                ListTile(
                  title: const Text('Role'),
                  subtitle: Text(widget.profile.role),
                ),
                ListTile(
                  title: const Text('Registered'),
                  subtitle: Text(
                    widget.profile.registeredAt == null
                        ? 'Not available'
                        : _date(widget.profile.registeredAt!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.text});
  final String text;
  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _text;
  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit message'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _text,
        autofocus: true,
        minLines: 1,
        maxLines: 5,
        decoration: const InputDecoration(labelText: 'Message'),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Enter a message.' : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          if (_formKey.currentState!.validate())
            Navigator.pop(context, _text.text.trim());
        },
        child: const Text('Save'),
      ),
    ],
  );
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }
}
