import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/app_theme.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../models/distribution.dart';
import 'more/sync_queue_screen.dart'; 
import 'auth/login_screen.dart'; 
import 'profile/profile_screen.dart'; 
import 'beneficiaries/beneficiaries_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        _isOnline = results.any((result) => result != ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      drawer: _buildDrawer(context), 
      appBar: AppBar(
        title: const Text('AID TRACKER', style: TextStyle(letterSpacing: 2)),
        actions: [
          Icon(_isOnline ? Icons.wifi : Icons.wifi_off, color: _isOnline ? AppTheme.primaryColor : AppTheme.errorColor, size: 20),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing...')));
              try {
                final currentUserId = context.read<AuthProvider>().currentUser?.id;
                // capture warnings
                final warnings = await context.read<DataProvider>().syncPendingData(currentUserId: currentUserId);
                if (context.mounted) {
                  if (warnings.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(warnings.join('\n')), backgroundColor: Colors.orange));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync complete!')));
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e'), backgroundColor: AppTheme.errorColor));
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeText(context),
            const SizedBox(height: 24),
            _buildSystemStatusCard(dataProvider.pendingSyncCount, context),
            
            if (dataProvider.lowStockItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLowStockWarning(dataProvider.lowStockItems),
            ],

            if (isAdmin) ...[
              const SizedBox(height: 16),
              _buildApprovalWarning(dataProvider.pendingApprovalBeneficiaries.length, context),
            ],

            const SizedBox(height: 32),
            const Text('SYSTEM METRICS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _buildOverviewGrid(context, dataProvider),
            const SizedBox(height: 32),
            const Text('RECENT ACTIVITY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _buildRecentDistributions(dataProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockWarning(List<dynamic> lowStockItems) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${lowStockItems.length} items below minimum stock level!',
              style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalWarning(int count, BuildContext context) {
    final bool hasPending = count > 0;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BeneficiariesScreen(showPendingOnly: true))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasPending ? AppTheme.primaryColor.withAlpha(26) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasPending ? AppTheme.primaryColor.withAlpha(77) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(Icons.pending_actions, color: hasPending ? AppTheme.primaryColor : AppTheme.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                hasPending ? '$count beneficiary profiles awaiting approval.' : 'No pending beneficiary approvals.',
                style: TextStyle(color: hasPending ? AppTheme.primaryColor : AppTheme.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.chevron_right, color: hasPending ? AppTheme.primaryColor : AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final firstName = user?.name.split(' ')[0].toUpperCase() ?? 'AGENT';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(firstName, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, height: 1, color: Colors.white)),
        const SizedBox(height: 16),
        Text(
          'Welcome to the field dashboard. Ensure your data is synced and monitor real-time distribution metrics and inventory levels to avoid stockouts.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Drawer(
      backgroundColor: AppTheme.cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.backgroundColor),
            accountName: Text(user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            accountEmail: Text('${user?.role.toUpperCase()} • ${user?.location ?? ''}', style: const TextStyle(color: AppTheme.textSecondary)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(user?.name[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 24, color: AppTheme.backgroundColor, fontWeight: FontWeight.bold)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text('Log Out', style: TextStyle(color: AppTheme.errorColor)),
            onTap: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard(int pendingCount, BuildContext context) {
    bool isOperational = pendingCount == 0;
    
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncQueueScreen())),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isOperational ? AppTheme.primaryColor.withAlpha(77) : Colors.orange.withAlpha(77)), 
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(isOperational ? 'All Systems Synced' : 'Sync Pending', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isOperational ? AppTheme.primaryColor : Colors.orange),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pending Items', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('$pendingCount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isOperational ? AppTheme.textPrimary : Colors.orange)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Last Checked', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM d, hh:mm a').format(DateTime.now()), style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewGrid(BuildContext context, DataProvider data) {
    int totalItemsLeft = data.inventory.fold(0, (sum, item) => sum + item.quantity);
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 900 ? 4 : 2;
    double aspectRatio = screenWidth > 900 ? 1.6 : 1.5; 

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: aspectRatio,
      children: [
        _buildStatCard(Icons.people, '${data.beneficiaries.length}', 'Beneficiaries'),
        _buildStatCard(Icons.inventory, '${data.totalDistributions}', 'Distributions'),
        _buildStatCard(Icons.widgets, '${data.inventory.length}', 'Inventory Items'),
        _buildStatCard(Icons.archive, '$totalItemsLeft', 'Items Left'),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String count, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildRecentDistributions(DataProvider data) {
    if (data.distributions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('No activity tracked yet.', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }
    final recent = data.distributions.take(3).toList(); 
    return Column(
      children: recent.map((dist) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: _buildDistributionTile(dist, data),
      )).toList(),
    );
  }

  Widget _buildDistributionTile(Distribution dist, DataProvider data) {
    String itemString = dist.items.keys.map((id) {
      final itemIndex = data.inventory.indexWhere((i) => i.id == id);
      final itemName = itemIndex != -1 ? data.inventory[itemIndex].name : 'Unknown Item';
      return '$itemName (${dist.items[id]})';
    }).join(' • ');

    if (itemString.isEmpty) itemString = 'Items removed';
    String formattedDate = DateFormat('MMM d, hh:mm a').format(dist.date);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withAlpha(26),
            child: Text(dist.beneficiaryName.isNotEmpty ? dist.beneficiaryName[0] : '?', style: const TextStyle(color: AppTheme.primaryColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dist.beneficiaryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(itemString, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text(formattedDate, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Icon(dist.syncStatus == 'pending' ? Icons.cloud_upload_outlined : Icons.check_circle, color: dist.syncStatus == 'pending' ? Colors.orange : AppTheme.primaryColor, size: 20),
        ],
      ),
    );
  }
}