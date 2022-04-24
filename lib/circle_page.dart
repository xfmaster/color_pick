import 'package:flutter/material.dart';

import 'color_pick.dart';

class CirclePage extends StatefulWidget {
  const CirclePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return CirclePageState();
  }
}

class CirclePageState extends State<CirclePage> {
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
          ColorPickView(
            selectColor: const Color(0xff00eaff),
            selectRadius: 30,
            padding: 100,
            selectRingColor: Colors.black,
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
