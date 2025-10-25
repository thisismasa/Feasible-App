import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final bool enableHover;
  final bool enable3D;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.enableHover = true,
    this.enable3D = false,
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _tapController;
  late AnimationController _glowController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _tapAnimation;
  late Animation<double> _glowAnimation;

  bool _isHovering = false;
  Offset _mousePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _hoverAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
    
    _tapAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _tapController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleHover(bool hovering) {
    if (!widget.enableHover) return;
    
    setState(() {
      _isHovering = hovering;
    });
    
    if (hovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  void _handleMouseMove(PointerEvent event) {
    if (!widget.enable3D) return;
    
    setState(() {
      _mousePosition = event.localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      onHover: widget.enable3D ? _handleMouseMove : null,
      child: GestureDetector(
        onTapDown: (_) {
          _tapController.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          _tapController.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () {
          _tapController.reverse();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hoverAnimation,
            _tapAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            final elevationValue = 4 + (_hoverAnimation.value * 8);
            final scaleValue = _tapAnimation.value;
            
            Widget cardContent = Container(
              margin: widget.margin,
              decoration: BoxDecoration(
                color: widget.color ?? Colors.white,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                boxShadow: widget.boxShadow ?? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: elevationValue,
                    offset: Offset(0, elevationValue / 2),
                    spreadRadius: _hoverAnimation.value * 2,
                  ),
                  if (_isHovering)
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1 * _glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Padding(
                      padding: widget.padding ?? const EdgeInsets.all(16),
                      child: widget.child,
                    ),
                    
                    // Shimmer effect on hover
                    if (_isHovering)
                      Positioned.fill(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _hoverAnimation.value * 0.1,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                                transform: GradientRotation(
                                  _glowAnimation.value * 2 * math.pi,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
            
            // Apply 3D transform if enabled
            if (widget.enable3D && _isHovering) {
              final size = MediaQuery.of(context).size;
              final centerX = size.width / 2;
              final centerY = size.height / 2;
              final percentX = (_mousePosition.dx - centerX) / centerX;
              final percentY = (_mousePosition.dy - centerY) / centerY;
              
              cardContent = Transform(
                alignment: FractionalOffset.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(percentX * 0.3)
                  ..rotateX(-percentY * 0.3),
                child: cardContent,
              );
            }
            
            return Transform.scale(
              scale: scaleValue,
              child: cardContent,
            );
          },
        ),
      ),
    );
  }
}

// Flip Card Animation
class AnimatedFlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;

  const AnimatedFlipCard({
    Key? key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<AnimatedFlipCard> createState() => _AnimatedFlipCardState();
}

class _AnimatedFlipCardState extends State<AnimatedFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    HapticFeedback.mediumImpact();
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isShowingFront = _animation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(math.pi * _animation.value),
            child: isShowingFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

// Expandable Card
class AnimatedExpandableCard extends StatefulWidget {
  final Widget header;
  final Widget content;
  final bool initiallyExpanded;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const AnimatedExpandableCard({
    Key? key,
    required this.header,
    required this.content,
    this.initiallyExpanded = false,
    this.backgroundColor,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<AnimatedExpandableCard> createState() => _AnimatedExpandableCardState();
}

class _AnimatedExpandableCardState extends State<AnimatedExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      color: widget.backgroundColor,
      borderRadius: widget.borderRadius,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: _handleTap,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: widget.header),
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(
                      Icons.expand_more,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.content,
            ),
          ),
        ],
      ),
    );
  }
}

