import 'package:color_pick/ring_color_pick.dart';
import 'package:flutter/material.dart';

class RingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return RingPageState();
  }
}

class RingPageState extends State<RingPage> {
  Color currentColor = Color(0xff0000ff);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("色环选择器"),
      ),
      body: Center(
          child: Column(
        children: <Widget>[
          ColorRingPickView(
            selectColor: Color(0xff00eaff),
            selectRadius: 40,
            ringWidth: 30,
            selectRingColor: Colors.white,
            selectColorCallBack: (color) {
              setState(() {
                currentColor = color;
              });
            },
          ),
          Container(
            color: currentColor,
            height: 50,
            width: 50,
            child: SizedBox(),
          )
        ],
      )),
    );
  }
}
