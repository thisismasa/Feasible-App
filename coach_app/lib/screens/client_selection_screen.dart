import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../models/package_model.dart';
import '../services/database_service.dart';
import 'package_selection_screen.dart';

enum SelectionMode { booking, adhoc, general }

class ClientSelectionScreen extends StatefulWidget {
  final SelectionMode mode;
  final bool onlyActiveClients;

  ClientSelectionScreen({
    Key? key,
    this.mode = SelectionMode.general,
    this.onlyActiveClients = false,
  }) : super(key: key);

  @override
  State<ClientSelectionScreen> createState() => _ClientSelectionScreenState();
}

class _ClientSelectionScreenState extends State<ClientSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allClients = [];
  List<UserModel> _filteredClients = [];
  Map<String, ClientPackage?> _clientPackages = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    debugPrint('📱 ClientSelectionScreen: Loading clients (mode: ${widget.mode}, onlyActive: ${widget.onlyActiveClients})');
    _loadClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);

    try {
      // Get the current logged-in trainer's ID
      final trainerId = DatabaseService.instance.currentUserId ?? 'demo-trainer';
      debugPrint('🔑 Using trainer ID: $trainerId');

      // Load clients for this trainer using DatabaseService
      final clientsData = await DatabaseService.instance.getClientsForTrainer(trainerId);

      final clients = clientsData.map((data) => UserModel.fromJson(data)).toList();

      // If only active clients, filter by package
      if (widget.onlyActiveClients) {
        final activeClients = <UserModel>[];

        for (final client in clients) {
          // Check if client has active package
          final packages = await DatabaseService.instance.getClientPackages(
            clientId: client.id,
            status: 'active',
          );

          if (packages.isNotEmpty) {
            final package = packages.first;
            final remainingSessions = package['remaining_sessions'] ?? 0;
            if (remainingSessions > 0) {
              activeClients.add(client);
            }
          }
        }

        setState(() {
          _allClients = activeClients;
          _filteredClients = activeClients;
        });
      } else {
        setState(() {
          _allClients = clients;
          _filteredClients = clients;
        });
      }

      // Load packages for each client
      await _loadClientPackages();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load clients: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Error loading clients: $e');
    }
  }

  Future<void> _loadClientPackages() async {
    for (final client in _allClients) {
      try {
        final packages = await DatabaseService.instance.getClientPackages(
          clientId: client.id,
          status: 'active',
        );

        if (packages.isNotEmpty) {
          final packageData = packages.first;
          final remainingSessions = packageData['sessions_remaining'] ?? packageData['remaining_sessions'] ?? 0;

          if (remainingSessions > 0) {
            _clientPackages[client.id] = ClientPackage.fromSupabaseMap(packageData);
          } else {
            _clientPackages[client.id] = null;
            debugPrint('⚠️ Client ${client.id} has package with 0 remaining sessions');
          }
        } else {
          _clientPackages[client.id] = null;
          debugPrint('⚠️ Client ${client.id} has no active packages');
        }
      } catch (e) {
        _clientPackages[client.id] = null;
        debugPrint('❌ Error loading package for ${client.id}: $e');
      }
    }

    // If in booking mode with onlyActiveClients, filter out any clients whose packages failed to load
    if (widget.onlyActiveClients && widget.mode == SelectionMode.booking) {
      final validClients = _allClients.where((client) =>
        _clientPackages[client.id] != null &&
        _clientPackages[client.id]!.remainingSessions > 0
      ).toList();

      if (validClients.length != _allClients.length) {
        setState(() {
          _allClients = validClients;
          _filteredClients = validClients;
        });
        debugPrint('ℹ️ Filtered down to ${validClients.length} clients with valid packages');
      }
    }
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients = _allClients.where((client) {
        return client.name.toLowerCase().contains(query) ||
            client.email.toLowerCase().contains(query) ||
            (client.phone?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  String _getTitle() {
    switch (widget.mode) {
      case SelectionMode.booking:
        return 'Select Client for Booking';
      case SelectionMode.adhoc:
        return 'Select Client for Session';
      case SelectionMode.general:
        return 'Select Client';
    }
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadClients,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredClients.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildClientList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search clients...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildClientList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredClients.length,
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        final package = _clientPackages[client.id];
        return _buildClientCard(client, package);
      },
    );
  }

  Widget _buildClientCard(UserModel client, ClientPackage? package) {
    final hasActivePackage = package != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActivePackage ? Colors.green.shade200 : Colors.grey.shade200,
          width: hasActivePackage ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            _selectClient(client, package);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    client.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (client.phone != null && client.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          client.phone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                      if (hasActivePackage) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${package.remainingSessions} sessions left',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'No active package',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No clients found'
                : 'No clients yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search term'
                : 'Add your first client to get started',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _selectClient(UserModel client, ClientPackage? package) async {
    if (widget.mode == SelectionMode.booking && package == null) {
      // Show package purchase prompt
      final shouldPurchase = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Active Package'),
          content: Text(
            '${client.name} doesn\'t have an active package. Would you like to purchase one?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Purchase Package'),
            ),
          ],
        ),
      );

      if (shouldPurchase == true) {
        // Navigate to package purchase flow
        final packagePurchased = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PackageSelectionScreen(client: client),
          ),
        );

        // If package was purchased, reload and try again
        if (packagePurchased == true && mounted) {
          await _loadClients();

          // Get the updated package
          final updatedPackages = await DatabaseService.instance.getClientPackages(
            clientId: client.id,
            status: 'active',
          );

          if (updatedPackages.isNotEmpty && mounted) {
            final newPackage = ClientPackage.fromSupabaseMap(updatedPackages.first);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Package assigned! ${newPackage.remainingSessions} sessions available'),
                backgroundColor: Colors.green,
              ),
            );

            // Now return to booking with the new package
            Navigator.pop(context, {'client': client, 'package': newPackage});
          }
        }
      }
      return;
    }

    // Return selected client and package
    Navigator.pop(context, {'client': client, 'package': package});
  }
}
