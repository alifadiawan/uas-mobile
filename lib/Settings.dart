import 'package:flutter/material.dart';
import 'package:mobile_uas/widgets/CustomBottomNavBar.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Your existing ThemeProvider remains the same.
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  // Handles the sign-out process
  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Shows a themed confirmation dialog before logging out
  Future<void> _showLogoutConfirmationDialog() async {
    final theme = Theme.of(context);
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (isConfirmed == true) {
      _handleLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (user != null) _buildUserProfileHeader(user, theme),
          _buildSettingsGroup(
            context,
            title: 'Appearance',
            children: [_buildDarkModeTile(themeProvider, theme)],
          ),
          _buildSettingsGroup(
            context,
            title: 'Account',
            children: [_buildLogoutTile(theme)],
          ),
        ],
      ),
      // This page doesn't have a FAB, so the setup is simpler.
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 3),
    );
  }

  /// Builds the header section displaying user's avatar and name.
  Widget _buildUserProfileHeader(User user, ThemeData theme) {
    // Try to get the user's name from user.userMetadata, fallback to email if not available
    String displayName = user.userMetadata?['name'] ??
        user.userMetadata?['full_name'] ??
        user.userMetadata?['username'] ??
        user.email ??
        'No name';

    // Try to get the user's profile image from Google or other providers
    String? photoUrl = user.userMetadata?['avatar_url'] ??
        user.userMetadata?['picture'];

    String getInitials(String name) {
      if (name.isEmpty) return '??';
      List<String> parts = name.trim().split(' ');
      if (parts.length == 1) {
        return parts[0].substring(0, 2).toUpperCase();
      }
      return (parts[0][0] + parts.last[0]).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(
                    getInitials(displayName),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// A reusable widget to group settings using our established modern theme.
  Widget _buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        // Replaced Card with our consistent border-style Container
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            // Add dividers between items manually
            children: List.generate(
              children.length * 2 - 1,
              (index) {
                if (index.isEven) {
                  return children[index ~/ 2];
                } else {
                  return Divider(
                    height: 1,
                    indent: 56, // Indent to align with ListTile content
                    color: Colors.grey.shade200,
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Builds the ListTile for toggling dark mode.
  Widget _buildDarkModeTile(ThemeProvider themeProvider, ThemeData theme) {
    return ListTile(
      onTap: () => themeProvider.toggleTheme(),
      leading: Icon(
        themeProvider.isDarkMode
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
        color: theme.textTheme.bodyMedium?.color,
      ),
      title: const Text('Dark Mode'),
      trailing: Switch(
        value: themeProvider.isDarkMode,
        onChanged: (value) => themeProvider.toggleTheme(),
        activeColor: theme.colorScheme.primary,
        // Make the track color more subtle to fit the theme
        activeTrackColor: theme.colorScheme.primary.withOpacity(0.5),
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade200,
      ),
    );
  }

  /// Builds the ListTile for the logout action.
  Widget _buildLogoutTile(ThemeData theme) {
    return ListTile(
      leading: Icon(Icons.logout, color: theme.colorScheme.error),
      title: Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
      onTap: _showLogoutConfirmationDialog,
    );
  }
}
