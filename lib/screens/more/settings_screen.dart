import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS', style: TextStyle(letterSpacing: 1.5))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('GENERAL', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: AppTheme.cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.language, color: AppTheme.textSecondary)),
            title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('English', style: TextStyle(color: AppTheme.textSecondary)),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Multi-language support coming soon'))),
          ),
          
          const SizedBox(height: 32),
          const Text('DATA & SYNC', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          SwitchListTile(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            tileColor: AppTheme.cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            secondary: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.wifi_tethering, color: AppTheme.textSecondary)),
            title: const Text('Sync on Wi-Fi Only', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Saves cellular data', style: TextStyle(color: AppTheme.textSecondary)),
            value: true,
            // Removed deprecated activeColor property. Material 3 will automatically use AppTheme.primaryColor
            onChanged: (val) {},
          ),
          const Divider(height: 1, color: AppTheme.backgroundColor),
          ListTile(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
            tileColor: AppTheme.cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.cleaning_services, color: AppTheme.errorColor)),
            title: const Text('Clear Local Cache', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
            subtitle: const Text('Frees up device storage', style: TextStyle(color: AppTheme.textSecondary)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared successfully!')));
            },
          ),
        ],
      ),
    );
  }
}