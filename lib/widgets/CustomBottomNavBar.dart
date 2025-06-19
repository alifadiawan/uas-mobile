import 'package:flutter/material.dart';
import 'package:mobile_uas/Notes/InsertNotes.dart'; // Import is no longer needed here but left for context
import 'package:mobile_uas/Notes/NotesIndex.dart';
import 'package:mobile_uas/Category/CategoryIndex.dart';
import 'package:mobile_uas/Calender/CalenderIndex.dart';
import 'package:mobile_uas/Settings.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({Key? key, required this.currentIndex})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // A regular, flat BottomAppBar
    return BottomAppBar(
      elevation: 0,
      color: Theme.of(context).colorScheme.background,
      surfaceTintColor: Theme.of(context).colorScheme.background,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              Icons.description_outlined,
              'Notes',
              0,
              () => _navigateToPage(context, const NotesIndex()),
            ),
            _buildNavItem(
              context,
              Icons.folder_outlined,
              'Category',
              1,
              () => _navigateToPage(context, const Categoryindex()),
            ),
            // The central "Add" button has been removed from here.
            _buildNavItem(
              context,
              Icons.calendar_today_outlined,
              'Calendar',
              2,
              () => _navigateToPage(context, const Calenderindex()),
            ),
            _buildNavItem(
              context,
              Icons.settings_outlined,
              'Settings',
              3,
              () => _navigateToPage(context, const Settings()),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the standard navigation items
  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int itemIndex,
    VoidCallback onTap,
  ) {
    final bool isSelected = currentIndex == itemIndex;
    final theme = Theme.of(context);
    final color = isSelected ? Colors.grey.shade800 : Colors.grey.shade500;
    final isDarkMode = theme.brightness == Brightness.dark;

    final finalColor =
        isDarkMode
            ? isSelected
                ? theme.colorScheme.primary
                : Colors.grey.shade500
            : color;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: finalColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: finalColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigation logic (no changes needed here)
  void _navigateToPage(BuildContext context, Widget page) {
    if (ModalRoute.of(context)?.settings.name == page.runtimeType.toString())
      return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
        settings: RouteSettings(name: page.runtimeType.toString()),
      ),
    );
  }
}
