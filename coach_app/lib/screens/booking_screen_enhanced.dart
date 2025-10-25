import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../models/package_model.dart';
import '../models/session_model.dart';
import '../services/database_service.dart';

/// Enhanced Booking Screen - Production Ready with Advanced Features
/// Fixes: Race conditions, time conflicts, business logic, UX improvements
class BookingScreenEnhanced extends StatefulWidget {
  final UserModel client;
  final ClientPackage package;
  final String? trainerId;

  const BookingScreenEnhanced({
    Key? key,
    required this.client,
    required this.package,
    this.trainerId,
  }) : super(key: key);

  @override
  State<BookingScreenEnhanced> createState() => _BookingScreenEnhancedState();
}

class _BookingScreenEnhancedState extends State<BookingScreenEnhanced>
    with TickerProviderStateMixin {
  // Controllers & Animation
  late TabController _tabController;
  late AnimationController _slideController;
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  // Booking State
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now(); // Track focused day separately for calendar
  TimeSlotInfo? _selectedSlot;
  int _currentStep = 0;
  
  // Configuration
  int _duration = 60;
  SessionType _sessionType = SessionType.inPerson;
  String? _selectedLocation;
  bool _isRecurring = false;
  RecurrencePattern _recurrencePattern = RecurrencePattern.weekly;
  int _recurrenceCount = 4;
  
  // Data
  List<SessionModel> _existingSessions = [];
  Map<DateTime, List<TimeSlotInfo>> _slotsCache = {};
  bool _isLoading = false;
  String? _errorMessage;
  
  // Business Rules
  final BookingConstraints constraints = BookingConstraints();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _loadExistingSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _slideController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSessions() async {
    setState(() => _isLoading = true);

    try {
      // Load sessions for the next 90 days using DatabaseService
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 90));

      // Load BOTH trainer sessions AND client sessions to check availability
      final trainerSessionsFuture = DatabaseService.instance.getTrainerSessions(
        trainerId: widget.trainerId ?? 'demo-trainer',
        startDate: now,
        endDate: endDate,
        status: 'scheduled',
      );

      final clientSessionsFuture = DatabaseService.instance.getClientSessions(
        clientId: widget.client.id,
        startDate: now,
        endDate: endDate,
      );

      // Wait for both queries to complete
      final results = await Future.wait<List<Map<String, dynamic>>>([
        trainerSessionsFuture,
        clientSessionsFuture,
      ]);
      final trainerSessions = results[0];
      final clientSessions = results[1];

      // Combine both lists and convert to SessionModel
      final allSessions = <SessionModel>[];

      for (final data in trainerSessions) {
        allSessions.add(SessionModel.fromSupabaseMap(data));
      }

      for (final data in clientSessions) {
        // Only add client sessions that are scheduled/confirmed
        final status = data['status'] as String?;
        if (status == 'scheduled' || status == 'confirmed') {
          allSessions.add(SessionModel.fromSupabaseMap(data));
        }
      }

      setState(() {
        _existingSessions = allSessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load availability: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Error loading sessions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final steps = ['Date & Time', 'Details', 'Confirm'];
    
    return AppBar(
      title: const Text('Book Session', style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.blue,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: List.generate(steps.length, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.blue
                                      : (isCompleted ? Colors.green : Colors.grey.shade300),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: isActive ? Colors.white : Colors.grey.shade600,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  steps[index],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    color: isActive ? Colors.blue : Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 20,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: isCompleted ? Colors.green : Colors.grey.shade300,
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return PageView(
      controller: PageController(initialPage: _currentStep),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildDateTimeStep(),
        _buildDetailsStep(),
        _buildConfirmationStep(),
      ],
    );
  }

  Widget _buildDateTimeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Select Date',
            'Choose a date for your training session',
            Icons.calendar_today,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildEnhancedCalendar(),
          const SizedBox(height: 24),
          // Duration auto-set to 60 min (package default)
          // Removed manual duration selection for simplified UX
          if (_selectedDay != null) ...[
            _buildSectionHeader(
              'Available Time Slots',
              'Select a time that works for you',
              Icons.schedule,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildTimeSlotsLegend(),
            const SizedBox(height: 12),
            _buildEnhancedTimeSlots(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Session Type',
            'Where will this session take place?',
            Icons.place,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildSessionTypeSelector(),
          const SizedBox(height: 24),
          if (_sessionType == SessionType.inPerson) ...[
            _buildSectionHeader(
              'Location',
              'Select training location',
              Icons.location_on,
              Colors.red,
            ),
            const SizedBox(height: 16),
            _buildLocationSelector(),
            const SizedBox(height: 24),
          ],
          _buildSectionHeader(
            'Recurring Session',
            'Book multiple sessions at once',
            Icons.repeat,
            Colors.indigo,
          ),
          const SizedBox(height: 16),
          _buildRecurringOptions(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Session Notes',
            'Any special requests or notes?',
            Icons.note,
            Colors.teal,
          ),
          const SizedBox(height: 16),
          _buildNotesField(),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    if (_selectedDay == null || _selectedSlot == null) {
      return const Center(child: Text('Please complete previous steps'));
    }
    
    final totalSessions = _isRecurring ? _recurrenceCount : 1;
    final recurringDates = _isRecurring ? _calculateRecurringDates() : [_selectedDay!];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.purple.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Review Your Booking',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please review the details below',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildConfirmationCard(
            'Client Information',
            Icons.person,
            Colors.blue,
            [
              _buildDetailRow('Name', widget.client.name),
              _buildDetailRow('Email', widget.client.email),
              _buildDetailRow('Phone', widget.client.phone),
            ],
          ),
          const SizedBox(height: 16),
          _buildConfirmationCard(
            'Session Details',
            Icons.fitness_center,
            Colors.orange,
            [
              _buildDetailRow('Type', _sessionType == SessionType.inPerson ? 'In-Person' : 'Online'),
              if (_sessionType == SessionType.inPerson)
                _buildDetailRow('Location', _selectedLocation ?? 'Not specified'),
              _buildDetailRow('Duration', '$_duration minutes'),
              _buildDetailRow('Date', DateFormat('EEEE, MMM d, yyyy').format(_selectedDay!)),
              _buildDetailRow('Time', DateFormat('h:mm a').format(_selectedSlot!.startTime)),
              if (_isRecurring)
                _buildDetailRow('Sessions', '$totalSessions sessions (${_recurrencePattern.name})'),
            ],
          ),
          const SizedBox(height: 16),
          _buildConfirmationCard(
            'Package Information',
            Icons.card_giftcard,
            Colors.green,
            [
              _buildDetailRow('Package', widget.package.packageName),
              _buildDetailRow('Current Balance', '${widget.package.remainingSessions} sessions'),
              _buildDetailRow('After Booking', '${widget.package.remainingSessions - totalSessions} sessions'),
              _buildDetailRow('Expires', DateFormat('MMM d, yyyy').format(widget.package.expiryDate)),
            ],
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 16),
            _buildConfirmationCard(
              'Recurring Dates',
              Icons.calendar_month,
              Colors.purple,
              recurringDates.map((date) => 
                _buildDetailRow(
                  DateFormat('EEEE').format(date),
                  DateFormat('MMM d, yyyy h:mm a').format(
                    DateTime(date.year, date.month, date.day, 
                      _selectedSlot!.startTime.hour, _selectedSlot!.startTime.minute),
                  ),
                )
              ).toList(),
            ),
          ],
          if (_notesController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildConfirmationCard(
              'Session Notes',
              Icons.note,
              Colors.teal,
              [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _notesController.text,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          _buildCancellationPolicy(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedCalendar() {
    final now = DateTime.now();
    final minDate = now.add(Duration(hours: constraints.minAdvanceHours));
    final maxDate = now.add(Duration(days: constraints.maxAdvanceDays));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: minDate,
        lastDay: maxDate,
        focusedDay: _focusedDay, // Use _focusedDay instead of _selectedDay
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableGestures: AvailableGestures.horizontalSwipe,
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.orange.shade300,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          HapticFeedback.lightImpact();

          try {
            constraints.validateDate(selectedDay);
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay; // Update focused day when selecting
              _selectedSlot = null;
              _slotsCache.remove(selectedDay); // Refresh slots
            });
          } catch (e) {
            _showErrorSnackbar(e.toString());
          }
        },
        onPageChanged: (focusedDay) {
          // Update focused day when navigating months
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final sessionsOnDay = _existingSessions.where((s) =>
              isSameDay(s.scheduledDate, date)).length;
            
            if (sessionsOnDay > 0) {
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    final durations = [30, 45, 60, 90, 120];
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: durations.map((duration) {
        final isSelected = _duration == duration;
        final canSelect = true; // All durations allowed for now
        
        return GestureDetector(
          onTap: canSelect
              ? () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _duration = duration;
                    _selectedSlot = null;
                    if (_selectedDay != null) {
                      _slotsCache.remove(_selectedDay!);
                    }
                  });
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    )
                  : null,
              color: isSelected
                  ? null
                  : (canSelect ? Colors.white : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.orange
                    : (canSelect ? Colors.grey.shade300 : Colors.grey.shade400),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Text(
                  '$duration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (canSelect ? Colors.orange : Colors.grey),
                  ),
                ),
                Text(
                  'minutes',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Colors.white
                        : (canSelect ? Colors.grey.shade600 : Colors.grey),
                  ),
                ),
                if (!canSelect)
                  Text(
                    'Not in package',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade400,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlotsLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Colors.green.shade100, 'Available'),
          _buildLegendItem(Colors.red.shade100, 'Booked'),
          _buildLegendItem(Colors.orange.shade100, 'Buffer'),
          _buildLegendItem(Colors.grey.shade200, 'Unavailable'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildEnhancedTimeSlots() {
    final slots = _getAvailableSlots(_selectedDay!);
    
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No available slots for this date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try a different date or duration',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    // Group by time of day
    final morningSlots = slots.where((s) => s.startTime.hour < 12).toList();
    final afternoonSlots = slots.where((s) => s.startTime.hour >= 12 && s.startTime.hour < 17).toList();
    final eveningSlots = slots.where((s) => s.startTime.hour >= 17).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morningSlots.isNotEmpty) _buildTimeSection('Morning', morningSlots, Icons.wb_sunny),
        if (afternoonSlots.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTimeSection('Afternoon', afternoonSlots, Icons.wb_cloudy),
        ],
        if (eveningSlots.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTimeSection('Evening', eveningSlots, Icons.nightlight),
        ],
      ],
    );
  }

  Widget _buildTimeSection(String title, List<TimeSlotInfo> slots, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${slots.where((s) => s.isAvailable).length} available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((slot) => _buildTimeSlotChip(slot)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotChip(TimeSlotInfo slot) {
    final isSelected = _selectedSlot?.startTime == slot.startTime;
    
    return Tooltip(
      message: slot.unavailableReason ?? 'Available',
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('h:mm a').format(slot.startTime),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (!slot.isAvailable) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.block,
                size: 14,
                color: slot.displayColor,
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: slot.isAvailable
            ? (selected) {
                HapticFeedback.selectionClick();
                debugPrint('🕐 Slot clicked: ${slot.startTime}, selected: $selected');
                setState(() {
                  _selectedSlot = selected ? slot : null;
                  debugPrint('✅ _selectedSlot set to: ${_selectedSlot?.startTime}');
                  debugPrint('📅 _selectedDay: $_selectedDay');
                  debugPrint('🔘 Can proceed: ${_canProceed()}');
                });
              }
            : null,
        backgroundColor: slot.displayColor,
        selectedColor: Colors.blue,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : (slot.isAvailable ? Colors.black87 : Colors.grey.shade600),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildSessionTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            SessionType.inPerson,
            'In-Person',
            'At gym or location',
            Icons.location_on,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeCard(
            SessionType.online,
            'Online',
            'Video call session',
            Icons.videocam,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(
    SessionType type,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _sessionType == type;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _sessionType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withOpacity(0.7)])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    final locations = ['Main Gym', 'Downtown Studio', 'Park Training', 'Client Home'];
    
    return Column(
      children: locations.map((location) {
        final isSelected = _selectedLocation == location;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            value: location,
            groupValue: _selectedLocation,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _selectedLocation = value);
            },
            title: Text(location),
            secondary: Icon(
              Icons.place,
              color: isSelected ? Colors.red : Colors.grey,
            ),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? Colors.red : Colors.grey.shade300,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecurringOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _isRecurring,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _isRecurring = value);
            },
            title: const Text(
              'Make this a recurring session',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Book multiple sessions at once',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            activeColor: Colors.indigo,
          ),
          if (_isRecurring) ...[
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRecurringOption(
                    RecurrencePattern.weekly,
                    'Weekly',
                    'Same day each week',
                    Icons.calendar_view_week,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRecurringOption(
                    RecurrencePattern.biweekly,
                    'Bi-Weekly',
                    'Every 2 weeks',
                    Icons.calendar_view_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Number of sessions: $_recurrenceCount',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _recurrenceCount.toDouble(),
              min: 2,
              max: math.min(12, widget.package.remainingSessions.toDouble()),
              divisions: (math.min(12, widget.package.remainingSessions) - 2).toInt(),
              label: '$_recurrenceCount sessions',
              activeColor: Colors.indigo,
              onChanged: (value) {
                setState(() => _recurrenceCount = value.round());
              },
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _recurrenceCount > widget.package.remainingSessions
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _recurrenceCount > widget.package.remainingSessions
                        ? Icons.warning
                        : Icons.check_circle,
                    size: 20,
                    color: _recurrenceCount > widget.package.remainingSessions
                        ? Colors.red
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _recurrenceCount > widget.package.remainingSessions
                          ? 'Not enough sessions in package'
                          : 'Package has enough sessions',
                      style: TextStyle(
                        fontSize: 12,
                        color: _recurrenceCount > widget.package.remainingSessions
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurringOption(
    RecurrencePattern pattern,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _recurrencePattern == pattern;
    
    return GestureDetector(
      onTap: () {
        setState(() => _recurrencePattern = pattern);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.indigo : Colors.grey),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.indigo : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'E.g., Focus on upper body, injury to mention, etc.',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationPolicy() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Cancellation Policy',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Free cancellation up to 24 hours before\n'
            '• 50% charge for cancellations within 24 hours\n'
            '• No refund for no-shows\n'
            '• Rescheduling allowed up to 12 hours before',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _currentStep--);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(color: Colors.blue),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (_selectedDay != null && _selectedSlot != null) || _currentStep > 0 ? _handleNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedDay != null && _selectedSlot != null) || _currentStep > 0 ? Colors.blue : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Text(
                  _currentStep == 2 ? 'Confirm Booking' : 'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: (_selectedDay != null && _selectedSlot != null) || _currentStep > 0 ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Business Logic
  List<TimeSlotInfo> _getAvailableSlots(DateTime date) {
    // Check cache first
    if (_slotsCache.containsKey(date)) {
      return _slotsCache[date]!;
    }
    
    final slots = <TimeSlotInfo>[];
    final schedule = constraints.getBusinessHours(date);
    
    if (!schedule.isWorkingDay) {
      _slotsCache[date] = [];
      return [];
    }
    
    var currentTime = DateTime(
      date.year,
      date.month,
      date.day,
      schedule.startHour,
      schedule.startMinute,
    );
    
    final endTime = DateTime(
      date.year,
      date.month,
      date.day,
      schedule.endHour,
      schedule.endMinute,
    );
    
    while (currentTime.isBefore(endTime)) {
      final slotEnd = currentTime.add(Duration(minutes: _duration));
      
      if (slotEnd.isAfter(endTime)) {
        break; // Would extend past business hours
      }
      
      final slotInfo = TimeSlotInfo(
        startTime: currentTime,
        endTime: slotEnd,
      );
      
      // Validate slot
      _validateSlot(slotInfo, date);
      
      slots.add(slotInfo);
      currentTime = currentTime.add(const Duration(minutes: 30)); // 30-min intervals
    }
    
    _slotsCache[date] = slots;
    return slots;
  }

  void _validateSlot(TimeSlotInfo slot, DateTime date) {
    // Check minimum advance time
    final now = DateTime.now();
    final minBookingTime = now.add(Duration(hours: constraints.minAdvanceHours));
    
    if (slot.startTime.isBefore(minBookingTime)) {
      slot.isAvailable = false;
      slot.unavailableReason = 'Too soon (${constraints.minAdvanceHours}h min)';
      slot.displayColor = Colors.grey.shade200;
      return;
    }
    
    // Check conflicts with existing sessions
    for (final session in _existingSessions) {
      if (_hasTimeConflict(slot, session)) {
        slot.isAvailable = false;
        slot.unavailableReason = 'Booked';
        slot.displayColor = Colors.red.shade100;
        return;
      }
      
      // Check buffer time
      if (_isWithinBuffer(slot, session)) {
        slot.isAvailable = false;
        slot.unavailableReason = 'Buffer time';
        slot.displayColor = Colors.orange.shade100;
        return;
      }
    }
    
    // Check lunch break
    if (_isDuringLunchBreak(slot)) {
      slot.isAvailable = false;
      slot.unavailableReason = 'Lunch break';
      slot.displayColor = Colors.grey.shade200;
      return;
    }
    
    slot.isAvailable = true;
    slot.displayColor = Colors.green.shade100;
  }

  bool _hasTimeConflict(TimeSlotInfo slot, SessionModel session) {
    final sessionEnd = session.scheduledDate.add(Duration(minutes: session.durationMinutes));
    return (slot.startTime.isBefore(sessionEnd) && slot.endTime.isAfter(session.scheduledDate));
  }

  bool _isWithinBuffer(TimeSlotInfo slot, SessionModel session) {
    final bufferBefore = session.scheduledDate.subtract(Duration(minutes: constraints.bufferMinutes));
    final sessionEnd = session.scheduledDate.add(Duration(minutes: session.durationMinutes));
    final bufferAfter = sessionEnd.add(Duration(minutes: constraints.bufferMinutes));
    
    return (slot.startTime.isBefore(bufferAfter) && slot.endTime.isAfter(bufferBefore));
  }

  bool _isDuringLunchBreak(TimeSlotInfo slot) {
    final lunchStart = DateTime(slot.startTime.year, slot.startTime.month, slot.startTime.day, 12, 0);
    final lunchEnd = DateTime(slot.startTime.year, slot.startTime.month, slot.startTime.day, 13, 0);
    
    return (slot.startTime.isBefore(lunchEnd) && slot.endTime.isAfter(lunchStart));
  }

  List<DateTime> _calculateRecurringDates() {
    if (!_isRecurring || _selectedDay == null) return [_selectedDay!];
    
    final dates = <DateTime>[];
    final interval = _recurrencePattern == RecurrencePattern.weekly ? 7 : 14;
    
    for (int i = 0; i < _recurrenceCount; i++) {
      dates.add(_selectedDay!.add(Duration(days: i * interval)));
    }
    
    return dates;
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedDay != null && _selectedSlot != null;
      case 1:
        if (_sessionType == SessionType.inPerson && _selectedLocation == null) {
          return false;
        }
        if (_isRecurring && _recurrenceCount > widget.package.remainingSessions) {
          return false;
        }
        return true;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _handleNext() async {
    if (_currentStep < 2) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep++);
    } else {
      await _confirmBooking();
    }
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);
    
    try {
      // Validate package one more time
      final packageValidation = await _validatePackage();
      if (!packageValidation.isValid) {
        throw BookingException(packageValidation.reason);
      }
      
      // Create booking(s) with transaction
      final dates = _calculateRecurringDates();
      await _bookSessionsTransaction(dates);
      
      // Show success
      await _showSuccessDialog();
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<PackageValidation> _validatePackage() async {
    final totalSessions = _isRecurring ? _recurrenceCount : 1;
    
    // Check remaining sessions
    if (widget.package.remainingSessions < totalSessions) {
      return PackageValidation(
        isValid: false,
        reason: 'Not enough sessions in package',
        suggestRenewal: true,
      );
    }
    
    // Check expiration
    final lastDate = _isRecurring
        ? _calculateRecurringDates().last
        : _selectedDay!;
    
    if (widget.package.expiryDate.isBefore(lastDate)) {
      return PackageValidation(
        isValid: false,
        reason: 'Package expires before final session',
        suggestRenewal: true,
      );
    }
    
    return PackageValidation(isValid: true, reason: '');
  }

  Future<void> _bookSessionsTransaction(List<DateTime> dates) async {
    // Use DatabaseService with transaction-safe booking
    for (final date in dates) {
      final sessionDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        _selectedSlot!.startTime.hour,
        _selectedSlot!.startTime.minute,
      );

      // Book each session using the RPC function
      final result = await DatabaseService.instance.bookSession(
        clientId: widget.client.id,
        trainerId: widget.trainerId ?? 'demo-trainer',
        scheduledDate: sessionDateTime,
        durationMinutes: _duration,
        packageId: widget.package.id, // CORRECT: Use client_packages.id (the instance ID)
        sessionType: _sessionType.toSnakeCase(),
        location: _selectedLocation,
        notes: _notesController.text,
      );

      if (!result['success']) {
        // Handle booking failure
        throw BookingException(
          result['message'] ?? 'Failed to book session: ${result['error']}'
        );
      }

      debugPrint('✓ Session booked: ${result['session_id']}');

      // Small delay between bookings for recurring sessions
      if (dates.length > 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isRecurring
                  ? '$_recurrenceCount sessions booked successfully'
                  : 'Your session has been booked',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: _loadExistingSessions,
        ),
      ),
    );
  }
}

// Business Logic Classes
class BookingConstraints {
  final int minAdvanceHours = 2;
  final int maxAdvanceDays = 30;
  final int bufferMinutes = 15;
  
  void validateDate(DateTime date) {
    final now = DateTime.now();
    final minTime = now.add(Duration(hours: minAdvanceHours));
    final maxTime = now.add(Duration(days: maxAdvanceDays));
    
    if (date.isBefore(minTime)) {
      throw BookingException('Please book at least $minAdvanceHours hours in advance');
    }
    
    if (date.isAfter(maxTime)) {
      throw BookingException('Cannot book more than $maxAdvanceDays days ahead');
    }
  }
  
  BusinessHours getBusinessHours(DateTime date) {
    // Customize based on day of week
    final dayOfWeek = date.weekday;
    
    if (dayOfWeek == DateTime.sunday) {
      return BusinessHours(isWorkingDay: false);
    }
    
    if (dayOfWeek == DateTime.saturday) {
      return BusinessHours(
        isWorkingDay: true,
        startHour: 8,
        startMinute: 0,
        endHour: 14,
        endMinute: 0,
      );
    }
    
    return BusinessHours(
      isWorkingDay: true,
      startHour: 6,
      startMinute: 0,
      endHour: 21,
      endMinute: 0,
    );
  }
}

class BusinessHours {
  final bool isWorkingDay;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  BusinessHours({
    this.isWorkingDay = true,
    this.startHour = 6,
    this.startMinute = 0,
    this.endHour = 21,
    this.endMinute = 0,
  });
}

class TimeSlotInfo {
  final DateTime startTime;
  final DateTime endTime;
  bool isAvailable;
  String? unavailableReason;
  Color displayColor;

  TimeSlotInfo({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.unavailableReason,
    this.displayColor = Colors.green,
  });
}

enum SessionType { inPerson, online }

extension SessionTypeExtension on SessionType {
  String toSnakeCase() {
    switch (this) {
      case SessionType.inPerson:
        return 'in_person';
      case SessionType.online:
        return 'online';
    }
  }
}

enum RecurrencePattern { weekly, biweekly }

class PackageValidation {
  final bool isValid;
  final String reason;
  final bool suggestRenewal;

  PackageValidation({
    required this.isValid,
    this.reason = '',
    this.suggestRenewal = false,
  });
}

class BookingException implements Exception {
  final String message;
  BookingException(this.message);
  
  @override
  String toString() => message;
}

