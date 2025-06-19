// lib/animated_background.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Alignment>> _animations;

  // Using theme-aware colors
  List<Color> lightColors = [
    Colors.purple.shade200,
    Colors.blue.shade200,
    Colors.amber.shade200,
  ];

  List<Color> darkColors = [
    Colors.purple.shade900,
    Colors.blue.shade900,
    Colors.deepOrange.shade900,
  ];

  List<Alignment> alignments = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];
  
  int alignmentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(seconds: 4 + index * 2),
      )..repeat(reverse: true),
    );

    _animations = List.generate(
      3,
      (index) => Tween<Alignment>(
        begin: Alignment.center,
        end: _getRandomAlignment(),
      ).animate(
        CurvedAnimation(
          parent: _controllers[index],
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  Alignment _getRandomAlignment() {
    alignmentIndex = (alignmentIndex + 1) % alignments.length;
    return alignments[alignmentIndex];
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? darkColors : lightColors;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors[0].withOpacity(0.6), colors[1].withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        ...List.generate(
          3,
          (index) => AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              return Align(
                alignment: _animations[index].value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[index].withOpacity(0.4),
                  ),
                ),
              );
            },
          ),
        ),
        // Add the backdrop filter for the blur effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}