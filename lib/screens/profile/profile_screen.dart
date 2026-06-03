import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/app_user.dart';
import 'package:intl/intl.dart';
import '../auth/login_screen.dart';
import 'team_management_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AppUser? user; // added optional user targets

  const ProfileScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    
    // if a specific user is passed, we show them. otherwise show logged-in user.
    final targetUser = user ?? auth.currentUser;
    final isViewingSelf = user == null || user?.id == auth.currentUser?.id;

    if (targetUser == null) return const SizedBox();

    String title = isViewingSelf ? 'MY PROFILE' : '${targetUser.role.toUpperCase()} PROFILE';
    if (!isViewingSelf && targetUser.role == 'admin') title = 'TEAM MEMBER PROFILE';

    // calculate agent-specific statistics based on exact ID logging
    final agentDistributionsCount = data.distributions.where((d) => d.agentId == targetUser.id).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(letterSpacing: 1.5)),
        actions: [
          if (isViewingSelf)
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.errorColor),
              onPressed: () {
                auth.logout();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              },
            )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Center(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle, border: Border.all(color: AppTheme.cardColor, width: 4)),
              child: Center(child: Text(targetUser.name[0], style: const TextStyle(fontSize: 40, color: AppTheme.backgroundColor, fontWeight: FontWeight.w900))),
            ),
          ),
          const SizedBox(height: 16),
          Text(targetUser.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(targetUser.email, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(targetUser.role == 'admin' ? Icons.admin_panel_settings : Icons.badge, color: AppTheme.primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Access Level: ${targetUser.role.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Stationed at ${targetUser.location}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text('OPERATIONAL METRICS', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatBox('Distributions Handled', agentDistributionsCount.toString())),
              const SizedBox(width: 16),
              Expanded(child: _buildStatBox('Status', targetUser.isActive ? 'ACTIVE' : 'SUSPENDED', color: targetUser.isActive ? AppTheme.primaryColor : AppTheme.errorColor)),
            ],
          ),

          const SizedBox(height: 32),

          const Text('ASSIGNED BENEFICIARIES', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final assignedBenes = data.beneficiaries.where((b) => b.assignedAgentId == targetUser.id).toList();
              if (assignedBenes.isEmpty) {
                return const Text('No beneficiaries explicitly assigned.', style: TextStyle(color: AppTheme.textSecondary));
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: assignedBenes.map((b) => Chip(
                  label: Text(b.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  backgroundColor: AppTheme.cardColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  avatar: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(b.name[0], style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                )).toList(),
              );
            },
          ),

          const SizedBox(height: 32),
          
          const Text('DISTRIBUTION HISTORY', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final history = data.distributions.where((d) => d.agentId == targetUser.id).toList();
              history.sort((a, b) => b.date.compareTo(a.date));
              
              if (history.isEmpty) {
                return const Text('No distributions logged yet.', style: TextStyle(color: AppTheme.textSecondary));
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final dist = history[index];
                  final benIdx = data.beneficiaries.indexWhere((b) => b.id == dist.beneficiaryId);
                  final benName = benIdx != -1 ? data.beneficiaries[benIdx].name : 'Unknown Beneficiary';
                  
                  String itemString = dist.items.keys.map((itemId) {
                    final itemIndex = data.inventory.indexWhere((i) => i.id == itemId);
                    final itemName = itemIndex != -1 ? data.inventory[itemIndex].name : 'Unknown Item';
                    return '$itemName (${dist.items[itemId]})';
                  }).join(' • ');

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(benName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Expanded(child: Text(itemString, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(DateFormat('MMM d, yyyy • hh:mm a').format(dist.date), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        if (dist.notes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(dist.notes, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontStyle: FontStyle.italic)),
                        ]
                      ],
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 32),
          
          const Text('ACCOUNT SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          if (isViewingSelf)
            ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(targetUser: targetUser, isAdminReset: false))),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: AppTheme.cardColor,
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.lock_outline, color: AppTheme.primaryColor)),
              title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            )
          else if (auth.isAdmin)
            ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(targetUser: targetUser, isAdminReset: true))),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: AppTheme.cardColor,
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.lock_reset, color: AppTheme.errorColor)),
              title: const Text('Force Reset Password', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorColor)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ),

          const SizedBox(height: 32),
          
          if (isViewingSelf && auth.isAdmin) ...[
            const Text('ADMINISTRATION', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamManagementScreen())),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: AppTheme.cardColor,
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.group, color: AppTheme.primaryColor)),
              title: const Text('Manage Team', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String count, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: (color ?? AppTheme.primaryColor).withAlpha(26))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color ?? AppTheme.primaryColor)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}