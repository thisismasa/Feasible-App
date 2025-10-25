import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../screens/live_session_screen.dart';
import '../screens/client_selection_screen.dart';

class SessionModeSelectorScreen extends StatelessWidget {
  const SessionModeSelectorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Select Workout Type'),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the type of session',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the workout mode that fits your client\'s goals',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _SessionModeCard(
                    title: 'Strength Training',
                    description: 'Weight lifting & resistance',
                    icon: Icons.fitness_center,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade900],
                    ),
                    onTap: () => _startSession(context, WorkoutType.strength),
                  ),
                  _SessionModeCard(
                    title: 'HYROX Simulation',
                    description: 'Race prep & endurance',
                    icon: Icons.timer,
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade700, Colors.red.shade700],
                    ),
                    onTap: () => _startSession(context, WorkoutType.hyrox),
                  ),
                  _SessionModeCard(
                    title: 'Running',
                    description: 'Cardio & conditioning',
                    icon: Icons.directions_run,
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.teal.shade700],
                    ),
                    onTap: () => _startSession(context, WorkoutType.running),
                  ),
                  _SessionModeCard(
                    title: 'HIIT / EMOM',
                    description: 'High intensity intervals',
                    icon: Icons.speed,
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade700, Colors.pink.shade700],
                    ),
                    onTap: () => _startSession(context, WorkoutType.hiit),
                  ),
                  _SessionModeCard(
                    title: 'Custom Session',
                    description: 'Flexible workout format',
                    icon: Icons.edit,
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade700, Colors.blue.shade700],
                    ),
                    onTap: () => _startSession(context, WorkoutType.custom),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSession(BuildContext context, WorkoutType workoutType) async {
    HapticFeedback.mediumImpact();

    // First select client
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientSelectionScreen(
          mode: SelectionMode.adhoc,
          onlyActiveClients: false,
        ),
      ),
    );

    if (result != null && result is Map) {
      final client = result['client'] as UserModel;

      if (context.mounted) {
        // Navigate to live session
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveSessionScreen(
              client: client,
              mode: SessionMode.adhoc,
              workoutType: workoutType,
            ),
          ),
        );

        // Return to dashboard after session
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    }
  }
}

class _SessionModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _SessionModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
