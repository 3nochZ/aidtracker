import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/data_provider.dart';
import '../../models/beneficiary.dart';
import '../../providers/auth_provider.dart';
import '../../models/inventory_item.dart';
import 'distribution_success_screen.dart';

class DistributeFlowScreen extends StatefulWidget {
  const DistributeFlowScreen({super.key});

  @override
  State<DistributeFlowScreen> createState() => _DistributeFlowScreenState();
}

class _DistributeFlowScreenState extends State<DistributeFlowScreen> {
  int _currentStep = 0;
  Beneficiary? _selectedBeneficiary;
  final Map<InventoryItem, int> _selectedItems = {};
  final _notesController = TextEditingController();
  String _searchQuery = '';

  void _nextStep() {
    if (_currentStep == 0 && _selectedBeneficiary == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a beneficiary'), backgroundColor: AppTheme.errorColor));
      return;
    }
    if (_currentStep == 1 && !_selectedItems.values.any((qty) => qty > 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one item'), backgroundColor: AppTheme.errorColor));
      return;
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    setState(() => _currentStep--);
  }

  void _confirmAndSave() async {
    final provider = context.read<DataProvider>();
    
     
    // grab the current logged-in user session dynamically
    final currentUser = context.read<AuthProvider>().currentUser; 

    // Flag self-registered distributions for admin review if still pending
    String notes = _notesController.text;
    if (_selectedBeneficiary?.status == 'pending' &&
        _selectedBeneficiary?.registeredByAgentId != null &&
        _selectedBeneficiary!.registeredByAgentId == currentUser?.id) {
      notes = '[SELF-REGISTERED] $notes';
    }

    // pass the logged-in user's real metadata, fallback only if null
    await provider.recordDistribution(
      _selectedBeneficiary!, 
      _selectedItems, 
      notes,
      agentId: currentUser?.id ?? 'unknown_id',      
      agentName: currentUser?.name ?? 'unknown_name',  
    );   
    
    setState(() {
      _currentStep = 0;
      _selectedBeneficiary = null;
      _selectedItems.clear();
      _notesController.clear();
      _searchQuery = '';
    });

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DistributionSuccessScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RECORD DISTRIBUTION', style: TextStyle(letterSpacing: 1.5)),
        leading: _currentStep > 0 
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevStep)
            : null,
      ),
      body: Column(
        children: [
          _buildStepperHeader(),
          Expanded(
            child: _currentStep == 0 
                ? _buildBeneficiarySelection() 
                : _currentStep == 1 
                    ? _buildItemSelection() 
                    : _buildReviewStep(),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.cardColor, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepIndicator(0, 'BENEFICIARY'),
          Expanded(child: Divider(color: _currentStep >= 1 ? AppTheme.primaryColor : AppTheme.cardColor, thickness: 2)),
          _buildStepIndicator(1, 'ITEMS'),
          Expanded(child: Divider(color: _currentStep >= 2 ? AppTheme.primaryColor : AppTheme.cardColor, thickness: 2)),
          _buildStepIndicator(2, 'REVIEW'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label) {
    bool isActive = _currentStep >= stepIndex;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : AppTheme.backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary, width: 2),
          ),
          child: Center(
            child: Text(
              '${stepIndex + 1}',
              style: TextStyle(color: isActive ? AppTheme.backgroundColor : AppTheme.textSecondary, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildBeneficiarySelection() {
    final auth = context.watch<AuthProvider>();
    final allBeneficiaries = context.watch<DataProvider>().beneficiaries;
    
    final beneficiaries = allBeneficiaries.where((b) {
      if (!auth.isAdmin) {
        if (b.assignedAgentId != null && b.assignedAgentId != auth.currentUser?.id) {
          return false;
        }
      }

      return b.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             b.location.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Search beneficiary...',
              prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            ),
          ),
        ),
        // Self-registration fraud warning (only if still pending)
        if (_selectedBeneficiary != null &&
            _selectedBeneficiary!.status == 'pending' &&
            _selectedBeneficiary!.registeredByAgentId != null &&
            _selectedBeneficiary!.registeredByAgentId == auth.currentUser?.id)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withAlpha(77)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You registered this beneficiary. Distribution will be flagged for admin review.',
                    style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: beneficiaries.isEmpty 
          ? const Center(child: Text('No matches found.', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: beneficiaries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = beneficiaries[index];
              final isSelected = _selectedBeneficiary?.id == b.id;
              return ListTile(
                onTap: () => setState(() => _selectedBeneficiary = b),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent, width: 2),
                ),
                tileColor: AppTheme.cardColor,
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(b.name[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
                ),
                title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text('${b.group.toUpperCase()} • ${b.location}', style: const TextStyle(color: AppTheme.textSecondary)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemSelection() {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    
    // Filter inventory items based on role (admins see all, agents only see their assigned inventory)
    final inventory = data.inventory.where((item) {
      if (auth.isAdmin) return true;
      return item.assignedAgentId == auth.currentUser?.id;
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: inventory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = inventory[index];
        final currentQty = _selectedItems[item] ?? 0;

        // Check if beneficiary has received this item in the last 30 days
        final bool isRationLocked = data.hasReceivedItemInLast30Days(_selectedBeneficiary!.id, item.id);

        final team = data.team;
        final agentIdx = team.indexWhere((u) => u.id == item.assignedAgentId);
        final assignedAgentName = agentIdx != -1 ? team[agentIdx].name : 'Unknown Agent';

        return _ItemQuantityInputRow(
          item: item,
          currentQty: currentQty,
          isLocked: isRationLocked,
          assignedAgentName: assignedAgentName,
          onChanged: (newQty) {
            setState(() {
              if (newQty <= 0) {
                _selectedItems.remove(item);
              } else {
                _selectedItems[item] = newQty;
              }
            });
          },
        );
      },
    );
  }

  Widget _buildReviewStep() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('BENEFICIARY', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: AppTheme.cardColor,
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(_selectedBeneficiary!.name[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
          ),
          title: Text(_selectedBeneficiary!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text('${_selectedBeneficiary!.group.toUpperCase()} • Household: ${_selectedBeneficiary!.householdSize}', style: const TextStyle(color: AppTheme.textSecondary)),
        ),
        const SizedBox(height: 32),
        const Text('ITEMS', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: _selectedItems.entries.where((e) => e.value > 0).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key.name, style: const TextStyle(fontSize: 16)),
                    Text('${entry.value} ${entry.key.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Notes (Optional)'),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppTheme.backgroundColor,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _currentStep == 2 ? _confirmAndSave : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _currentStep == 2 ? 'CONFIRM & SAVE' : 'NEXT STEP',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemQuantityInputRow extends StatefulWidget {
  final InventoryItem item;
  final int currentQty;
  final bool isLocked; 
  final String? assignedAgentName;
  final ValueChanged<int> onChanged;

  const _ItemQuantityInputRow({
    required this.item,
    required this.currentQty,
    required this.isLocked,
    this.assignedAgentName,
    required this.onChanged,
  });

  @override
  State<_ItemQuantityInputRow> createState() => _ItemQuantityInputRowState();
}

class _ItemQuantityInputRowState extends State<_ItemQuantityInputRow> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.currentQty > 0 ? widget.currentQty.toString() : ''
    );
  }

  @override
  void didUpdateWidget(covariant _ItemQuantityInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentQty != oldWidget.currentQty) {
      final newText = widget.currentQty > 0 ? widget.currentQty.toString() : '';
      if (_textController.text != newText) {
        _textController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleTextChange(String value) {
    int parsedValue = int.tryParse(value) ?? 0;
    
    if (parsedValue > widget.item.quantity) {
      parsedValue = widget.item.quantity;
      _textController.text = parsedValue.toString();
      _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
    }
    
    widget.onChanged(parsedValue);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isLocked ? AppTheme.errorColor.withAlpha(50) : Colors.transparent, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.isLocked ? AppTheme.errorColor.withAlpha(50) : AppTheme.primaryColor.withAlpha(50)),
                ),
                child: Icon(Icons.inventory_2_outlined, color: widget.isLocked ? AppTheme.errorColor : AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.isLocked ? Colors.grey : Colors.white)),
                    if (widget.item.allocatedTo != null && widget.item.allocatedTo!.isNotEmpty)
                      Text('Allocated to: ${widget.item.allocatedTo}', style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    if (widget.assignedAgentName != null)
                      Text('Agent: ${widget.assignedAgentName}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Available: ${widget.item.quantity} ${widget.item.unit}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              
              if (!widget.isLocked)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: widget.currentQty > 0 ? Colors.white : AppTheme.textSecondary,
                      onPressed: () {
                        if (widget.currentQty > 0) widget.onChanged(widget.currentQty - 1);
                      },
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _textController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary, width: 1)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
                        ),
                        onChanged: _handleTextChange,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: widget.currentQty < widget.item.quantity ? AppTheme.primaryColor : AppTheme.textSecondary,
                      onPressed: () {
                        final limit = widget.item.quantity;
                        if (widget.currentQty < limit) widget.onChanged(widget.currentQty + 1);
                      },
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.errorColor.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, color: AppTheme.errorColor, size: 14),
                      SizedBox(width: 4),
                      Text('LOCKED', style: TextStyle(color: AppTheme.errorColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          
          if (widget.isLocked) ...[
            const SizedBox(height: 12),
            const Divider(color: AppTheme.backgroundColor, height: 1),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(
                  Icons.error_outline, 
                  color: AppTheme.errorColor, 
                  size: 14,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '30-Day Cooldown Active (Item received within the last 30 days)',
                    style: TextStyle(
                      color: AppTheme.errorColor, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}