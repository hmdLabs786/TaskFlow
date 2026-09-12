import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';
import '../providers/task_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Appearance', colorScheme),
          _buildSettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: themeController.themeMode == ThemeMode.dark
                ? 'Currently dark'
                : 'Currently light',
            trailing: Switch(
              value: themeController.themeMode == ThemeMode.dark,
              onChanged: (_) => themeController.toggleThemeMode(),
              activeColor: colorScheme.primary,
            ),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Notifications', colorScheme),
          _buildSettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Task Reminders',
            subtitle: 'Get notified when tasks are due',
            trailing: Switch(
              value: true,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? 'Notifications enabled'
                        : 'Notifications disabled'),
                  ),
                );
              },
              activeColor: colorScheme.primary,
            ),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Data', colorScheme),
          _buildSettingsTile(
            icon: Icons.delete_sweep_rounded,
            title: 'Clear Completed Tasks',
            subtitle: 'Remove all completed tasks',
            trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            onTap: () => _showClearCompletedDialog(context),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('About', colorScheme),
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            subtitle: '1.0.0+1',
            trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showClearCompletedDialog(BuildContext context) {
    final provider = context.read<TaskProvider>();
    final completedCount = provider.completedCount;
    
    if (completedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No completed tasks to clear')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Tasks'),
        content: Text('Are you sure you want to delete $completedCount completed task(s)? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearCompletedTasks();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$completedCount completed task(s) cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
