import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:math';

typedef SelectColor = Color Function(Color color);

class ColorRingPickView extends StatefulWidget {
  Size size;
  double selectRadius;
  double padding;
  final double ringWidth = 20;
  Color selectColor;
  final SelectColor selectColorCallBack;

  ColorRingPickView({
    this.size,
    this.selectColorCallBack,
    this.selectRadius,
    this.padding,
    this.selectColor,
  }) {
    assert(size == null || (size != null && size.height == size.width),
        '控件宽高必须相等');
  }

  @override
  State<StatefulWidget> createState() {
    return ColorPickState();
  }
}

class ColorPickState extends State<ColorRingPickView> {
  double radius;
  Color currentColor = Color(0xff00ff);
  Offset currentOffset;
  Offset topLeftPosition;
  Offset selectPosition;
  Size screenSize;
  GlobalKey globalKey = new GlobalKey();
  bool isTap = false;

  @override
  Widget build(BuildContext context) {
    screenSize ??= MediaQuery.of(context).size;
    widget.size ??= screenSize;
    widget.selectRadius ??= 20;
    widget.padding ??= 40;
    print("screenSize=$screenSize");
    print(widget.size);
    assert(
        widget.size == null ||
            (widget.size != null && screenSize.width >= widget.size.width),
        '控件宽度太宽');
    radius = widget.size.width / 2 - widget.padding;
    currentOffset ??= Offset(radius, radius);
    if (widget.selectColor != null && selectPosition == null)
      _setColor(widget.selectColor);
    _initLeftTop();
    return GestureDetector(
      key: globalKey,
      child: Container(
        width: widget.size.width,
        height: widget.size.width,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              painter: ColorPick(radius: radius, ringWidth: widget.ringWidth),
              size: widget.size,
            ),
            Positioned(
              left: isTap ? currentOffset.dx : selectPosition.dx,
              top: isTap ? currentOffset.dy : selectPosition.dy,
              //这里减去80，是因为上下边距各40 所以需要减去还有半径
              child: Container(
                width: widget.selectRadius,
                height: widget.selectRadius,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.selectRadius),
                    border: Border.fromBorderSide(BorderSide())),
                child: ClipOval(
                  child: Container(
                    color: currentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      onTapDown: (e) {
        setState(() {
          isTap = true;
          _initLeftTop();
          currentColor =
              getColorAtPoint(e.globalPosition.dx, e.globalPosition.dy);
          if (widget.selectColorCallBack != null) {
            widget.selectColorCallBack(currentColor);
          }
        });
      },
      onPanUpdate: (e) {
        isTap = true;
        _initLeftTop();
        setState(() {
          currentColor =
              getColorAtPoint(e.globalPosition.dx, e.globalPosition.dy);
          if (widget.selectColorCallBack != null) {
            widget.selectColorCallBack(currentColor);
          }
        });
      },
    );
  }

  void _initLeftTop() {
    if (globalKey.currentContext != null && topLeftPosition == null) {
      print("================");
      final RenderBox box = globalKey.currentContext.findRenderObject();
      topLeftPosition = box.localToGlobal(Offset.zero);
    }
  }

  bool isOutSide(double eventX, double eventY) {
    double x = eventX -
        (topLeftPosition.dx + radius + widget.padding - widget.ringWidth / 2);
    double y = eventY -
        (topLeftPosition.dy + radius + widget.padding - widget.ringWidth / 2);
    double r = sqrt(x * x + y * y);
    print('r=$r--------------radius=$radius');
    if (r >= radius) return true;
    return false;
  }

  void _setColor(Color color) {
    print("setColor=$color");
    //设置颜色值
    var hsvColor = HSVColor.fromColor(color);

    print("setColor=$hsvColor");
    double r = hsvColor.saturation * radius;
    double radian = hsvColor.hue / -180.0 * pi;
    currentOffset = new Offset(
        radius +
            widget.padding -
            widget.ringWidth / 2 +
            radius * cos(radian * pi / 180),
        (radius - widget.padding - widget.ringWidth / 2) +
            radius * sin(radian * pi / 180));
    _updateSelector(r * cos(radian), -r * sin(radian));
    currentColor = color;
  }

  void _updateSelector(double eventX, double eventY) {
    //更新选中颜色值

    double r = sqrt(eventX * eventX + eventY * eventY);
    double x = eventX, y = eventY;
    if (r > radius - widget.ringWidth && r < radius + widget.ringWidth) {
      x *= radius / r;
      y *= radius / r;
    }
    double radians = atan(eventX / eventY);
    selectPosition = new Offset(radius * cos(radians), radius * sin(radians));
  }

  Color getColorAtPoint(double eventX, double eventY) {
    //获取坐标在色盘中的颜色值
    double x = eventX - (topLeftPosition.dx + radius + widget.padding);
    double y = eventY - (topLeftPosition.dy + radius + widget.padding);
    double r = sqrt(x * x + y * y);
    List<double> hsv = [0.0, 0.0, 1.0];
    var angle = atan2(-y, -x);
    hsv[0] = (atan2(-y, -x) / pi * 180).toDouble() + 180;
    currentOffset = new Offset(
        topLeftPosition.dx +
            radius +
            widget.padding -
            widget.ringWidth / 2 +
            radius * cos(hsv[0] * pi / 180),
        (topLeftPosition.dy + radius - widget.padding - widget.ringWidth / 2) +
            radius * sin(hsv[0] * pi / 180));
    hsv[1] = max(0, min(1, (r / radius)));
    return HSVColor.fromAHSV(1.0, hsv[0], hsv[1], hsv[2]).toColor();
  }
}

class ColorPick extends CustomPainter {
  Paint mPaint;
  Paint saturationPaint;
  final List<Color> mCircleColors = new List();
  final List<Color> mStatColors = new List();
  SweepGradient hueShader;
  final radius;
  final ringWidth;
  RadialGradient saturationShader;

  ColorPick({this.radius, this.ringWidth}) {
    _init();
  }

  void _init() {
    //{Color.RED, Color.YELLOW, Color.GREEN, Color.CYAN, Color.BLUE, Color.MAGENTA, Color.RED}
    mPaint = new Paint();
    mPaint.strokeWidth = ringWidth;
    mPaint.style = PaintingStyle.stroke;
    saturationPaint = new Paint();
    mCircleColors.add(Color.fromARGB(255, 255, 0, 0));
    mCircleColors.add(Color.fromARGB(255, 255, 255, 0));
    mCircleColors.add(Color.fromARGB(255, 0, 255, 0));
    mCircleColors.add(Color.fromARGB(255, 0, 255, 255));
    mCircleColors.add(Color.fromARGB(255, 0, 0, 255));
    mCircleColors.add(Color.fromARGB(255, 255, 0, 255));
    mCircleColors.add(Color.fromARGB(255, 255, 0, 0));

    mStatColors.add(Color.fromARGB(255, 255, 255, 255));
    mStatColors.add(Color.fromARGB(0, 255, 255, 255));
    hueShader = new SweepGradient(colors: mCircleColors);
    saturationShader = new RadialGradient(colors: mStatColors);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    mPaint.shader = hueShader.createShader(rect);
    saturationPaint.shader = saturationShader.createShader(rect);
    // 注意这一句
    canvas.clipRect(rect);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, mPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
