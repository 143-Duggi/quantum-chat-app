import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/contact_service.dart';
import '../models/message.dart';
import '../models/contact.dart';

class ChatScreen extends StatefulWidget {
  final String chatId; // This is the contact's UID

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final ContactService _contactService = ContactService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _sessionId;
  String? _sharedSecret;
  Contact? _contact;
  bool _isLoading = true;
  bool _isSending = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Get contact information
      final contact = await _contactService.getContact(widget.chatId);
      
      if (contact == null) {
        setState(() {
          _errorMessage = 'Contact not found';
          _isLoading = false;
        });
        return;
      }

      setState(() => _contact = contact);

      // Get or create chat session
      final sessionResult = await _chatService.getOrCreateSession(
        contactUid: widget.chatId,
        contactPubKey: contact.contactPubKey,
      );

      if (!sessionResult['success']) {
        setState(() {
          _errorMessage = sessionResult['error'] ?? 'Failed to initialize chat';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _sessionId = sessionResult['sessionId'];
        _sharedSecret = sessionResult['sharedSecret'];
        _isLoading = false;
      });

      // Scroll to bottom after messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSendMessage() async {
    if (_messageController.text.trim().isEmpty || _sessionId == null) return;
    if (_isSending) return;

    final plaintext = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    final result = await _chatService.sendMessage(
      sessionId: _sessionId!,
      plaintext: plaintext,
    );

    setState(() => _isSending = false);

    if (!result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Restore the message to the text field
      _messageController.text = plaintext;
    } else {
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _showDeleteDialog(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Delete this message for both parties?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && _sessionId != null) {
      final result = await _chatService.deleteMessage(
        sessionId: _sessionId!,
        messageId: message.messageId,
      );

      if (mounted && !result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to delete message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyMessageText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Mock messages for demo - these should be removed in production
  final List<Map<String, dynamic>> _mockMessages = [
    {
      'id': '1',
      'text': 'Hey! How are you doing? 👋',
      'isMine': false,
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      'status': 'read',
    },
    {
      'id': '2',
      'text': 'Hi! I\'m doing great, thanks for asking! How about you?',
      'isMine': true,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 58)),
      'status': 'read',
    },
    {
      'id': '3',
      'text': 'I\'m good too! Have you tried this new quantum chat app?',
      'isMine': false,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 55)),
      'status': 'read',
    },
    {
      'id': '4',
      'text': 'Yes! That\'s what we\'re using right now 😄',
      'isMine': true,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 50)),
      'status': 'read',
    },
    {
      'id': '5',
      'text': 'Oh wow, I didn\'t realize! This is amazing. So our messages are really secure?',
      'isMine': false,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
      'status': 'read',
    },
    {
      'id': '6',
      'text': 'Absolutely! It uses post-quantum cryptography, so even quantum computers can\'t break the encryption 🔒',
      'isMine': true,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
      'status': 'read',
    },
    {
      'id': '7',
      'text': 'That\'s incredible! Privacy is so important these days.',
      'isMine': false,
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      'status': 'read',
    },
    {
      'id': '8',
      'text': 'Exactly! And the UI is pretty clean too, don\'t you think?',
      'isMine': true,
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 25)),
      'status': 'read',
    },
    {
      'id': '9',
      'text': 'Yeah, I love the modern design! Very sleek and professional. 💯',
      'isMine': false,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 45)),
      'status': 'read',
    },
    {
      'id': '10',
      'text': 'The dark mode looks really good too. Perfect for late-night conversations!',
      'isMine': true,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 40)),
      'status': 'read',
    },
    {
      'id': '11',
      'text': 'Agreed! And I love that we can see when messages are delivered and read.',
      'isMine': false,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 20)),
      'status': 'read',
    },
    {
      'id': '12',
      'text': 'Yeah, the double check marks are a nice touch! ✓✓',
      'isMine': true,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
      'status': 'delivered',
    },
    {
      'id': '13',
      'text': 'Want to grab coffee later this week?',
      'isMine': false,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'status': 'read',
    },
    {
      'id': '14',
      'text': 'Sure! How about Thursday afternoon?',
      'isMine': true,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
      'status': 'delivered',
    },
    {
      'id': '15',
      'text': 'Perfect! I\'ll send you the location. See you then! 👍',
      'isMine': false,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 1)),
      'status': 'read',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFB3BA),
              child: Text(
                _contact?.contactUsername[0].toUpperCase() ?? '?',
                style: const TextStyle(
                  color: Color(0xFF2C2C2C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _contact?.contactUsername ?? 'Unknown',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Encrypted',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options menu
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Chat Info'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Show chat info
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Delete Chat'),
                        onTap: () async {
                          Navigator.pop(context);
                          if (_sessionId != null) {
                            await _chatService.deleteSession(_sessionId!);
                            if (mounted) context.pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Encryption notice
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFFE0BBE4).withOpacity(0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock,
                  size: 14,
                  color: Color(0xFF9370DB),
                ),
                const SizedBox(width: 8),
                Text(
                  'Messages are end-to-end encrypted',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9370DB),
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _sessionId == null
                ? const Center(child: Text('Unable to load chat'))
                : StreamBuilder<List<Message>>(
                    stream: _chatService.getMessages(_sessionId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error loading messages: ${snapshot.error}'),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFDFBA).withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  size: 48,
                                  color: Color(0xFFFFB366),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Start a secure conversation',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Protected by quantum encryption',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }

                      // Decrypt messages asynchronously
                      return FutureBuilder<List<Message>>(
                        future: _decryptMessages(messages),
                        builder: (context, decryptedSnapshot) {
                          if (decryptedSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final decryptedMessages = decryptedSnapshot.data ?? messages;

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: decryptedMessages.length,
                            itemBuilder: (context, index) {
                              final message = decryptedMessages[index];
                              final isMine = message.sender == currentUserId;

                              return _MessageBubble(
                                message: message,
                                isMine: isMine,
                                onLongPress: () => _showMessageOptions(message, isMine),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
                      enabled: !_isSending,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFBAFFC9),
                          Color(0xFF9AECAA),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C2C2C)),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Color(0xFF2C2C2C),
                              size: 20,
                            ),
                      onPressed: _isSending ? null : _handleSendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Message>> _decryptMessages(List<Message> messages) async {
    final decryptedMessages = <Message>[];

    for (final message in messages) {
      if (_sessionId == null) {
        decryptedMessages.add(message);
        continue;
      }

      final decrypted = await _chatService.decryptMessage(
        ciphertext: message.ciphertext,
        iv: message.iv,
        sessionId: _sessionId!,
      );

      decryptedMessages.add(
        message.copyWith(
          decryptedContent: decrypted ?? '[Failed to decrypt]',
        ),
      );
    }

    return decryptedMessages;
  }

  void _showMessageOptions(Message message, bool isMine) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                _copyMessageText(message.decryptedContent ?? message.ciphertext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete for everyone'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(message);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onLongPress,
  });

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMine
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.decryptedContent ?? message.ciphertext,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isMine
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isMine
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.7)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSecondary
                                      .withOpacity(0.7),
                              fontSize: 10,
                            ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == MessageStatus.sent
                              ? Icons.done_all
                              : Icons.access_time,
                          size: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
