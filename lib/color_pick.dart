library color_pick;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:math';

typedef SelectColor = void Function(Color color);

class ColorPickView extends StatefulWidget {
  final Size? size;
  final double? selectRadius;
  final double? padding;
  final Color? selectColor;
  final Color? selectRingColor;
  final SelectColor? selectColorCallBack;

  ColorPickView(
      {Key? key,
      this.size,
      this.selectColorCallBack,
      this.selectRadius,
      this.padding,
      this.selectRingColor,
      this.selectColor})
      : super(key: key) {
    assert(size == null || (size != null), '控件宽度太宽');
    assert(size == null || (size != null && size!.height == size!.width),
        '控件宽高必须相等');
  }

  @override
  State<StatefulWidget> createState() {
    return ColorPickState();
  }
}

class ColorPickState extends State<ColorPickView> {
  double? radius;
  double? selectRadius, padding;
  Color currentColor = const Color(0xff00ff);
  Color? selectRingColor;

  Offset? currentOffset;
  Offset? topLeftPosition;
  Offset? selectPosition;
  Size? screenSize, size;
  GlobalKey globalKey = new GlobalKey();
  bool isTap = false;

  @override
  Widget build(BuildContext context) {
    screenSize ??= MediaQuery.of(context).size;
    size = (widget.size ?? screenSize);
    selectRadius = (widget.selectRadius ?? 10);
    padding = (widget.padding ?? 40);
    selectRingColor = (widget.selectRingColor ?? Colors.black);
    assert((size != null && screenSize!.width >= size!.width), '控件宽度太宽');
    radius = size!.width / 2 - padding!;
    currentOffset ??= Offset(radius!, radius!);
    if (widget.selectColor != null && selectPosition == null) {
      _setColor(widget.selectColor!);
    }
    _initLeftTop();
    return GestureDetector(
      key: globalKey,
      child: SizedBox(
        width: size!.width,
        height: size!.width,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              painter: ColorPick(radius: radius),
              size: size!,
            ),
            Positioned(
              left: isTap
                  ? currentOffset!.dx -
                      (topLeftPosition == null
                          ? 0
                          : (topLeftPosition!.dx + selectRadius! / 2))
                  : (selectPosition == null
                      ? radius
                      : selectPosition!.dx + selectRadius! / 2),
              top: isTap
                  ? currentOffset!.dy -
                      (topLeftPosition == null
                          ? 0
                          : (topLeftPosition!.dy + selectRadius! / 2))
                  : (selectPosition == null
                      ? radius
                      : selectPosition!.dy + selectRadius! / 2),
              //这里减去80，是因为上下边距各40 所以需要减去还有半径
              child: Container(
                width: selectRadius,
                height: selectRadius,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(selectRadius!),
                  border: Border.fromBorderSide(
                      BorderSide(color: selectRingColor!)),
                ),
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
          if (!isOutSide(e.globalPosition.dx, e.globalPosition.dy)) {
            currentColor =
                getColorAtPoint(e.globalPosition.dx, e.globalPosition.dy);
            currentOffset = e.globalPosition;
            if (widget.selectColorCallBack != null) {
              widget.selectColorCallBack!(currentColor);
            }
          }
        });
      },
      onPanUpdate: (e) {
        isTap = true;
        _initLeftTop();
        setState(() {
          if (!isOutSide(e.globalPosition.dx, e.globalPosition.dy)) {
            currentOffset = e.globalPosition;
            currentColor =
                getColorAtPoint(e.globalPosition.dx, e.globalPosition.dy);
            if (widget.selectColorCallBack != null) {
              widget.selectColorCallBack!(currentColor);
            }
          }
        });
      },
    );
  }

  void _initLeftTop() {
    if (globalKey.currentContext != null && topLeftPosition == null) {
      final RenderBox? box =
          globalKey.currentContext!.findRenderObject() as RenderBox?;
      topLeftPosition = box?.localToGlobal(Offset.zero);
    }
  }

  bool isOutSide(double eventX, double eventY) {
    double x = eventX - (topLeftPosition!.dx + radius! + padding!);
    double y = eventY - (topLeftPosition!.dy + radius! + padding!);
    double r = sqrt(x * x + y * y);
    if (r >= radius!) return true;
    return false;
  }

  void _setColor(Color color) {
    //设置颜色值
    var hsvColor = HSVColor.fromColor(color);
    double r = hsvColor.saturation * radius!;
    double radian = hsvColor.hue / -180.0 * pi;
    _updateSelector(r * cos(radian), -r * sin(radian));
    currentColor = color;
  }

  void _updateSelector(double eventX, double eventY) {
    //更新选中颜色值
    double r = sqrt(eventX * eventX + eventY * eventY);
    double x = eventX, y = eventY;
    if (r > radius!) {
      x *= radius! / r;
      y *= radius! / r;
    }
    selectPosition = Offset(x + radius! + padding!, y + radius! + padding!);
  }

  Color getColorAtPoint(double eventX, double eventY) {
    //获取坐标在色盘中的颜色值
    double x = eventX - (topLeftPosition!.dx + radius! + padding!);
    double y = eventY - (topLeftPosition!.dy + radius! + padding!);
    double r = sqrt(x * x + y * y);
    List<double> hsv = [0.0, 0.0, 1.0];
    hsv[0] = (atan2(-y, -x) / pi * 180).toDouble() + 180;
    hsv[1] = max(0, min(1, (r / radius!)));
    return HSVColor.fromAHSV(1.0, hsv[0], hsv[1], hsv[2]).toColor();
  }
}

class ColorPick extends CustomPainter {
  Paint? mPaint;
  Paint? saturationPaint;
  final List<Color> mCircleColors = [];
  final List<Color> mStatColors = [];
  SweepGradient? hueShader;
  final double? radius;
  RadialGradient? saturationShader;

  ColorPick({this.radius = 10}) {
    mPaint = Paint();
    saturationPaint = Paint();
    mCircleColors.add(const Color.fromARGB(255, 255, 0, 0));
    mCircleColors.add(const Color.fromARGB(255, 255, 255, 0));
    mCircleColors.add(const Color.fromARGB(255, 0, 255, 0));
    mCircleColors.add(const Color.fromARGB(255, 0, 255, 255));
    mCircleColors.add(const Color.fromARGB(255, 0, 0, 255));
    mCircleColors.add(const Color.fromARGB(255, 255, 0, 255));
    mCircleColors.add(const Color.fromARGB(255, 255, 0, 0));

    mStatColors.add(const Color.fromARGB(255, 255, 255, 255));
    mStatColors.add(const Color.fromARGB(0, 255, 255, 255));
    hueShader = SweepGradient(colors: mCircleColors);
    saturationShader = RadialGradient(colors: mStatColors);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    mPaint!.shader = hueShader!.createShader(rect);
    saturationPaint!.shader = saturationShader!.createShader(rect);
    // 注意这一句
    canvas.clipRect(rect);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), radius!, mPaint!);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), radius!, saturationPaint!);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
