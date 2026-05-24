import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // added this import
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/app_user.dart';
import 'add_beneficiary_screen.dart';

class BeneficiaryDetailScreen extends StatefulWidget {
  final String beneficiaryId; 

  const BeneficiaryDetailScreen({super.key, required this.beneficiaryId});

  @override
  State<BeneficiaryDetailScreen> createState() => _BeneficiaryDetailScreenState();
}

class _BeneficiaryDetailScreenState extends State<BeneficiaryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    final beneficiary = data.beneficiaries.firstWhere(
      (b) => b.id == widget.beneficiaryId,
      orElse: () => data.beneficiaries.first,
    );

    final history = data.distributions.where((d) => d.beneficiaryId == beneficiary.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiary Profile'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit), 
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddBeneficiaryScreen(beneficiary: beneficiary)),
                );
              }
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Beneficiary?'),
                    content: const Text('This will remove the person locally and permanently delete them from the cloud upon next sync.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('Delete', style: TextStyle(color: Colors.red))
                      ),
                    ],
                  )
                );

                if (confirm == true && context.mounted) {
                  await context.read<DataProvider>().deleteBeneficiary(beneficiary.id);
                  if (!context.mounted) return; 
                  Navigator.pop(context); 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beneficiary deleted.')));
                }
              },
            ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            _buildHeader(beneficiary, data, isAdmin),
            const TabBar(
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryColor,
              tabs: [Tab(text: 'Details'), Tab(text: 'Distributions'), Tab(text: 'Notes')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDetailsTab(beneficiary, data),
                  _buildDistributionsTab(history, data), 
                  _buildNotesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic beneficiary, DataProvider data, bool isAdmin) {
    return Container(
      width: double.infinity,
      color: beneficiary.status == 'pending' ? Colors.orange : AppTheme.primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          if (beneficiary.status == 'pending')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Text('PENDING APPROVAL', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withAlpha(50), 
            child: Text(beneficiary.name[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Text(beneficiary.name, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${beneficiary.id.substring(0, 8)} • ${beneficiary.location}', style: const TextStyle(color: Colors.white, fontSize: 13)),
          if (beneficiary.status == 'pending' && isAdmin) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final admin = context.read<AuthProvider>().currentUser;
                    data.approveBeneficiary(beneficiary.id, approvedBy: admin != null ? AppUser(id: admin.id, name: admin.name, email: admin.email, password: admin.password, role: admin.role, location: admin.location) : null);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${beneficiary.name}" approved.')));
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('APPROVE'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.cardColor,
                        title: const Text('Reject Beneficiary?'),
                        content: Text('This will permanently reject "${beneficiary.name}".'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              final admin = context.read<AuthProvider>().currentUser;
                              if (admin != null) {
                                data.rejectBeneficiary(
                                  beneficiary.id,
                                  rejectedBy: AppUser(id: admin.id, name: admin.name, email: admin.email, password: admin.password, role: admin.role, location: admin.location),
                                );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${beneficiary.name}" rejected.')));
                              }
                            },
                            child: const Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('REJECT'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab(dynamic beneficiary, DataProvider data) {
    String assignedAgentStr = 'Unassigned (Open to All Agents)';
    if (beneficiary.assignedAgentId != null) {
      final agentIdx = data.team.indexWhere((u) => u.id == beneficiary.assignedAgentId);
      if (agentIdx != -1) {
        assignedAgentStr = data.team[agentIdx].name;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDetailRow(Icons.location_on, 'Location', beneficiary.location),
        const Divider(),
        _buildDetailRow(Icons.people, 'Household Size', '${beneficiary.householdSize}'),
        const Divider(),
        _buildDetailRow(Icons.person_add, 'Registered By', beneficiary.registeredByAgentName ?? 'Admin / System Import'),
        const Divider(),
        _buildDetailRow(Icons.badge, 'Assigned Agent', assignedAgentStr),
        const Divider(),
        _buildDetailRow(Icons.sync, 'Sync Status', beneficiary.syncStatus),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionsTab(List<dynamic> history, DataProvider data) {
    if (history.isEmpty) {
      return const Center(child: Text('No historical distribution logs.', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final dist = history[index];
        
        String itemString = dist.items.keys.map((id) {
          final itemIndex = data.inventory.indexWhere((i) => i.id == id);
          final itemName = itemIndex != -1 ? data.inventory[itemIndex].name : 'Unknown Item';
          return '$itemName (${dist.items[id]})';
        }).join(' • ');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(itemString, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
  }

  Widget _buildNotesTab() {
    return const Center(child: Text('no additional notes.'));
  }
}