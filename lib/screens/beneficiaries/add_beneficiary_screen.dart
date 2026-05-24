import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/beneficiary.dart';

class AddBeneficiaryScreen extends StatefulWidget {
  final Beneficiary? beneficiary; // added optional edit target

  const AddBeneficiaryScreen({super.key, this.beneficiary});

  @override
  State<AddBeneficiaryScreen> createState() => _AddBeneficiaryScreenState();
}

class _AddBeneficiaryScreenState extends State<AddBeneficiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _subCityController = TextEditingController();
  final _kebeleController = TextEditingController();
  final _houseNoController = TextEditingController();
  final _householdSizeController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGroup = 'General';
  final List<String> _groups = ['General', 'Elderly', 'Vulnerable', 'Pregnant/Lactating'];
  String? _selectedAgentId;

  @override
  void initState() {
    super.initState();
    // if editing, pre-populate all form fields
    if (widget.beneficiary != null) {
      final b = widget.beneficiary!;
      _nameController.text = b.name;
      _householdSizeController.text = b.householdSize.toString();
      _selectedGroup = b.group;
      _selectedAgentId = b.assignedAgentId;
      
      // parse combined location back into its constituent city/sub-city components
      final parts = b.location.split(', ');
      if (parts.length >= 4) {
        _cityController.text = parts[0];
        _subCityController.text = parts[1];
        _kebeleController.text = parts[2].replaceAll('Kebele ', '');
        _houseNoController.text = parts[3].replaceAll('House No. ', '');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _subCityController.dispose();
    _kebeleController.dispose();
    _houseNoController.dispose();
    _householdSizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<DataProvider>();
      final String formattedLocation = '${_cityController.text.trim()}, '
          '${_subCityController.text.trim()}, '
          'Kebele ${_kebeleController.text.trim()}, '
          'House No. ${_houseNoController.text.trim()}';

      if (widget.beneficiary != null) {
        // edit existing profile
        provider.updateBeneficiary(
          widget.beneficiary!.id,
          _nameController.text.trim(),
          formattedLocation,
          int.parse(_householdSizeController.text.trim()),
          _selectedGroup,
          assignedAgentId: _selectedAgentId,
        );
      } else {
        // create brand new profile
        final auth = context.read<AuthProvider>();
        final currentUser = auth.currentUser;
        provider.addBeneficiary(
          _nameController.text.trim(),
          formattedLocation,
          int.parse(_householdSizeController.text.trim()),
          group: _selectedGroup,
          assignedAgentId: _selectedAgentId,
          isAdmin: auth.isAdmin,
          registeredByAgentId: auth.isAdmin ? null : currentUser?.id,
          registeredByAgentName: auth.isAdmin ? null : currentUser?.name,
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.beneficiary != null;
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final agents = context.watch<DataProvider>().team.where((u) => u.role != 'admin').toList();

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'EDIT BENEFICIARY' : 'ADD BENEFICIARY', style: const TextStyle(letterSpacing: 1.5))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildAvatarPicker(),
            const SizedBox(height: 32),
            
            const Text('PERSONAL DETAILS', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Full Name *'),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _householdSizeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Household Size *'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Must be > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedGroup, 
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Target Demographic Group *'),
              items: _groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _selectedGroup = val!),
            ),
            
            if (isAdmin) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _selectedAgentId,
                dropdownColor: AppTheme.cardColor,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Assign to Agent (Optional)'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Unassigned (Open to All Agents)')),
                  ...agents.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                ],
                onChanged: (val) => setState(() => _selectedAgentId = val),
              ),
            ],

            const SizedBox(height: 32),
            const Text('LOCATION DETAILS', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'City *'),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _subCityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Sub City *'),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kebeleController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Kebele *'),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _houseNoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'House No. *'),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text('ADDITIONAL INFO', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Notes (Optional)'),
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
              child: Text(isEdit ? 'SAVE CHANGES' : 'CREATE ACCOUNT', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor.withAlpha(128), width: 2),
            ),
            child: const Icon(Icons.person, size: 50, color: AppTheme.textSecondary),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.backgroundColor, width: 3),
              ),
              child: const Icon(Icons.camera_alt, color: AppTheme.backgroundColor, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}