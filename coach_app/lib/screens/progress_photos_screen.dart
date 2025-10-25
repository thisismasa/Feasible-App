import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';

/// Progress Photos Timeline Screen - Visual Journey Tracking
/// Features: Photo comparison, timeline view, before/after slider, AI body analysis
class ProgressPhotosScreen extends StatefulWidget {
  final UserModel client;

  const ProgressPhotosScreen({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _photoController;
  late AnimationController _comparisonController;
  
  String _selectedView = 'timeline'; // timeline, grid, comparison
  List<ProgressPhoto> _photos = [];
  ProgressPhoto? _beforePhoto;
  ProgressPhoto? _afterPhoto;
  double _comparisonSliderValue = 0.5;
  
  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _photoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    
    _comparisonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _loadProgressPhotos();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _photoController.dispose();
    _comparisonController.dispose();
    super.dispose();
  }

  void _loadProgressPhotos() {
    // Demo data - replace with real data from Supabase
    setState(() {
      _photos = List.generate(8, (index) {
        final date = DateTime.now().subtract(Duration(days: index * 14));
        return ProgressPhoto(
          id: 'photo_$index',
          clientId: widget.client.id,
          photoUrl: 'https://via.placeholder.com/600x800',
          timestamp: date,
          weight: 185.0 - (index * 2.5),
          bodyFatPercentage: 22.0 - (index * 0.5),
          notes: index == 0 ? 'Current Progress' : 'Week ${index * 2} check-in',
          measurements: {
            'chest': 42.0 - (index * 0.2),
            'waist': 36.0 - (index * 0.3),
            'hips': 40.0 - (index * 0.2),
            'arms': 15.5 - (index * 0.1),
          },
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAnimatedAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildViewSelector(),
                const SizedBox(height: 16),
                _buildStatsOverview(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _buildContentView(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildAnimatedAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.purple,
      flexibleSpace: FlexibleSpaceBar(
        title: FadeTransition(
          opacity: _headerController,
          child: const Text(
            'Progress Photos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade400, Colors.purple.shade800],
            ),
          ),
          child: SafeArea(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _headerController,
                curve: Curves.easeOutCubic,
              )),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Hero(
                    tag: 'client-progress-${widget.client.id}',
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.client.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.client.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_photos.length} Photos • ${_calculateDaysSinceStart()} Days Journey',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Expanded(
            child: _buildViewOption('timeline', Icons.timeline, 'Timeline'),
          ),
          Expanded(
            child: _buildViewOption('grid', Icons.grid_view, 'Grid'),
          ),
          Expanded(
            child: _buildViewOption('comparison', Icons.compare, 'Compare'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewOption(String value, IconData icon, String label) {
    final isSelected = _selectedView == value;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: () {
          setState(() => _selectedView = value);
          _photoController.reset();
          _photoController.forward();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    if (_photos.isEmpty) return const SizedBox();
    
    final latestPhoto = _photos.first;
    final oldestPhoto = _photos.last;
    
    final weightChange = latestPhoto.weight - oldestPhoto.weight;
    final bodyFatChange = latestPhoto.bodyFatPercentage - oldestPhoto.bodyFatPercentage;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          const Text(
            'Total Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressStat(
                  'Weight',
                  weightChange,
                  'lbs',
                  Icons.monitor_weight,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressStat(
                  'Body Fat',
                  bodyFatChange,
                  '%',
                  Icons.show_chart,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(
    String label,
    double change,
    String unit,
    IconData icon,
    Color color,
  ) {
    final isPositive = change < 0; // Negative is good for weight/body fat
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.trending_down : Icons.trending_up,
                color: isPositive ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${change.abs().toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    switch (_selectedView) {
      case 'grid':
        return _buildGridView();
      case 'comparison':
        return _buildComparisonView();
      default:
        return _buildTimelineView();
    }
  }

  Widget _buildTimelineView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final photo = _photos[index];
          
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(index.isEven ? -1.0 : 1.0, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _photoController,
              curve: Interval(
                (index * 0.1).clamp(0.0, 1.0),
                ((index + 1) * 0.1).clamp(0.0, 1.0),
                curve: Curves.easeOutCubic,
              ),
            )),
            child: _buildTimelinePhotoCard(photo, index),
          );
        },
        childCount: _photos.length,
      ),
    );
  }

  Widget _buildTimelinePhotoCard(ProgressPhoto photo, int index) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        index.isEven ? 16 : 80,
        8,
        index.isEven ? 80 : 16,
        8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (index.isOdd) const Spacer(),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _showPhotoDetail(photo),
              child: Hero(
                tag: 'photo-${photo.id}',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Image.network(
                            photo.photoUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(photo.timestamp),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildMeasurementChip(
                              '${photo.weight} lbs',
                              Icons.monitor_weight,
                              Colors.blue,
                            ),
                            const SizedBox(height: 4),
                            _buildMeasurementChip(
                              '${photo.bodyFatPercentage}% BF',
                              Icons.show_chart,
                              Colors.orange,
                            ),
                            if (photo.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                photo.notes,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (index.isEven) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 3 / 4,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final photo = _photos[index];
            
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _photoController,
                  curve: Interval(
                    (index * 0.05).clamp(0.0, 1.0),
                    ((index + 1) * 0.05).clamp(0.0, 1.0),
                    curve: Curves.easeOutBack,
                  ),
                ),
              ),
              child: _buildGridPhotoCard(photo),
            );
          },
          childCount: _photos.length,
        ),
      ),
    );
  }

  Widget _buildGridPhotoCard(ProgressPhoto photo) {
    return GestureDetector(
      onTap: () => _showPhotoDetail(photo),
      child: Hero(
        tag: 'photo-${photo.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photo.photoUrl,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('MMM dd').format(photo.timestamp),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${photo.weight} lbs',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonView() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Before/After Photo Selector
            Row(
              children: [
                Expanded(
                  child: _buildPhotoSelector(
                    'Before',
                    _beforePhoto,
                    (photo) => setState(() => _beforePhoto = photo),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPhotoSelector(
                    'After',
                    _afterPhoto,
                    (photo) => setState(() => _afterPhoto = photo),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Comparison View
            if (_beforePhoto != null && _afterPhoto != null)
              _buildComparisonSlider(),
            
            const SizedBox(height: 24),
            
            // Stats Comparison
            if (_beforePhoto != null && _afterPhoto != null)
              _buildStatsComparison(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSelector(
    String label,
    ProgressPhoto? selectedPhoto,
    Function(ProgressPhoto) onSelect,
  ) {
    return GestureDetector(
      onTap: () => _showPhotoPickerDialog(label, onSelect),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade200, width: 2),
        ),
        child: selectedPhoto == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Select $label Photo',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      selectedPhoto.photoUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildComparisonSlider() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // After Photo (Background)
            Image.network(
              _afterPhoto!.photoUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            
            // Before Photo (Clipped)
            ClipRect(
              clipper: _ComparisonClipper(_comparisonSliderValue),
              child: Image.network(
                _beforePhoto!.photoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            
            // Divider Line
            Positioned(
              left: _comparisonSliderValue * MediaQuery.of(context).size.width - 32,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: Colors.white,
              ),
            ),
            
            // Slider Handle
            Positioned(
              left: _comparisonSliderValue * MediaQuery.of(context).size.width - 48,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _comparisonSliderValue = (details.localPosition.dx + 
                          _comparisonSliderValue * MediaQuery.of(context).size.width - 48) /
                          MediaQuery.of(context).size.width;
                      _comparisonSliderValue = _comparisonSliderValue.clamp(0.0, 1.0);
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.compare_arrows,
                      color: Colors.purple,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            
            // Labels
            Positioned(
              top: 16,
              left: 16,
              child: _buildComparisonLabel('Before', Colors.blue),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _buildComparisonLabel('After', Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatsComparison() {
    final weightDiff = _afterPhoto!.weight - _beforePhoto!.weight;
    final bfDiff = _afterPhoto!.bodyFatPercentage - _beforePhoto!.bodyFatPercentage;
    final daysDiff = _afterPhoto!.timestamp.difference(_beforePhoto!.timestamp).inDays;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Transformation Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildComparisonStat(
                'Weight Change',
                '${weightDiff.toStringAsFixed(1)} lbs',
                weightDiff < 0 ? Icons.trending_down : Icons.trending_up,
                weightDiff < 0 ? Colors.green : Colors.red,
              ),
              _buildComparisonStat(
                'Body Fat Change',
                '${bfDiff.toStringAsFixed(1)}%',
                bfDiff < 0 ? Icons.trending_down : Icons.trending_up,
                bfDiff < 0 ? Colors.green : Colors.red,
              ),
              _buildComparisonStat(
                'Time Period',
                '$daysDiff days',
                Icons.calendar_today,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMeasurementChip(String text, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'add_photo',
          onPressed: () => _addNewPhoto(),
          backgroundColor: Colors.purple,
          child: const Icon(Icons.add_a_photo),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.small(
          heroTag: 'share',
          onPressed: () => _shareProgress(),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.share),
        ),
      ],
    );
  }

  void _showPhotoDetail(ProgressPhoto photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoDetailScreen(photo: photo),
      ),
    );
  }

  void _showPhotoPickerDialog(String label, Function(ProgressPhoto) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select $label Photo',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  final photo = _photos[index];
                  return GestureDetector(
                    onTap: () {
                      onSelect(photo);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              photo.photoUrl,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.black.withOpacity(0.7),
                                child: Text(
                                  DateFormat('MMM dd').format(photo.timestamp),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewPhoto() {
    // Implement photo upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo upload feature coming soon!')),
    );
  }

  void _shareProgress() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon!')),
    );
  }

  int _calculateDaysSinceStart() {
    if (_photos.isEmpty) return 0;
    return DateTime.now().difference(_photos.last.timestamp).inDays;
  }
}

// Photo Detail Screen
class _PhotoDetailScreen extends StatelessWidget {
  final ProgressPhoto photo;

  const _PhotoDetailScreen({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: 'photo-${photo.id}',
          child: InteractiveViewer(
            child: Image.network(photo.photoUrl),
          ),
        ),
      ),
    );
  }
}

// Custom Clipper for Comparison
class _ComparisonClipper extends CustomClipper<Rect> {
  final double value;

  _ComparisonClipper(this.value);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * value, size.height);
  }

  @override
  bool shouldReclip(_ComparisonClipper oldClipper) {
    return oldClipper.value != value;
  }
}

// Models
class ProgressPhoto {
  final String id;
  final String clientId;
  final String photoUrl;
  final DateTime timestamp;
  final double weight;
  final double bodyFatPercentage;
  final String notes;
  final Map<String, double> measurements;

  ProgressPhoto({
    required this.id,
    required this.clientId,
    required this.photoUrl,
    required this.timestamp,
    required this.weight,
    required this.bodyFatPercentage,
    this.notes = '',
    this.measurements = const {},
  });
}

