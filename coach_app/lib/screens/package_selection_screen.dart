import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';
import '../models/user_model.dart';
import '../models/package_model.dart';
import '../services/supabase_service.dart';
import 'payment_method_selection_screen.dart';

class PackageSelectionScreen extends StatefulWidget {
  final UserModel client;

  const PackageSelectionScreen({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<PackageSelectionScreen> createState() => _PackageSelectionScreenState();
}

class _PackageSelectionScreenState extends State<PackageSelectionScreen> {
  List<PackageModel> _availablePackages = [];
  PackageModel? _selectedPackage;
  DateTime _startDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _autoRenew = false;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Custom package fields
  bool _isCreatingCustom = false;
  final _customNameController = TextEditingController();
  final _customDescriptionController = TextEditingController();
  final _customPriceController = TextEditingController();
  final _customSessionsController = TextEditingController();
  final _customValidityController = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _customDescriptionController.dispose();
    _customPriceController.dispose();
    _customSessionsController.dispose();
    _customValidityController.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    try {
      final response = await SupabaseService.instance.client
          .from('packages')
          .select()
          .eq('is_active', true)
          .order('price');
      
      if (response is List) {
        setState(() {
          _availablePackages = (response as List)
              .map((data) => PackageModel(
                    id: data['id'] ?? '',
                    name: data['name'] ?? 'Unnamed Package',
                    description: data['description'] ?? '',
                    price: (data['price'] ?? 0).toDouble(),
                    sessionCount: data['sessions'] ?? data['session_count'] ?? 0,
                    validityDays: data['validity_days'] ?? 30,
                    isActive: data['is_active'] ?? true,
                    createdAt: data['created_at'] != null
                        ? DateTime.parse(data['created_at'])
                        : DateTime.now(),
                  ))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading packages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Select Package'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isCreatingCustom = !_isCreatingCustom;
              });
            },
            icon: Icon(_isCreatingCustom ? Icons.list : Icons.edit),
            label: Text(_isCreatingCustom ? 'Presets' : 'Custom'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isCreatingCustom
                  ? _buildCustomPackageForm()
                  : _buildPackageList(),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPackageList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Client Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  widget.client.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigning package to:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      widget.client.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Package Options
        const Text(
          'Available Packages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_availablePackages.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.card_giftcard,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No packages available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isCreatingCustom = true;
                    });
                  },
                  child: const Text('Create Custom Package'),
                ),
              ],
            ),
          )
        else
          ..._availablePackages.map((package) => _buildPackageCard(package)),
        
        if (_selectedPackage != null) ...[
          const SizedBox(height: 24),
          const Text(
            'Package Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildConfigurationSection(),
        ],
      ],
    );
  }

  Widget _buildCustomPackageForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Custom Package',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Design a personalized package for ${widget.client.name}',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Package Details Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _customNameController,
                  decoration: const InputDecoration(
                    labelText: 'Package Name',
                    hintText: 'e.g., Premium Training Package',
                    prefixIcon: Icon(Icons.label),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _customDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What does this package include?',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customSessionsController,
                        decoration: const InputDecoration(
                          labelText: 'Number of Sessions',
                          prefixIcon: Icon(Icons.fitness_center),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _customValidityController,
                        decoration: const InputDecoration(
                          labelText: 'Validity (days)',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _customPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Package Price',
                    prefixText: '\$',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 24),
                
                // Price Calculator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Price per session:'),
                          Text(
                            _calculatePricePerSession(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sessions per week:'),
                          Text(
                            _calculateSessionsPerWeek(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Save as Preset Option
                CheckboxListTile(
                  value: false,
                  onChanged: (value) {
                    // Save as preset logic
                  },
                  title: const Text('Save as preset package'),
                  subtitle: const Text('Make this package available for other clients'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Configuration Section
          const Text(
            'Package Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildConfigurationSection(),
        ],
      ),
    );
  }

  Widget _buildPackageCard(PackageModel package) {
    final isSelected = _selectedPackage?.id == package.id;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OpenContainer(
        closedElevation: 0,
        openElevation: 4,
        closedColor: Colors.transparent,
        openColor: Colors.white,
        transitionDuration: const Duration(milliseconds: 500),
        closedBuilder: (context, openContainer) {
          return InkWell(
            onTap: () {
              setState(() {
                _selectedPackage = package;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isSelected
                            ? [Colors.blue.shade400, Colors.blue.shade600]
                            : [Colors.grey.shade300, Colors.grey.shade400],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          package.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${package.sessionCount} sessions',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${package.validityDays} days',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '฿${package.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.blue : Colors.black,
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            package.sessionCount > 0
                                ? '฿${(package.price / package.sessionCount).toStringAsFixed(0)}/session'
                                : '฿${package.price.toStringAsFixed(0)}/month',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        openBuilder: (context, _) {
          return _buildPackageDetails(package);
        },
      ),
    );
  }

  Widget _buildPackageDetails(PackageModel package) {
    return Scaffold(
      appBar: AppBar(
        title: Text(package.name),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    package.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${package.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Package Details
            _buildDetailRow('Description', package.description),
            _buildDetailRow('Number of Sessions', '${package.sessionCount}'),
            _buildDetailRow('Validity Period', '${package.validityDays} days'),
            _buildDetailRow(
              'Price per Session',
              '\$${(package.price / package.sessionCount).toStringAsFixed(2)}',
            ),
            
            const SizedBox(height: 24),
            
            // What's Included
            const Text(
              "What's Included",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildIncludedItem('Personal training sessions'),
            _buildIncludedItem('Progress tracking'),
            _buildIncludedItem('Flexible scheduling'),
            _buildIncludedItem('Professional guidance'),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedPackage = package;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Select This Package',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Column(
      children: [
        // Start Date Selection
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Package Start Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _selectStartDate(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, MMMM dd, yyyy').format(_startDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Package will expire on ${DateFormat('MMM dd, yyyy').format(
                          _startDate.add(Duration(
                            days: _selectedPackage?.validityDays ?? 30,
                          )),
                        )}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Payment method selection removed - now handled by PaymentMethodSelectionScreen
        // User will see beautiful payment screens after clicking "Assign Package"
      ],
    );
  }

  Widget _buildBottomBar() {
    final canProceed = _isCreatingCustom
        ? _customNameController.text.isNotEmpty &&
            _customPriceController.text.isNotEmpty &&
            _customSessionsController.text.isNotEmpty
        : _selectedPackage != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    _isCreatingCustom
                        ? '\$${_customPriceController.text.isEmpty ? '0.00' : double.tryParse(_customPriceController.text)?.toStringAsFixed(2) ?? '0.00'}'
                        : '\$${_selectedPackage?.price.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canProceed && !_isSaving ? _assignPackage : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Assign Package',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _paymentMethod = value;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.green : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.green : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  String _calculatePricePerSession() {
    if (_customPriceController.text.isEmpty ||
        _customSessionsController.text.isEmpty) {
      return '\$0.00';
    }
    
    final price = double.tryParse(_customPriceController.text) ?? 0;
    final sessions = int.tryParse(_customSessionsController.text) ?? 1;
    
    return '\$${(price / sessions).toStringAsFixed(2)}';
  }

  String _calculateSessionsPerWeek() {
    if (_customSessionsController.text.isEmpty ||
        _customValidityController.text.isEmpty) {
      return '0';
    }
    
    final sessions = int.tryParse(_customSessionsController.text) ?? 0;
    final days = int.tryParse(_customValidityController.text) ?? 1;
    final weeks = days / 7;
    
    return (sessions / weeks).toStringAsFixed(1);
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _assignPackage() async {
    setState(() {
      _isSaving = true;
    });

    try {
      PackageModel packageToAssign;

      if (_isCreatingCustom) {
        // Create custom package
        packageToAssign = PackageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _customNameController.text,
          description: _customDescriptionController.text,
          price: double.parse(_customPriceController.text),
          sessionCount: int.parse(_customSessionsController.text),
          validityDays: int.parse(_customValidityController.text),
          isActive: true,
          createdAt: DateTime.now(),
        );
      } else {
        packageToAssign = _selectedPackage!;
      }

      setState(() {
        _isSaving = false;
      });

      // Navigate to payment method selection screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMethodSelectionScreen(
            package: packageToAssign,
            client: widget.client,
            isSubscription: packageToAssign.isRecurring,
          ),
        ),
      );

      // If payment was completed, go back
      if (result != null && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning package: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

