import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;
  final Duration? duration;
  final VoidCallback? onFinished;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.speed = const Duration(milliseconds: 30),
    this.duration,
    this.onFinished,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    if (widget.text.isEmpty) {
      _displayedText = '';
      _currentIndex = 0;
      _isFinished = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onFinished?.call();
        }
      });
    } else {
      _startTyping();
    }
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _reset();
      if (widget.text.isEmpty) {
        _isFinished = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onFinished?.call();
          }
        });
      } else {
        _startTyping();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    _displayedText = '';
    _currentIndex = 0;
    _isFinished = false;
  }

  void _startTyping() {
    if (widget.text.isEmpty) {
      _isFinished = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onFinished?.call();
        }
      });
      return;
    }
    
    final Duration charSpeed;
    if (widget.duration != null && widget.text.isNotEmpty) {
      final int calculatedMs = widget.duration!.inMilliseconds ~/ widget.text.length;
      charSpeed = Duration(milliseconds: calculatedMs.clamp(15, 120));
    } else {
      charSpeed = widget.speed;
    }
    
    _timer = Timer.periodic(charSpeed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        _finish();
      }
    });
  }

  void _finish() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _displayedText = widget.text;
        _currentIndex = widget.text.length;
        _isFinished = true;
      });
    } else {
      _displayedText = widget.text;
      _currentIndex = widget.text.length;
      _isFinished = true;
    }
    widget.onFinished?.call();
  }

  // Allow user to tap to complete text immediately
  void skip() {
    if (!_isFinished) {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: skip,
      behavior: HitTestBehavior.opaque,
      child: Text(
        _displayedText,
        style: widget.style,
      ),
    );
  }
}
