import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_theme.dart';
import '../../providers/data_provider.dart';
import '../../models/distribution.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _dateFilter = 'All Time';
  final List<String> _filters = ['Last 7 days', 'Last 30 days', 'All Time'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPORTS & METRICS', style: TextStyle(letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Distributions to CSV',
            onPressed: () => _exportDistributionsToCsv(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFilterChips(),
          const SizedBox(height: 24),
          const Text('INVENTORY STABILITY', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildInventoryStockCard(),
          const SizedBox(height: 32),
          const Text('DISTRIBUTION SUMMARY', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildDistributionSummary(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _filters.map((filter) {
        final isSelected = _dateFilter == filter;
        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _dateFilter = filter);
          },
          selectedColor: AppTheme.primaryColor,
          labelStyle: TextStyle(color: isSelected ? AppTheme.backgroundColor : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          backgroundColor: AppTheme.cardColor,
        );
      }).toList(),
    );
  }

  List<Distribution> _getFilteredDistributions() {
    final data = context.read<DataProvider>();
    final all = data.distributions;
    if (_dateFilter == 'All Time') return all;
    
    final now = DateTime.now();
    final threshold = _dateFilter == 'Last 7 days' 
        ? now.subtract(const Duration(days: 7)) 
        : now.subtract(const Duration(days: 30));
    
    return all.where((d) => d.date.isAfter(threshold)).toList();
  }

  Widget _buildInventoryStockCard() {
    final data = context.watch<DataProvider>();
    final items = data.inventory;
    
    if (items.isEmpty) return _buildEmptyCard('No items to analyze.');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: items.map((item) {
          final isLow = item.quantity <= item.minStockLevel;
          final double ratio = (item.quantity / (item.quantity + item.minStockLevel + 1));

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${item.quantity} ${item.unit} left', style: TextStyle(color: isLow ? AppTheme.errorColor : AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio > 1.0 ? 1.0 : ratio,
                    backgroundColor: AppTheme.backgroundColor,
                    color: isLow ? AppTheme.errorColor : AppTheme.primaryColor,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistributionSummary() {
    final filtered = _getFilteredDistributions();
    if (filtered.isEmpty) return _buildEmptyCard('No distributions in this period.');

    final data = context.read<DataProvider>();
    Map<String, int> itemTotals = {};
    for (var d in filtered) {
      d.items.forEach((id, qty) {
        itemTotals[id] = (itemTotals[id] ?? 0) + qty;
      });
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: itemTotals.entries.map((entry) {
          final itemIdx = data.inventory.indexWhere((i) => i.id == entry.key);
          final name = itemIdx != -1 ? data.inventory[itemIdx].name : 'Removed Item';
          final unit = itemIdx != -1 ? data.inventory[itemIdx].unit : '';
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(color: AppTheme.textSecondary)),
                Text('${entry.value} $unit', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Center(child: Text(msg, style: const TextStyle(color: AppTheme.textSecondary))),
    );
  }

  Future<void> _exportDistributionsToCsv(BuildContext context) async {
    final data = context.read<DataProvider>();
    final distributions = data.distributions;

    List<List<dynamic>> rows = [];
    rows.add(['ID', 'Date', 'Beneficiary', 'Items', 'Agent', 'Notes']);

    for (var d in distributions) {
      String itemsStr = d.items.entries.map((e) {
        final itemIdx = data.inventory.indexWhere((i) => i.id == e.key);
        final name = itemIdx != -1 ? data.inventory[itemIdx].name : 'Unknown';
        return '$name: ${e.value}';
      }).join('; ');

      rows.add([
        d.id,
        d.date.toIso8601String(),
        d.beneficiaryName,
        itemsStr,
        d.agentName,
        d.notes,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/distributions_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(path)], text: 'Distribution History Export');
  }
}
