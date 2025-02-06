import 'dart:math';

import 'package:flutter/material.dart';

import '../app/home/pages/exam/countdown_logic.dart';

class SimpleRoulette extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final Function(dynamic)? onSpinCompleted;
  final Countdown countdown;

  const SimpleRoulette({
    Key? key,
    required this.options,
    this.onSpinCompleted,
    required this.countdown,
  }) : super(key: key);

  @override
  _SimpleRouletteState createState() => _SimpleRouletteState();
}

class _SimpleRouletteState extends State<SimpleRoulette> {
  final _random = Random();
  bool _isLoading = false;

  Future<void> _startRandomSelection() async {
    setState(() => _isLoading = true);

    // 模拟随机选择过程
    await Future.delayed(const Duration(seconds: 2));

    final result = widget.options[_random.nextInt(widget.options.length)];

    setState(() => _isLoading = false);

    widget.onSpinCompleted?.call(result['id']);

  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.autorenew,
              size: 28,
            ),
      label: Text(
        _isLoading ? '正在随机选择...' : '开始随机选题',
        style: const TextStyle(fontSize: 18),
      ),
      onPressed: _isLoading
          ? null
          : () {
              _startRandomSelection();
              widget.countdown.stop();
              widget.countdown.reset();
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        minimumSize: const Size(200, 56),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}