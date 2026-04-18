import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/inactivity_provider.dart';
import '../services/auth_service.dart';
import '../services/pin_service.dart';
import '../services/contact_service.dart';
import '../models/contact.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ContactService _contactService = ContactService();

  String _username = 'Loading...';
  String _uniqueUserId = 'Loading...';
  bool _isLoading = true;

  // Pastel colors for icons
  static const _pastelBlue = Color(0xFFBAE1FF);
  static const _pastelPink = Color(0xFFFFB3BA);
  static const _pastelGreen = Color(0xFFBAFFC9);
  static const _pastelPurple = Color(0xFFE0BBE4);
  static const _pastelOrange = Color(0xFFFFDFBA);
  static const _pastelYellow = Color(0xFFFFF4BA);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final data = userDoc.data()!;
      
      if (mounted) {
        setState(() {
          _username = data['username'] ?? 'Unknown';
          _uniqueUserId = data['uniqueUserId'] ?? 'Unknown';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyUserIdToClipboard() {
    Clipboard.setData(ClipboardData(text: _uniqueUserId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('User ID copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 8),
                // Profile Header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _pastelBlue.withOpacity(0.3),
                        _pastelPurple.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: _pastelPurple,
                        child: Text(
                          _username.isNotEmpty ? _username[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black87
                                : const Color(0xFF2C2C2C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _username,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _uniqueUserId,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              letterSpacing: 1,
                            ),
                      ),
                    ],
                  ),
                ),
                _SettingsSection(
                  title: 'Account',
                  children: [
                    _SettingsTile(
                      icon: Icons.qr_code_rounded,
                      iconColor: const Color(0xFF9370DB),
                      iconBackground: _pastelPurple,
                      title: 'My QR Code',
                      subtitle: 'Share your QR code with others',
                      onTap: () => context.push('/my-qr'),
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _pastelGreen.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: Color(0xFF70B77E),
                        ),
                      ),
                      title: const Text('User ID'),
                      subtitle: Text(_uniqueUserId),
                      trailing: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _pastelBlue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onTap: _copyUserIdToClipboard,
                    ),
                    _SettingsTile(
                      icon: Icons.person_add_outlined,
                      iconColor: const Color(0xFF89CFF0),
                      iconBackground: _pastelBlue,
                      title: 'Add Contact',
                      subtitle: 'Add new contacts to chat',
                      onTap: () => context.push('/add-contact'),
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'Security',
                  children: [
                    _SettingsTile(
                      icon: Icons.pin_outlined,
                      iconColor: const Color(0xFFFF9999),
                      iconBackground: _pastelPink,
                      title: 'Change PIN',
                      subtitle: 'Update your 6-digit PIN',
                      onTap: () {
                        _showComingSoonSnackbar();
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.key_rounded,
                      iconColor: const Color(0xFFFFB366),
                      iconBackground: _pastelOrange,
                      title: 'Regenerate Keys',
                      subtitle: 'Generate new encryption keys',
                      onTap: () {
                        _showRegenerateKeysDialog(context);
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFFFFE066),
                      iconBackground: _pastelYellow,
                      title: 'Auto-Lock',
                      subtitle: _getAutoLockSubtitle(),
                      onTap: () {
                        _showAutoLockDialog(context);
                      },
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'Appearance',
                  children: [
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _pastelPurple.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: const Color(0xFF9370DB),
                            ),
                          ),
                          title: const Text('Dark Mode'),
                          subtitle: Text(
                            themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
                          ),
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (_) => themeProvider.toggleTheme(),
                            activeColor: const Color(0xFF9AECAA),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'Privacy',
                  children: [
                    StreamBuilder<List<Contact>>(
                      stream: _contactService.getContacts(),
                      builder: (context, snapshot) {
                        final blockedCount = snapshot.data
                                ?.where((c) => c.blocked)
                                .length ??
                            0;
                        return _SettingsTile(
                          icon: Icons.block_rounded,
                          iconColor: const Color(0xFFFF9999),
                          iconBackground: _pastelPink,
                          title: 'Blocked Contacts',
                          subtitle: blockedCount > 0
                              ? '$blockedCount blocked'
                              : 'No blocked contacts',
                          onTap: () {
                            _showBlockedContactsDialog(context);
                          },
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      iconColor: const Color(0xFFFF8080),
                      iconBackground: const Color(0xFFFFCCCC),
                      title: 'Clear All Chats',
                      subtitle: 'Delete all conversation history',
                      onTap: () {
                        _showClearChatsDialog(context);
                      },
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'About',
                  children: [
                    _SettingsTile(
                      icon: Icons.info_rounded,
                      iconColor: const Color(0xFF89CFF0),
                      iconBackground: _pastelBlue,
                      title: 'About QuantumChat',
                      subtitle: 'Version 1.0.0',
                      onTap: () {
                        _showAboutDialog(context);
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.description_rounded,
                      iconColor: const Color(0xFF70B77E),
                      iconBackground: _pastelGreen,
                      title: 'Terms of Service',
                      subtitle: 'Read our terms and conditions',
                      onTap: () {
                        _showComingSoonSnackbar();
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      iconColor: const Color(0xFF9370DB),
                      iconBackground: _pastelPurple,
                      title: 'Privacy Policy',
                      subtitle: 'Learn how we protect your data',
                      onTap: () {
                        _showComingSoonSnackbar();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.red.shade900.withOpacity(0.2)
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.red.shade700.withOpacity(0.5)
                            : Colors.red.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showLogoutDialog(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color:
                                    Theme.of(context).brightness == Brightness.dark
                                        ? Colors.red.shade300
                                        : Colors.red.shade700,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.red.shade300
                                      : Colors.red.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getAutoLockSubtitle() {
    final inactivityProvider = Provider.of<InactivityProvider>(context, listen: false);
    final timeout = inactivityProvider.timeoutMinutes;
    if (timeout == 0) {
      return 'Disabled';
    } else if (timeout == 1) {
      return 'Lock after 1 minute';
    } else {
      return 'Lock after $timeout minutes';
    }
  }

  void _showAutoLockDialog(BuildContext context) {
    final inactivityProvider = Provider.of<InactivityProvider>(context, listen: false);
    final currentTimeout = inactivityProvider.timeoutMinutes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Lock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App will automatically lock after inactivity. You\'ll need to re-enter your PIN to unlock.',
            ),
            const SizedBox(height: 16),
            _AutoLockOption(
              label: 'Never',
              minutes: 0,
              currentTimeout: currentTimeout,
              onTap: () {
                inactivityProvider.setTimeoutMinutes(0);
                Navigator.pop(context);
                setState(() {});
              },
            ),
            _AutoLockOption(
              label: '1 minute',
              minutes: 1,
              currentTimeout: currentTimeout,
              onTap: () {
                inactivityProvider.setTimeoutMinutes(1);
                Navigator.pop(context);
                setState(() {});
              },
            ),
            _AutoLockOption(
              label: '5 minutes',
              minutes: 5,
              currentTimeout: currentTimeout,
              onTap: () {
                inactivityProvider.setTimeoutMinutes(5);
                Navigator.pop(context);
                setState(() {});
              },
            ),
            _AutoLockOption(
              label: '10 minutes',
              minutes: 10,
              currentTimeout: currentTimeout,
              onTap: () {
                inactivityProvider.setTimeoutMinutes(10);
                Navigator.pop(context);
                setState(() {});
              },
            ),
            _AutoLockOption(
              label: '15 minutes',
              minutes: 15,
              currentTimeout: currentTimeout,
              onTap: () {
                inactivityProvider.setTimeoutMinutes(15);
                Navigator.pop(context);
                setState(() {});
              },
            ),
            _AutoLockOption(
              label: '30 minutes',
              minutes: 30,
              currentTimeout: currentTimeout,
              onTap: () {
                inactivityProvider.setTimeoutMinutes(30);
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBlockedContactsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blocked Contacts'),
        content: StreamBuilder<List<Contact>>(
          stream: _contactService.getContacts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final blockedContacts =
                snapshot.data?.where((c) => c.blocked).toList() ?? [];

            if (blockedContacts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No blocked contacts'),
              );
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: blockedContacts.length,
                itemBuilder: (context, index) {
                  final contact = blockedContacts[index];
                  return ListTile(
                    title: Text(contact.contactUsername),
                    subtitle: Text(contact.contactUniqueId),
                    trailing: TextButton(
                      onPressed: () async {
                        final result = await _contactService
                            .unblockContact(contact.contactUid);
                        if (context.mounted && result['success']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '${contact.contactUsername} unblocked')),
                          );
                        }
                      },
                      child: const Text('Unblock'),
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRegenerateKeysDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Keys'),
        content: const Text(
          'This will generate new encryption keys. Your existing conversations will remain accessible, but new messages will use the new keys.\n\nNote: This feature is not yet fully implemented.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement key regeneration
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Key regeneration coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  void _showClearChatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Chats'),
        content: const Text(
          'This will permanently delete all your conversation history. This action cannot be undone.\n\nNote: Chat functionality is not yet fully implemented.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement clear chats
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat deletion coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About QuantumChat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QuantumChat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text('Version 1.0.0'),
            const SizedBox(height: 16),
            const Text(
              'A secure messaging app with post-quantum encryption using Kyber-1024 and AES-256-GCM.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• End-to-end encryption'),
            const Text('• QR code contact exchange'),
            const Text('• No metadata logging'),
            const Text('• PIN protection'),
            const Text('• Dark/Light themes'),
            const SizedBox(height: 16),
            Text(
              '© 2025 QuantumChat',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final authService = AuthService();
    final pinService = PinService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Clear PIN verification
              await pinService.clearPinVerification();

              // Sign out
              await authService.signOut();

              if (!context.mounted) return;

              // Close dialog and navigate to login
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBackground.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _AutoLockOption extends StatelessWidget {
  final String label;
  final int minutes;
  final int currentTimeout;
  final VoidCallback onTap;

  const _AutoLockOption({
    required this.label,
    required this.minutes,
    required this.currentTimeout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = minutes == currentTimeout;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
