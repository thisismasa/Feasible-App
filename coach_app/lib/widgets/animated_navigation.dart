import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedNavigationRail extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavDestination> destinations;
  final bool isExpanded;
  final Function() onToggleExpanded;

  const AnimatedNavigationRail({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.isExpanded,
    required this.onToggleExpanded,
  }) : super(key: key);

  @override
  State<AnimatedNavigationRail> createState() => _AnimatedNavigationRailState();
}

class _AnimatedNavigationRailState extends State<AnimatedNavigationRail>
    with TickerProviderStateMixin {
  late AnimationController _expansionController;
  late AnimationController _selectionController;
  late Animation<double> _expansionAnimation;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;
  
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    );
    
    _itemControllers = List.generate(
      widget.destinations.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );
    
    _itemAnimations = _itemControllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      );
    }).toList();
    
    if (widget.isExpanded) {
      _expansionController.forward();
    }
    
    _animateItems();
  }

  void _animateItems() async {
    for (int i = 0; i < _itemControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        _itemControllers[i].forward();
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _expansionController.forward();
      } else {
        _expansionController.reverse();
      }
    }
    
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _selectionController.forward().then((_) {
        _selectionController.reset();
      });
    }
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _selectionController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expansionAnimation,
      builder: (context, child) {
        return Container(
          width: widget.isExpanded ? 280 : 80,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Navigation Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.destinations.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _itemAnimations[index],
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _itemAnimations[index].value,
                          child: _buildNavItem(
                            destination: widget.destinations[index],
                            index: index,
                            isSelected: widget.selectedIndex == index,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Footer
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: widget.isExpanded ? 60 : 40,
                height: widget.isExpanded ? 60 : 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.blue.shade600,
                  size: widget.isExpanded ? 30 : 20,
                ),
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: FadeTransition(
                    opacity: _expansionAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PT Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Version 2.0',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required NavDestination destination,
    required int index,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onDestinationSelected(index);
          },
          borderRadius: BorderRadius.circular(widget.isExpanded ? 30 : 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isExpanded ? 20 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(widget.isExpanded ? 30 : 20),
              border: isSelected
                  ? Border.all(color: Colors.blue.withOpacity(0.3), width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // Animated Icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: isSelected ? 1 : 0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 1 + (value * 0.2),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          destination.icon,
                          color: isSelected ? Colors.blue : Colors.grey.shade600,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
                
                if (widget.isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: FadeTransition(
                      opacity: _expansionAnimation,
                      child: Text(
                        destination.label,
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  if (destination.badge != null)
                    FadeTransition(
                      opacity: _expansionAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          destination.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onToggleExpanded,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedRotation(
                  turns: widget.isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (widget.isExpanded)
                  FadeTransition(
                    opacity: _expansionAnimation,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'Collapse',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
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
}

class NavDestination {
  final IconData icon;
  final String label;
  final String? badge;

  const NavDestination({
    required this.icon,
    required this.label,
    this.badge,
  });
}

// Animated Tab Bar
class AnimatedTabBar extends StatefulWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int) onTabSelected;

  const AnimatedTabBar({
    Key? key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  State<AnimatedTabBar> createState() => _AnimatedTabBarState();
}

class _AnimatedTabBarState extends State<AnimatedTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _indicatorAnimation = CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.elasticOut,
    );
    _indicatorController.forward();
  }

  @override
  void didUpdateWidget(AnimatedTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _indicatorController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / widget.tabs.length;
          
          return Stack(
            children: [
              // Animated Indicator
              AnimatedBuilder(
                animation: _indicatorAnimation,
                builder: (context, child) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: widget.selectedIndex * tabWidth,
                    bottom: 0,
                    child: Transform.scale(
                      scaleX: _indicatorAnimation.value,
                      child: Container(
                        width: tabWidth,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Tabs
              Row(
                children: widget.tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  final isSelected = index == widget.selectedIndex;
                  
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onTabSelected(index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color: Colors.transparent,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: isSelected ? Colors.blue : Colors.grey,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontSize: isSelected ? 16 : 14,
                            ),
                            child: Text(tab),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

