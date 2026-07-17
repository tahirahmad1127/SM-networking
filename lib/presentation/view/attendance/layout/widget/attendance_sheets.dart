import 'dart:math';

import 'package:flutter/material.dart';


/// SLIDE TO CHECK IN SHEET
class SlideToCheckInSheet extends StatefulWidget {
  final VoidCallback onComplete;

  const SlideToCheckInSheet({super.key, required this.onComplete});

  @override
  State<SlideToCheckInSheet> createState() => _SlideToCheckInSheetState();
}

class _SlideToCheckInSheetState extends State<SlideToCheckInSheet> {
  bool _isCompleted = false;
  double _progress = 0.0;

  Color _interpolateColor(double progress) {
    const start = Colors.green;
    const end = Colors.amber;
    return Color.lerp(start, end, progress.clamp(0.0, 1.0))!;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.3,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 30),

            Image.asset("assets/images/location.png", height: 70,),

            const SizedBox(height: 30),

            // Slide Button
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _progress = max(
                        0.0,
                        min(1.0,
                            details.localPosition.dx / constraints.maxWidth),
                      );
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_progress > 0.9) {
                      setState(() {
                        _progress = 1.0;
                        _isCompleted = true;
                      });
                      // No artificial delay here — that was 800ms of a
                      // static "Processing..." label with no actual
                      // spinner and no real work happening, which read as
                      // a stall. Hand off to onComplete() immediately; the
                      // caller's own loading indicator takes over right
                      // as this sheet closes.
                      widget.onComplete();
                    } else {
                      setState(() => _progress = 0.0);
                    }
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: _isCompleted
                          ? Colors.amber
                          : _interpolateColor(_progress),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 150),
                          left: _progress * (constraints.maxWidth - 56),
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            _isCompleted
                                ? "Processing..."
                                : "Swipe right to Punch In",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// SLIDE TO CHECK OUT SHEET
class SlideToCheckOutSheet extends StatefulWidget {
  final VoidCallback onComplete;

  const SlideToCheckOutSheet({super.key, required this.onComplete});

  @override
  State<SlideToCheckOutSheet> createState() => _SlideToCheckOutSheetState();
}

class _SlideToCheckOutSheetState extends State<SlideToCheckOutSheet> {
  bool _isCompleted = false;
  double _progress = 0.0;

  Color _interpolateColor(double progress) {
    const start = Colors.green;
    const end = Colors.amber;
    return Color.lerp(start, end, progress.clamp(0.0, 1.0))!;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.3,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 30),

            Image.asset("assets/images/location.png", height: 70,),

            const SizedBox(height: 30),

            // Slide Button
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _progress = max(
                        0.0,
                        min(1.0,
                            details.localPosition.dx / constraints.maxWidth),
                      );
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_progress > 0.9) {
                      setState(() {
                        _progress = 1.0;
                        _isCompleted = true;
                      });
                      // No artificial delay here — that was 800ms of a
                      // static "Processing..." label with no actual
                      // spinner and no real work happening, which read as
                      // a stall. Hand off to onComplete() immediately; the
                      // caller's own loading indicator takes over right
                      // as this sheet closes.
                      widget.onComplete();
                    } else {
                      setState(() => _progress = 0.0);
                    }
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: _isCompleted
                          ? Colors.amber
                          : _interpolateColor(_progress),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 150),
                          left: _progress * (constraints.maxWidth - 56),
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            _isCompleted
                                ? "Processing..."
                                : "Swipe right to Punch Out",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
