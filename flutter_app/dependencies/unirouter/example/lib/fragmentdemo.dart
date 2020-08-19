import 'package:flutter/material.dart';
import 'package:unirouter/unirouter_plugin.dart';

class FragmentDemoWidget extends StatefulWidget {
  FragmentDemoWidget({Key key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return FlutterDemoWidgetState();
  }
}

class FlutterDemoWidgetState extends State<FragmentDemoWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    instanceKey = UniRouter.instance.routeOf(context)?.instanceKey;
  }

  static int num = 1;
  String instanceKey;
  static const kTextStyle = const TextStyle(
    fontSize: 19,
    shadows: null,
    color: Colors.black,
  );

  Widget build(BuildContext context) {
    TextTheme txtTh = Theme.of(context).textTheme;
    return new Scaffold(
        appBar: null,
        backgroundColor: Colors.orange,
        body: new Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '$instanceKey',
                  style: TextStyle(fontSize: 20),
                ),
                // SizedBox(width: 1.0, height: 100.0),
                RaisedButton(
                  child: Text(
                    "Open Fragment Flutter",
                    style: txtTh.display1.merge(kTextStyle),
                  ),
                  onPressed: () {
                    UniRouter.instance
                        .push("/fragdemo", instanceKey: 'ff${num++}');
                  },
                ),
                RaisedButton(
                  child: Text(
                    "Open Flutter",
                    style: txtTh.display1.merge(kTextStyle),
                  ),
                  onPressed: () {
                    UniRouter.instance
                        .push("/flutterdemo", instanceKey: 'ff${num++}');
                  },
                ),
                SizedBox(width: 1.0, height: 100.0),
                RaisedButton(
                  child: Text(
                    "Open Native",
                    style: txtTh.display2.merge(kTextStyle),
                  ),
                  onPressed: () {
                    UniRouter.instance
                        .push("/nativedemo", instanceKey: 'ff${num++}');
                  },
                ),
              ],
            ),
          ),
        ),
        floatingActionButton:
            null // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
