import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:math';

typedef SelectColor = Color Function(Color color);

class ColorRingPickView extends StatefulWidget {
  Size size;
  double selectRadius;
  double padding;
  double ringWidth;
  Color selectRingColor;
  Color selectColor;
  final SelectColor selectColorCallBack;

  ColorRingPickView(
      {this.size,
      this.selectColorCallBack,
      this.selectRadius,
      this.padding,
      this.selectRingColor,
      this.selectColor,
      this.ringWidth}) {
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
  double centerX, centerY;
  GlobalKey globalKey = new GlobalKey();
  bool isTap = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.selectColor != null && selectPosition == null)
      Future.delayed(Duration(milliseconds: 300)).then((val) {
        _setColor(widget.selectColor);
      });
  }

  @override
  Widget build(BuildContext context) {
    screenSize ??= MediaQuery.of(context).size;
    widget.size ??= screenSize;
    widget.selectRadius ??= 20;
    widget.padding ??= 40;
    widget.ringWidth ??= 20;
    widget.selectRingColor ??= Colors.white;
    assert(
        widget.size == null ||
            (widget.size != null && screenSize.width >= widget.size.width),
        '控件宽度太宽');
    radius = widget.size.width / 2 - widget.padding;
    selectPosition = currentOffset ??= Offset(radius, radius);
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
              left: isTap
                  ? currentOffset.dx -
                      topLeftPosition.dx -
                      widget.selectRadius / 2
                  : selectPosition.dx -
                      (topLeftPosition == null ? 0 : topLeftPosition.dx) -
                      widget.selectRadius / 2,
              top: isTap
                  ? currentOffset.dy -
                      topLeftPosition.dy -
                      widget.selectRadius / 2
                  : selectPosition.dy -
                      (topLeftPosition == null ? 0 : topLeftPosition.dy) -
                      widget.selectRadius / 2,
              child: Container(
                width: widget.selectRadius,
                height: widget.selectRadius,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.selectRadius),
                    border: Border.fromBorderSide(
                        BorderSide(color: widget.selectRingColor))),
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
          print("$centerX-----------$centerY");
          if (widget.selectColorCallBack != null) {
            widget.selectColorCallBack(currentColor);
          }
        });
      },
    );
  }

  void _initLeftTop() {
    if (globalKey.currentContext != null && topLeftPosition == null) {
      final RenderBox box = globalKey.currentContext.findRenderObject();
      topLeftPosition = box.localToGlobal(Offset.zero);
      print(topLeftPosition.dx);
      centerX = topLeftPosition.dx +
          widget.padding / 2 +
          widget.selectRadius / 2 +
          radius;
      centerY = topLeftPosition.dy +
          widget.padding / 2 +
          widget.selectRadius / 2 +
          radius;
    }
  }

  bool isOutSide(double eventX, double eventY) {
    double x = eventX - centerX;
    double y = eventY - centerY;
    double r = sqrt(x * x + y * y);
    if (r >= radius) return true;
    return false;
  }

  void _setColor(Color color) {
    //设置颜色值
    var hsvColor = HSVColor.fromColor(color);
    _initLeftTop();
    double r = hsvColor.saturation * radius;
    double radian = hsvColor.hue / 180.0 * pi;
    setState(() {
      currentOffset =
          new Offset(centerX + r * cos(radian), centerY + r * sin(radian));
      currentColor = color;
    });
  }

  Color getColorAtPoint(double eventX, double eventY) {
    //获取坐标在色盘中的颜色值
    double x = eventX - centerX;
    double y = eventY - centerY;
    double r = sqrt(x * x + y * y);
    List<double> hsv = [0.0, 0.0, 1.0];
    var h = (atan2(-y, -x) / pi * 180).toDouble() + 180;
    hsv[0] = h;
    currentOffset = new Offset(centerX + radius * cos(h * pi / 180),
        centerY + radius * sin(h * pi / 180));
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
