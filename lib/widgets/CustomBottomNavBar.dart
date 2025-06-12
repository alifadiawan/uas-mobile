import 'package:flutter/material.dart';
import 'package:mobile_uas/Notes/NotesIndex.dart';
import 'package:mobile_uas/Category/CategoryIndex.dart';
import 'package:mobile_uas/Calender/CalenderIndex.dart';
import 'package:mobile_uas/Settings.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
        color: colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              Icons.home_rounded,
              'Home',
              currentIndex == 0,
              () => _navigateToPage(context, NotesIndex()),
              theme,
            ),
            _buildNavItem(
              context,
              Icons.folder_rounded,
              'Category',
              currentIndex == 1,
              () => _navigateToPage(context, Categoryindex()),
              theme,
            ),
            SizedBox(width: 60),
            _buildNavItem(
              context,
              Icons.calendar_today_rounded,
              'Calendar',
              currentIndex == 2,
              () => _navigateToPage(context, Calenderindex()),
              theme,
            ),
            _buildNavItem(
              context,
              Icons.settings_rounded,
              'Settings',
              currentIndex == 3,
              () => _navigateToPage(context, Settings()),
              theme,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected
                ? colorScheme.primary
                : theme.iconTheme.color?.withOpacity(0.5),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? colorScheme.primary
                  : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}