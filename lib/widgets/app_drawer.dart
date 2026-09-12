import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/theme_controller.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'TaskFlow_app_logo_design_20260912140615.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'TaskFlow',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(
              context,
              icon: Icons.check_circle_rounded,
              title: 'My Tasks',
              color: colorScheme.primary,
              onTap: () {
                provider.setCategory('All');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'LISTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _drawerItem(
              context,
              icon: Icons.work_outline_rounded,
              title: 'Work',
              color: const Color(0xFF5B5FC7),
              onTap: () {
                provider.setCategory('Work');
                Navigator.pop(context);
              },
            ),
            _drawerItem(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Personal',
              color: const Color(0xFF00897B),
              onTap: () {
                provider.setCategory('Personal');
                Navigator.pop(context);
              },
            ),
            _drawerItem(
              context,
              icon: Icons.priority_high_rounded,
              title: 'Urgent',
              color: const Color(0xFFD93025),
              onTap: () {
                provider.setCategory('Urgent');
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(indent: 16, endIndent: 16),
            _drawerItem(
              context,
              icon: Icons.settings_rounded,
              title: 'Settings',
              color: colorScheme.onSurfaceVariant,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _drawerItem(
              context,
              icon: Icons.info_outline_rounded,
              title: 'About',
              color: colorScheme.onSurfaceVariant,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
