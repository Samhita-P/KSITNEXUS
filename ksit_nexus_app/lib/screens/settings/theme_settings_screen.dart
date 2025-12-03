import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../services/theme_service.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme is always light - no need to watch provider
    // final currentTheme = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Show info that light mode is always enabled
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.infoLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.info),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.info),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Light Mode Always Enabled',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'The app is configured to always use light mode for consistency across all devices.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Disabled theme options
                  RadioListTile<AppThemeMode>(
                    title: const Row(
                      children: [
                        Icon(Icons.light_mode, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Light'),
                        SizedBox(width: 8),
                        Icon(Icons.check, size: 18, color: Colors.green),
                      ],
                    ),
                    value: AppThemeMode.light,
                    groupValue: AppThemeMode.light,
                    onChanged: null, // Disabled
                  ),
                  RadioListTile<AppThemeMode>(
                    title: Row(
                      children: [
                        Icon(Icons.dark_mode, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          'Dark',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(Disabled)',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    value: AppThemeMode.dark,
                    groupValue: AppThemeMode.light,
                    onChanged: null, // Disabled
                  ),
                  RadioListTile<AppThemeMode>(
                    title: Row(
                      children: [
                        Icon(Icons.brightness_auto, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          'System Default',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(Disabled)',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Follow system theme (Disabled)',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    value: AppThemeMode.system,
                    groupValue: AppThemeMode.light,
                    onChanged: null, // Disabled
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme Preview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sample Card',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This is how your app will look with the selected theme.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text('Primary Button'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {},
                              child: const Text('Secondary'),
                            ),
                          ],
                        ),
                      ],
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
}

















