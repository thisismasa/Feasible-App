import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../services/database_service.dart';

enum SessionMode { scheduled, adhoc }

enum WorkoutType {
  strength,
  hyrox,
  running,
  hiit,
  custom,
}

class LiveSessionScreen extends StatefulWidget {
  final UserModel client;
  final SessionModel? session;
  final SessionMode mode;
  final WorkoutType workoutType;

  const LiveSessionScreen({
    Key? key,
    required this.client,
    this.session,
    this.mode = SessionMode.adhoc,
    this.workoutType = WorkoutType.strength,
  }) : super(key: key);

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen>
    with TickerProviderStateMixin {
  // Session state
  bool _isSessionStarted = false;
  DateTime? _sessionStartTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _sessionTimer;

  // Exercise logging
  final List<ExerciseLog> _exerciseLogs = [];
  final _notesController = TextEditingController();

  // Rest timer
  bool _isResting = false;
  int _restTimeRemaining = 0;
  Timer? _restTimer;

  // Animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    if (widget.mode == SessionMode.scheduled) {
      _showStartConfirmation();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _pulseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showStartConfirmation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Start Session?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Client: ${widget.client.name}'),
              const SizedBox(height: 8),
              if (widget.session != null) ...[
                Text(
                  'Scheduled: ${DateFormat('h:mm a').format(widget.session!.scheduledDate)}',
                ),
                Text(
                  'Duration: ${widget.session!.durationMinutes} minutes',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startSession();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Start Session'),
            ),
          ],
        ),
      );
    });
  }

  void _startSession() {
    setState(() {
      _isSessionStarted = true;
      _sessionStartTime = DateTime.now();
    });

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_sessionStartTime!);
      });
    });

    // Update session status in database
    if (widget.session != null) {
      DatabaseService.instance.updateSessionStatus(
        sessionId: widget.session!.id,
        status: 'in_progress',
        actualStartTime: _sessionStartTime,
      ).then((_) => debugPrint('✓ Session started in database'));
    }
  }

  void _endSession() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${_formatDuration(_elapsedTime)}'),
            Text('Exercises logged: ${_exerciseLogs.length}'),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to end this session?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (shouldEnd == true) {
      await _saveSessionData();
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _saveSessionData() async {
    try {
      final endTime = DateTime.now();
      final actualDuration = endTime.difference(_sessionStartTime!).inMinutes;

      if (widget.session != null) {
        // Update existing session
        await DatabaseService.instance.updateSessionStatus(
          sessionId: widget.session!.id,
          status: 'completed',
          actualEndTime: endTime,
          actualDurationMinutes: actualDuration,
          notes: _notesController.text,
        );
        debugPrint('✓ Session updated: ${widget.session!.id}');
      } else {
        // Create new adhoc session using booking
        final result = await DatabaseService.instance.bookSession(
          clientId: widget.client.id,
          trainerId: 'demo-trainer',
          scheduledDate: _sessionStartTime!,
          durationMinutes: actualDuration,
          packageId: 'adhoc-session',
          sessionType: 'adhoc',
        );

        if (result['success']) {
          final sessionId = result['session_id'];
          // Update to completed
          await DatabaseService.instance.updateSessionStatus(
            sessionId: sessionId,
            status: 'completed',
            actualStartTime: _sessionStartTime,
            actualEndTime: endTime,
            actualDurationMinutes: actualDuration,
            notes: _notesController.text,
          );
          debugPrint('✓ Adhoc session created: $sessionId');
        }
      }

      // Save exercise logs
      for (final log in _exerciseLogs) {
        await DatabaseService.instance.logExercise(
          sessionId: widget.session?.id ?? 'temp-session',
          clientId: widget.client.id,
          exerciseName: log.exerciseName,
          sets: log.sets,
          reps: log.reps,
          weight: log.weight,
          notes: log.notes,
        );
      }

      debugPrint('✓ ${_exerciseLogs.length} exercises logged');
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSessionStarted) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Session in Progress'),
              content: const Text(
                'Exiting will end the session. Are you sure?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          return shouldExit ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF16213E),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.client.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.workoutType.name.toUpperCase(),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        if (_isSessionStarted)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _pulseController,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_elapsedTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (!_isSessionStarted) {
      return _buildPreSessionView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionStats(),
          const SizedBox(height: 24),
          _buildRestTimer(),
          const SizedBox(height: 24),
          _buildExerciseLog(),
          const SizedBox(height: 24),
          _buildSessionNotes(),
        ],
      ),
    );
  }

  Widget _buildPreSessionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 120,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 32),
            const Text(
              'Ready to Start?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap the start button below to begin the session',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _startSession,
              icon: const Icon(Icons.play_arrow, size: 32),
              label: const Text(
                'START SESSION',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.purple.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Duration',
            _formatDuration(_elapsedTime),
            Icons.timer,
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStatItem(
            'Exercises',
            '${_exerciseLogs.length}',
            Icons.fitness_center,
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStatItem(
            'Sets',
            '${_exerciseLogs.fold<int>(0, (sum, log) => sum + log.sets)}',
            Icons.repeat,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildRestTimer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rest Timer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_isResting)
                Text(
                  '$_restTimeRemaining seconds',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildRestButton('30s', 30),
              const SizedBox(width: 8),
              _buildRestButton('60s', 60),
              const SizedBox(width: 8),
              _buildRestButton('90s', 90),
              const SizedBox(width: 8),
              _buildRestButton('120s', 120),
            ],
          ),
          if (_isResting) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _stopRestTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Stop Timer'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestButton(String label, int seconds) {
    return Expanded(
      child: ElevatedButton(
        onPressed: _isResting ? null : () => _startRestTimer(seconds),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }

  void _startRestTimer(int seconds) {
    setState(() {
      _isResting = true;
      _restTimeRemaining = seconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restTimeRemaining--;
      });

      if (_restTimeRemaining <= 0) {
        _stopRestTimer();
        HapticFeedback.heavyImpact();
        // Play sound or notification
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restTimeRemaining = 0;
    });
  }

  Widget _buildExerciseLog() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exercise Log',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_exerciseLogs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No exercises logged yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            )
          else
            ..._exerciseLogs.reversed
                .map((log) => _buildExerciseCard(log))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.exerciseName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${log.sets} sets × ${log.reps} reps @ ${log.weight} kg',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              log.notes,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addExercise() async {
    final result = await showDialog<ExerciseLog>(
      context: context,
      builder: (context) => const AddExerciseDialog(),
    );

    if (result != null) {
      setState(() {
        _exerciseLogs.add(result);
      });
      HapticFeedback.mediumImpact();
    }
  }

  Widget _buildSessionNotes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add notes about the session...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (!_isSessionStarted) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _endSession,
          icon: const Icon(Icons.stop, size: 28),
          label: const Text(
            'END SESSION',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class ExerciseLog {
  final String exerciseName;
  final int sets;
  final int reps;
  final double weight;
  final String notes;
  final DateTime timestamp;

  ExerciseLog({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
    this.notes = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AddExerciseDialog extends StatefulWidget {
  const AddExerciseDialog({Key? key}) : super(key: key);

  @override
  State<AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Exercise'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _exerciseController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter exercise name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      decoration: const InputDecoration(
                        labelText: 'Sets',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final log = ExerciseLog(
                exerciseName: _exerciseController.text,
                sets: int.tryParse(_setsController.text) ?? 3,
                reps: int.tryParse(_repsController.text) ?? 10,
                weight: double.tryParse(_weightController.text) ?? 0,
                notes: _notesController.text,
              );
              Navigator.pop(context, log);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
