import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/data_provider.dart';
import 'sync_queue_screen.dart';
import 'settings_screen.dart'; 
import 'reports_screen.dart';
import 'audit_logs_screen.dart';
import '../../providers/auth_provider.dart';
import '../beneficiaries/beneficiaries_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.watch<DataProvider>().pendingSyncCount;

    return Scaffold(
      appBar: AppBar(title: const Text('OPTIONS', style: TextStyle(letterSpacing: 1.5))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuTile(
            context: context,
            icon: Icons.sync,
            title: 'Sync & Queue',
            iconColor: AppTheme.primaryColor,
            trailingWidget: pendingCount > 0 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                    child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncQueueScreen())),
          ),
          const SizedBox(height: 12),
          if (context.watch<AuthProvider>().isAdmin) ...[
            _buildMenuTile(
              context: context,
              icon: Icons.pending_actions,
              title: 'Pending Approvals',
              iconColor: Colors.orange,
              trailingWidget: context.watch<DataProvider>().pendingApprovalBeneficiaries.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                      child: Text('${context.watch<DataProvider>().pendingApprovalBeneficiaries.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  : null,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BeneficiariesScreen(showPendingOnly: true))),
            ),
            const SizedBox(height: 12),
          ],
          _buildMenuTile(
            context: context,
            icon: Icons.bar_chart,
            title: 'System Reports',
            iconColor: AppTheme.primaryColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            context: context,
            icon: Icons.security,
            title: 'Audit Trail',
            iconColor: AppTheme.errorColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen())),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            context: context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            iconColor: AppTheme.textSecondary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({required BuildContext context, required IconData icon, required String title, required Color iconColor, Widget? trailingWidget, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: AppTheme.cardColor,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingWidget != null) ...[trailingWidget, const SizedBox(width: 12)],
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}
