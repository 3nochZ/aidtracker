import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_theme.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/inventory_item.dart';
import 'add_inventory_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;
    final currentUser = authProvider.currentUser;
    
    final filteredInventory = dataProvider.inventory.where((item) {
      if (isAdmin) return true;
      return item.assignedAgentId == currentUser?.id;
    }).toList();

    final allItems = filteredInventory.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final lowStockItems = allItems.where((item) => item.quantity <= item.minStockLevel).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Search items...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, hintStyle: TextStyle(color: AppTheme.textSecondary)),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('INVENTORY', style: TextStyle(letterSpacing: 1.5)),
          actions: [
            if (isAdmin && !_isSearching)
              IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: 'Import from CSV',
                onPressed: () => _importCsv(context),
              ),
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () => setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              }),
            ),
            if (!_isSearching)
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
        body: Column(
          children: [
            _buildSummaryRow(context, allItems.length, lowStockItems.length),
            const TabBar(
              labelColor: AppTheme.primaryColor, 
              unselectedLabelColor: AppTheme.textSecondary, 
              indicatorColor: AppTheme.primaryColor,
              dividerColor: AppTheme.cardColor,
              tabs: [Tab(text: 'All Items'), Tab(text: 'Low Stock')],
            ),
            Expanded(
              child: TabBarView(
                children: [_buildItemList(allItems, isAdmin), _buildLowStockList(lowStockItems, isAdmin)],
              ),
            ),
          ],
        ),
        floatingActionButton: isAdmin 
            ? FloatingActionButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInventoryScreen())),
                child: const Icon(Icons.add),
              ) 
            : null,
      ),
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null) {
      final file = File(result.files.single.path!);
      final csvData = await file.readAsString();
      if (context.mounted) {
        await context.read<DataProvider>().importInventoryFromCsv(csvData);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import complete!')));
        }
      }
    }
  }

  Widget _buildSummaryRow(BuildContext context, int totalCount, int lowCount) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(child: _buildSummaryCard('Total Items', '$totalCount', AppTheme.primaryColor)),
          const SizedBox(width: 16),
          Expanded(child: _buildSummaryCard('Low Stock', '$lowCount', AppTheme.errorColor, isAlert: lowCount > 0)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color countColor, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAlert ? AppTheme.errorColor.withAlpha(77) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: countColor)),
              if (isAlert) ...[const Spacer(), Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor)]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(List<InventoryItem> items, bool isAdmin) {
    if (items.isEmpty) return const Center(child: Text('No items found.', style: TextStyle(color: AppTheme.textSecondary)));
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildItemTile(items[index], isAdmin, context),
    );
  }

  Widget _buildLowStockList(List<InventoryItem> items, bool isAdmin) {
    if (items.isEmpty && _searchQuery.isEmpty) return const Center(child: Text('All stock levels are optimal.', style: TextStyle(color: AppTheme.primaryColor)));
    if (items.isEmpty && _searchQuery.isNotEmpty) return const Center(child: Text('No matching low stock items.', style: TextStyle(color: AppTheme.textSecondary)));

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.errorColor.withAlpha(77), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.errorColor.withAlpha(77))),
          child: Row(
            children: [
              const Icon(Icons.warning, color: AppTheme.errorColor),
              const SizedBox(width: 12),
              Expanded(child: Text('${items.length} items are critically low. Please restock to maintain operational capacity.', style: const TextStyle(color: AppTheme.errorColor, fontSize: 13))),
            ],
          ),
        ),
        Expanded(child: _buildItemList(items, isAdmin)),
      ],
    );
  }

  Widget _buildItemTile(InventoryItem item, bool isAdmin, BuildContext context) {
    final isLow = item.quantity <= item.minStockLevel;
    
    String? assignedAgentName;
    if (isAdmin && item.assignedAgentId != null) {
      final team = context.read<DataProvider>().team;
      final agentIdx = team.indexWhere((u) => u.id == item.assignedAgentId);
      if (agentIdx != -1) {
        assignedAgentName = team[agentIdx].name;
      } else {
        assignedAgentName = 'Unknown Agent';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor, 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isLow ? AppTheme.errorColor.withAlpha(77) : AppTheme.primaryColor.withAlpha(77)),
            ),
            child: Icon(Icons.inventory_2_outlined, color: isLow ? AppTheme.errorColor : AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (item.allocatedTo != null && item.allocatedTo!.isNotEmpty)
                  Text('Allocated to: ${item.allocatedTo}', style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${item.quantity} ${item.unit} available', style: TextStyle(fontSize: 13, color: isLow ? AppTheme.errorColor : AppTheme.textSecondary)),
                if (assignedAgentName != null) ...[
                  const SizedBox(height: 4),
                  Text('Assigned to: $assignedAgentName', style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
                ],
              ],
            ),
          ),
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppTheme.errorColor.withAlpha(77), size: 24),
              onPressed: () {
                context.read<DataProvider>().deleteInventoryItem(item.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} deleted.')));
              },
            ),
        ],
      ),
    );
  }
}