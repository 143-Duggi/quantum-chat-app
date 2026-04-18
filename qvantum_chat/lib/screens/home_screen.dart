import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/contact_service.dart';
import '../models/contact.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ContactService _contactService = ContactService();
  
  // Pastel color palette for avatars
  final List<Color> _pastelColors = [
    const Color(0xFFFFB3BA), // Pastel pink
    const Color(0xFFBAE1FF), // Pastel blue
    const Color(0xFFFFDFBA), // Pastel orange
    const Color(0xFFBAFFC9), // Pastel green
    const Color(0xFFE0BBE4), // Pastel purple
    const Color(0xFFFFF4BA), // Pastel yellow
    const Color(0xFFFFCCE5), // Pastel rose
  ];

  Color _getAvatarColor(String name) {
    final hash = name.hashCode.abs();
    return _pastelColors[hash % _pastelColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuantumChat'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: StreamBuilder<List<Contact>>(
        stream: _contactService.getContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading contacts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBAE1FF).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Color(0xFF89CFF0),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No contacts yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by adding a contact via QR code\nor sharing your user ID',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/add-contact'),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Add Contact'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: _getAvatarColor(contact.contactUsername),
                  child: Text(
                    contact.contactUsername[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black87
                          : const Color(0xFF2C2C2C),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  contact.contactUsername,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  contact.blocked 
                      ? 'Blocked' 
                      : 'Tap to start chatting',
                  style: TextStyle(
                    color: contact.blocked 
                        ? Colors.red 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                trailing: contact.blocked
                    ? const Icon(Icons.block, color: Colors.red)
                    : const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: contact.blocked 
                    ? null 
                    : () => context.push('/chat/${contact.contactUid}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-contact'),
        backgroundColor: const Color(0xFFBAFFC9),
        foregroundColor: const Color(0xFF2C2C2C),
        child: const Icon(Icons.add),
      ),
    );
  }
}
