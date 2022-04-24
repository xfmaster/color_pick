import 'package:flutter/material.dart';

import 'ring_color_pick.dart';

class RingPage extends StatefulWidget {
  const RingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return RingPageState();
  }
}

class RingPageState extends State<RingPage> {
  Color currentColor = const Color(0xff0000ff);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Color wheel selector"),
      ),
      body: Center(
          child: Column(
        children: <Widget>[
          ColorRingPickView(
            selectColor: const Color(0xff00eaff),
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
            child: const SizedBox(),
          )
        ],
      )),
    );
  }
}
