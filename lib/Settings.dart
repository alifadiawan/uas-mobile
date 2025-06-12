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
        // Navigate to the login screen and remove all previous routes
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
                  style: TextStyle(color: theme.colorScheme.error),
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
        title: const Text('Settings'),
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
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 3),
    );
  }

  /// Builds the header section displaying user's avatar and email.
  Widget _buildUserProfileHeader(User user, ThemeData theme) {
    // Helper to generate initials from the user's email
    String getInitials(String email) {
      if (email.isEmpty) return '??';
      return email.substring(0, 2).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              getInitials(user.email ?? ''),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.email ?? 'No email associated',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// A reusable widget to group settings under a common title.
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
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior:
              Clip.antiAlias, // Ensures the ListTile background is clipped
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Builds the ListTile for toggling dark mode.
  Widget _buildDarkModeTile(ThemeProvider themeProvider, ThemeData theme) {
    return ListTile(
      leading: Icon(
        themeProvider.isDarkMode
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
        color: theme.colorScheme.primary,
      ),
      title: const Text('Dark Mode'),
      trailing: Switch(
        value: themeProvider.isDarkMode,
        onChanged: (value) => themeProvider.toggleTheme(),
        activeColor: theme.colorScheme.primary,
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
