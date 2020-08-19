import 'package:flutter/material.dart';

import 'method_channel_ex_example.dart';

class MethodChannelExPage extends StatefulWidget {
  @override
  _MethodChannelExPageState createState() => _MethodChannelExPageState();
}

class _MethodChannelExPageState extends State<MethodChannelExPage>
    with SingleTickerProviderStateMixin {
  AnimationController _animController;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: Duration(seconds: 4));
    _animation = Tween(begin: 20.0, end: 300.0).animate(_animController);
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animController.forward();
      }
    });
    _animation.addListener(() {
      setState(() {});
    });
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Stack(
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () =>
                        MethodChannelExExample.instance.getDataFromList(),
                    child: Container(
                        height: 30,
                        color: Colors.blue,
                        child: Text('getDataFromList')),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () =>
                        MethodChannelExExample.instance.getDataFromListStream(),
                    child: Container(
                        height: 30,
                        color: Colors.blue,
                        child: Text('getDataFromListStream')),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () =>
                        MethodChannelExExample.instance.getDataFromMap(),
                    child: Container(
                        height: 30,
                        color: Colors.blue,
                        child: Text('getDataFromMap')),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () =>
                        MethodChannelExExample.instance.getDataFromFlutter(),
                    child: Container(
                        height: 30,
                        color: Colors.blue,
                        child: Text('getDataFromFlutter')),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () => MethodChannelExExample.instance
                        .getDataFromFlutterToNative(),
                    child: Container(
                        height: 30,
                        color: Colors.blue,
                        child: Text('getDataFromFlutterToNative')),
                  ),
                ],
              ),
            ),
            Positioned(
              left: _animation.value,
              top: 320,
              child: Icon(
                Icons.android,
                size: 60,
                color: Colors.yellow,
              ),
            )
          ],
        ),
      ),
    );
  }
}
