import 'dart:math';

import 'package:flutter/material.dart';

class SimpleRoulette extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final Function(dynamic)? onSpinCompleted;

  const SimpleRoulette({
    Key? key,
    required this.options,
    this.onSpinCompleted,
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

    // 显示选择结果
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已选择：${result['name']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: _isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : const Icon(Icons.autorenew),
      label: Text(_isLoading ? '正在随机选择...' : '开始随机选题'),
      onPressed: _isLoading ? null : _startRandomSelection,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}