import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/distribution.dart';

class DistributionHistoryScreen extends StatelessWidget {
  const DistributionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final list = data.distributions;

    return Scaffold(
      appBar: AppBar(title: const Text('DISTRIBUTION HISTORY', style: TextStyle(letterSpacing: 1.5))),
      body: list.isEmpty
          ? const Center(child: Text('No historical logs found.', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final dist = list[index];
                return _buildHistoryCard(context, dist, data, auth);
              },
            ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Distribution dist, DataProvider data, AuthProvider auth) {
    final formattedDate = DateFormat('MMM d, hh:mm a').format(dist.date);

    // build display items list string
    String itemString = dist.items.keys.map((id) {
      final itemIdx = data.inventory.indexWhere((i) => i.id == id);
      final itemName = itemIdx != -1 ? data.inventory[itemIdx].name : 'Unknown Item';
      return '$itemName (${dist.items[id]})';
    }).join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dist.beneficiaryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(itemString, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Text(formattedDate, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                if (dist.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(dist.notes, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          
          if (auth.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
              onPressed: () => _showEditDialog(context, dist, data, auth),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              onPressed: () => _confirmDelete(context, dist, data, auth),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
            ),
          ]
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Distribution dist, DataProvider data, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Delete Distribution Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this distribution for ${dist.beneficiaryName}? This will revert item quantities back to inventory and log the action.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              data.deleteDistribution(dist.id, auth.currentUser!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Distribution deleted and inventory reverted.')));
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Distribution dist, DataProvider data, AuthProvider auth) {
    final controllers = <String, TextEditingController>{};
    dist.items.forEach((itemId, qty) {
      controllers[itemId] = TextEditingController(text: qty.toString());
    });
    
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Edit ${dist.beneficiaryName}\'s Allocation', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...dist.items.keys.map((id) {
                final itemIdx = data.inventory.indexWhere((i) => i.id == id);
                final itemName = itemIdx != -1 ? data.inventory[itemIdx].name : 'Unknown Item';
                final itemUnit = itemIdx != -1 ? data.inventory[itemIdx].unit : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(child: Text(itemName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: controllers[id],
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(itemUnit, style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Correction notes (required)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reason is required!'), backgroundColor: AppTheme.errorColor));
                return;
              }
              
              final editedItems = <String, int>{};
              controllers.forEach((id, ctrl) {
                editedItems[id] = int.tryParse(ctrl.text) ?? 0;
              });

              data.updateDistributionAndLog(dist.id, editedItems, reasonController.text.trim(), auth.currentUser!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Distribution corrected and logged!')));
            },
            child: const Text('Save Changes', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}