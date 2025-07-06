// ignore_for_file: unused_local_variable, prefer_const_declarations

import 'dart:math';
import 'package:flutter/material.dart';

class FlipCardController {
  _FlipCardWidgetState? _state;

  Future flipCard() async => _state?.flipCard();
}

class FlipCardWidget extends StatefulWidget {
  final Image front;
  final Image back;
  final FlipCardController controller;
  final VoidCallback? onFlipCompletion;

  const FlipCardWidget(
      {super.key,
      required this.front,
      required this.controller,
      required this.back,
      this.onFlipCompletion});

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> flipAnimation;

  bool isFront = true;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    flipAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutSine,
    );

    widget.controller._state = this;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFlipCompletion?.call();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future flipCard() async {
  if (controller.isAnimating) return;

  await controller.forward();
  await Future.delayed(const Duration(milliseconds: 200));
  await controller.reverse();
  setState(() {
    isFront = false;
  });
}

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final angle = flipAnimation.value * -pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isFrontImage(angle.abs())
                ? widget.back
                : Transform(
                    transform: Matrix4.identity()..rotateX(pi),
                    alignment: Alignment.center,
                    child: widget.front,
                  ),
          );
        },
      );

  bool isFrontImage(double angle) {
    final degrees90 = pi / 2;
    final degrees270 = 3 * pi / 2;

    return angle <= degrees90 || angle >= degrees270;
  }
}
