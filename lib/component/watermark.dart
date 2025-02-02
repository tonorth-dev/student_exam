import 'package:flutter/material.dart';
import '../common/app_data.dart';

class WatermarkWidget extends StatefulWidget {
  const WatermarkWidget({Key? key}) : super(key: key);

  @override
  _WatermarkWidgetState createState() => _WatermarkWidgetState();
}

class _WatermarkWidgetState extends State<WatermarkWidget> {
  LoginData? loginData;

  @override
  void initState() {
    super.initState();
    _initLoginData();
  }

  Future<void> _initLoginData() async {
    var data = await LoginData.read();
    setState(() {
      loginData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loginData == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: WatermarkPainter(loginData!),
      size: Size.infinite,
    );
  }
}

class WatermarkPainter extends CustomPainter {
  final LoginData loginData;

  WatermarkPainter(this.loginData);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    TextSpan span = TextSpan(
      text: '红师教育（${loginData.code}）',
      style: TextStyle(
        fontSize: 20.0,
        color: paint.color,
        fontFamily: 'OPPOSans',
      ),
    );

    TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();

    double stepX = size.width / 5;
    double stepY = size.height / 4;

    for (double y = 0; y < size.height; y += stepY) {
      for (double x = 0; x < size.width; x += stepX) {
        canvas.save();
        canvas.translate(x + stepX / 2, y + stepY / 2);
        canvas.rotate(-0.5);
        canvas.translate(-tp.width / 2, -tp.height / 2);
        tp.paint(canvas, const Offset(0, 0));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(WatermarkPainter oldDelegate) {
    return oldDelegate.loginData.code != loginData.code;
  }
}