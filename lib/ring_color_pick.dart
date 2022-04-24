import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:math';

typedef SelectColor = void Function(Color color);

class ColorRingPickView extends StatefulWidget {
  final Size? size;
  final double? selectRadius;
  final double? padding;
  final double? ringWidth;
  final Color? selectRingColor;
  final Color? selectColor;
  final SelectColor? selectColorCallBack;

  ColorRingPickView(
      {Key? key, this.size,
      this.selectColorCallBack,
      this.selectRadius,
      this.padding,
      this.selectRingColor,
      this.selectColor,
      this.ringWidth}) : super(key: key) {
    assert(size == null || (size != null && size!.height== size!.width),
        'The width and height of the control must be equal');
    assert(size == null || (size != null && size!.height== size!.width),
        'The width and height of the control must be equal');
  }

  @override
  State<StatefulWidget> createState() {
    return ColorPickState();
  }
}

class ColorPickState extends State<ColorRingPickView> {
  double? radius;
  double? selectRadius;
  double? padding;
  double? ringWidth;
  Color currentColor = const Color(0xff00ff);
  Color? selectRingColor;

  Offset? currentOffset;
  Offset? topLeftPosition;
  Offset? selectPosition;
  Size? size;
  Size? screenSize;
  double? centerX, centerY;
  GlobalKey globalKey = GlobalKey();
  bool isTap = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectColor != null && selectPosition == null) {
      Future.delayed(const Duration(milliseconds: 300)).then((val) {
        _setColor(widget.selectColor!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    screenSize ??= MediaQuery.of(context).size;
    size = (widget.size ?? screenSize);
    selectRadius = (widget.selectRadius ?? 20);
    padding = (widget.padding ?? 40);
    ringWidth = (widget.ringWidth ?? 20);
    selectRingColor = (widget.selectRingColor ?? Colors.white);
    assert((size != null && screenSize!.width >= size!.width), 'Control width is too wide');
    radius =size!.width / 2 -padding!;
    selectPosition = currentOffset ??= Offset(radius!, radius!);
    _initLeftTop();
    return GestureDetector(
      key: globalKey,
      child: SizedBox(
        width:size!.width,
        height:size!.width,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              painter: ColorPick(radius: radius, ringWidth:ringWidth),
              size:size!,
            ),
            Positioned(
              left: isTap
                  ? currentOffset!.dx -
                      topLeftPosition!.dx -
                     selectRadius! / 2
                  : selectPosition!.dx -
                      (topLeftPosition == null ? 0 : topLeftPosition!.dx) -
                     selectRadius! / 2,
              top: isTap
                  ? currentOffset!.dy -
                      topLeftPosition!.dy -
                     selectRadius! / 2
                  : selectPosition!.dy -
                      (topLeftPosition == null ? 0 : topLeftPosition!.dy) -
                     selectRadius! / 2,
              child: Container(
                width:selectRadius,
                height:selectRadius,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.selectRadius!),
                    border: Border.fromBorderSide(
                        BorderSide(color:selectRingColor!))),
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
            widget.selectColorCallBack!(currentColor);
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
            widget.selectColorCallBack!(currentColor);
          }
        });
      },
    );
  }

  void _initLeftTop() {
    if (globalKey.currentContext != null ) {
      final RenderBox? box =
      globalKey.currentContext!.findRenderObject() as RenderBox?;
      topLeftPosition = box?.localToGlobal(Offset.zero);
      centerX = topLeftPosition!.dx +
         padding! / 2 +
         selectRadius! / 2 +
          radius!;
      centerY = topLeftPosition!.dy +
         padding! / 2 +
         selectRadius! / 2 +
          radius!;
    }
  }

  bool isOutSide(double eventX, double eventY) {
    double x = eventX - centerX!;
    double y = eventY - centerY!;
    double r = sqrt(x * x + y * y);
    if (r >= radius!) return true;
    return false;
  }

  void _setColor(Color color) {
    //设置颜色值
    var hsvColor = HSVColor.fromColor(color);
    _initLeftTop();
    double r = hsvColor.saturation * radius!;
    double radian = hsvColor.hue / 180.0 * pi;
    setState(() {
      currentOffset =
          Offset(centerX! + r * cos(radian), centerY! + r * sin(radian));
      currentColor = color;
    });
  }

  Color getColorAtPoint(double eventX, double eventY) {
    //获取坐标在色盘中的颜色值
    double x = eventX - centerX!;
    double y = eventY - centerY!;
    double r = sqrt(x * x + y * y);
    List<double> hsv = [0.0, 0.0, 1.0];
    var h = (atan2(-y, -x) / pi * 180).toDouble() + 180;
    hsv[0] = h;
    currentOffset =  Offset(centerX! + radius! * cos(h * pi / 180),
        centerY! + radius! * sin(h * pi / 180));
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
  final double? ringWidth;
  RadialGradient? saturationShader;

  ColorPick({this.radius, this.ringWidth}) {
    _init();
  }

  void _init() {
    //{Color.RED, Color.YELLOW, Color.GREEN, Color.CYAN, Color.BLUE, Color.MAGENTA, Color.RED}
    mPaint =  Paint();
    mPaint?.strokeWidth = ringWidth!;
    mPaint?.style = PaintingStyle.stroke;
    saturationPaint =  Paint();
    mCircleColors.add(const Color.fromARGB(255, 255, 0, 0));
    mCircleColors.add(const Color.fromARGB(255, 255, 255, 0));
    mCircleColors.add(const Color.fromARGB(255, 0, 255, 0));
    mCircleColors.add(const Color.fromARGB(255, 0, 255, 255));
    mCircleColors.add(const Color.fromARGB(255, 0, 0, 255));
    mCircleColors.add(const Color.fromARGB(255, 255, 0, 255));
    mCircleColors.add(const Color.fromARGB(255, 255, 0, 0));

    mStatColors.add(const Color.fromARGB(255, 255, 255, 255));
    mStatColors.add(const Color.fromARGB(0, 255, 255, 255));
    hueShader =  SweepGradient(colors: mCircleColors);
    saturationShader =  RadialGradient(colors: mStatColors);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    mPaint?.shader = hueShader?.createShader(rect);
    saturationPaint?.shader = saturationShader?.createShader(rect);
    // 注意这一句
    canvas.clipRect(rect);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius!, mPaint!);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
