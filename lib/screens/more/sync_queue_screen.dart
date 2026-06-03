import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/data_provider.dart';
import 'settings_screen.dart'; 

class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({super.key});

  @override
  State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  bool _isSyncing = false;

  void _startSync() async {
    setState(() => _isSyncing = true);
    
    try {
      // capture the warnings returned by the sync engine
      final warnings = await context.read<DataProvider>().syncPendingData();
      if (!mounted) return;
      
      if (warnings.isNotEmpty) {
        // show a dialog to the agent explaining that some distributions were cancelled
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: const Text('Sync Warnings', style: TextStyle(color: Colors.orange)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: warnings.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(w, style: const TextStyle(color: Colors.white, fontSize: 13)),
              )).toList(),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
            ],
          )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed successfully!', style: TextStyle(color: AppTheme.backgroundColor)), backgroundColor: AppTheme.primaryColor),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync failed. Please check connection.'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SYNC & QUEUE', style: TextStyle(letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCloudStatusCard(),
          const SizedBox(height: 32),
          _buildPendingSummary(provider),
          const SizedBox(height: 32),
          const Text('PENDING BREAKDOWN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildBreakdownList(provider),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: !_isSyncing ? _startSync : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.backgroundColor,
              disabledBackgroundColor: AppTheme.cardColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSyncing 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppTheme.backgroundColor, strokeWidth: 3))
                : const Text('INITIATE SYNC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }

  Widget _buildCloudStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.backgroundColor, shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryColor.withAlpha(77))), 
            child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Offline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 4),
                Text('Data is stored securely. Tap initiate sync to push to cloud.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSummary(DataProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pending Items', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${provider.pendingSyncCount}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.orange)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Last Sync', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                provider.lastSyncTime != null
                    ? DateFormat('MMM d, hh:mm a').format(provider.lastSyncTime!)
                    : 'Never',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownList(DataProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildBreakdownTile(Icons.local_shipping_outlined, 'Distributions', provider.pendingDistributionsCount),
          const Divider(height: 1, color: AppTheme.backgroundColor),
          _buildBreakdownTile(Icons.people_outline, 'Beneficiaries', provider.pendingBeneficiariesCount),
          const Divider(height: 1, color: AppTheme.backgroundColor),
          _buildBreakdownTile(Icons.inventory_2_outlined, 'Inventory Updates', provider.pendingInventoryCount),
        ],
      ),
    );
  }

  Widget _buildBreakdownTile(IconData icon, String label, int count) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      trailing: Text('$count', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: count > 0 ? Colors.orange : AppTheme.textSecondary)),
    );
  }
}