import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_theme.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_beneficiary_screen.dart';
import 'beneficiary_detail_screen.dart';
import '../../models/beneficiary.dart';
import '../../models/app_user.dart';

class BeneficiariesScreen extends StatefulWidget {
  final bool showPendingOnly;
  const BeneficiariesScreen({super.key, this.showPendingOnly = false});

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String _sortBy = 'name_asc';

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sort by', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Name (A - Z)'),
                trailing: _sortBy == 'name_asc' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  setState(() => _sortBy = 'name_asc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Name (Z - A)'),
                trailing: _sortBy == 'name_desc' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  setState(() => _sortBy = 'name_desc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Household Size (Largest First)'),
                trailing: _sortBy == 'household_desc' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  setState(() => _sortBy = 'household_desc');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    
    List<Beneficiary> beneficiaries = widget.showPendingOnly 
        ? dataProvider.pendingApprovalBeneficiaries 
        : dataProvider.beneficiaries;

    beneficiaries = beneficiaries.where((b) {
      return b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             b.location.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (_sortBy == 'name_asc') {
      beneficiaries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'name_desc') {
      beneficiaries.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else if (_sortBy == 'household_desc') {
      beneficiaries.sort((a, b) => b.householdSize.compareTo(a.householdSize));
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search by name or camp...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : Text(widget.showPendingOnly ? 'PENDING APPROVALS' : 'BENEFICIARIES', style: const TextStyle(letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = ''; 
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterOptions,
            ),
          if (!_isSearching && isAdmin)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Import from CSV',
              onPressed: () => _importCsv(context),
            ),
        ],
      ),
      body: beneficiaries.isEmpty
          ? Center(child: Text(widget.showPendingOnly ? 'No pending approvals.' : 'No beneficiaries found.', style: const TextStyle(color: AppTheme.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: beneficiaries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final b = beneficiaries[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BeneficiaryDetailScreen(beneficiaryId: b.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryColor.withAlpha(76)),
                          ),
                          child: Center(child: Text(b.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${b.id.substring(0, 5)} • ${b.location}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Text('Household: ${b.householdSize}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        if (widget.showPendingOnly) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Registered by: ${b.registeredByAgentName ?? 'Admin / System'}',
                                style: const TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
                              ),
                            ],
                            ],
                          ),
                        ),
                        if (widget.showPendingOnly && isAdmin)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  final admin = context.read<AuthProvider>().currentUser;
                                  dataProvider.approveBeneficiary(b.id, approvedBy: admin != null ? AppUser(id: admin.id, name: admin.name, email: admin.email, password: admin.password, role: admin.role, location: admin.location) : null);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: AppTheme.backgroundColor, padding: const EdgeInsets.symmetric(horizontal: 10)),
                                child: const Text('APPROVE', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () => _confirmReject(context, b, dataProvider),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
                                child: const Text('REJECT', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          )
                        else
                          Icon(Icons.chevron_right, color: AppTheme.textSecondary.withAlpha(128)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBeneficiaryScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null) {
      final file = File(result.files.single.path!);
      final csvData = await file.readAsString();
      if (context.mounted) {
        await context.read<DataProvider>().importBeneficiariesFromCsv(csvData);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import complete!')));
        }
      }
    }
  }

  void _confirmReject(BuildContext context, Beneficiary b, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Reject Beneficiary?'),
        content: Text('This will permanently reject "${b.name}" and remove them on next sync.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final admin = context.read<AuthProvider>().currentUser;
              if (admin != null) {
                dataProvider.rejectBeneficiary(
                  b.id,
                  rejectedBy: AppUser(id: admin.id, name: admin.name, email: admin.email, password: admin.password, role: admin.role, location: admin.location),
                );
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${b.name}" rejected.')));
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
