import 'dart:math';
import 'package:flutter/material.dart';
import 'package:roulette/roulette.dart';

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
  late final RouletteController _controller;
  late final RouletteGroup _group;
  bool _clockwise = true;

  @override
  void initState() {
    super.initState();
    _controller = RouletteController();
    _group = _createRouletteGroup();
  }

  RouletteGroup _createRouletteGroup() {
    return RouletteGroup.uniform(
      widget.options.length,
      // Use name for display
      textBuilder: (index) => widget.options[index]['name'],
      textStyleBuilder: (index) => const TextStyle(color: Colors.white),
      colorBuilder: (index) => Color.lerp(
          Colors.orange.shade300,
          Colors.orange.shade900,
          index / (widget.options.length - 1)
      ) ?? Colors.orange,
    );
  }

  void _spin() async {
    final index = _random.nextInt(widget.options.length);
    final completed = await _controller.rollTo(
      index,
      clockwise: _clockwise,
      offset: _random.nextDouble(),
    );

    if (completed) {
      // Use id when spin completes
      widget.onSpinCompleted?.call(widget.options[index]['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 260,
          height: 260,
          child: Roulette(
            group: _group,
            controller: _controller,
            style: const RouletteStyle(
              dividerThickness: 0.0,
              dividerColor: Colors.black,
              centerStickSizePercent: 0.05,
              centerStickerColor: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _spin,
          child: const Text('随机选题'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}