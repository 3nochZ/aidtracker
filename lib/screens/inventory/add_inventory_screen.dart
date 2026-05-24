import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/data_provider.dart';

class AddInventoryScreen extends StatefulWidget {
  const AddInventoryScreen({super.key});

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _notesController = TextEditingController();
  final _allocatedToController = TextEditingController();
  
  String _selectedUnit = 'kg';
  final List<String> _units = ['kg', 'L', 'pcs', 'boxes'];
  String? _selectedAgentId;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _notesController.dispose();
    _allocatedToController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<DataProvider>();
      provider.addInventoryItem(
        _nameController.text.trim(),
        _selectedUnit,
        int.parse(_quantityController.text.trim()),
        minStockLevel: int.tryParse(_minStockController.text.trim()) ?? 10,
        assignedAgentId: _selectedAgentId,
        allocatedTo: _allocatedToController.text.trim().isEmpty ? null : _allocatedToController.text.trim(),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final agents = provider.team.where((u) => u.role == 'agent' && u.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADD ITEM', style: TextStyle(letterSpacing: 1.5)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor.withAlpha(77), width: 2),
                ),
                child: const Icon(Icons.inventory_2, size: 50, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Item Name *'),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedUnit,
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Unit *'),
              items: _units.map((unit) {
                return DropdownMenuItem(value: unit, child: Text(unit));
              }).toList(),
              onChanged: (val) => setState(() => _selectedUnit = val!),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String?>(
              initialValue: _selectedAgentId,
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Assign to Agent *'),
              validator: (value) => value == null ? 'Required' : null,
              items: agents.map((agent) {
                return DropdownMenuItem<String?>(
                  value: agent.id,
                  child: Text(agent.name),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedAgentId = val),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Quantity *'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (int.tryParse(value) == null) return 'Must be a number';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _minStockController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Min. Stock Alert Level'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Notes (Optional)'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _allocatedToController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Allocated To (Optional)'),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}