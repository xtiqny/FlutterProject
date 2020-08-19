import 'package:flutter/material.dart';
import 'package:unirouter/unirouter_plugin.dart';

class FlutterDemoWidget extends StatefulWidget {
  FlutterDemoWidget({Key key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return FlutterDemoWidgetState();
  }
}

class FlutterDemoWidgetState extends State<FlutterDemoWidget> {
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
  double _val = 0;
  static const kTextStyle = const TextStyle(
    fontSize: 19,
    shadows: null,
    color: Colors.black,
  );

  Widget build(BuildContext context) {
    RouteAction topAction = UniRouter.instance.getTopRoute(context);
    debugPrint(
        '=========> Top Route: url=${topAction?.url} instanceKey=${topAction?.instanceKey}');
    TextTheme txtTh = Theme.of(context).textTheme;
    return new Scaffold(
        appBar: new AppBar(
          leading: new GestureDetector(
              child: new Icon(Icons.arrow_back),
              onTap: () {
                UniRouter.instance.pop();
              }),
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: new Text(
            "Demo:($instanceKey)",
            style: Theme.of(context)
                .primaryTextTheme
                .headline
                .copyWith(fontSize: 18),
          ),
        ),
        body: new Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 16,
                ),
                SizedBox(width: 1.0, height: 100.0),
                RaisedButton(
                  child: Text(
                    "Open Flutter",
                    style: txtTh.display1.merge(kTextStyle),
                  ),
                  onPressed: () async {
                    final Map<String, dynamic> result = await UniRouter.instance
                        .push("/flutterdemo",
                            instanceKey: 'f${num++}',
                            params: {"name": "Open Flutter", "interval": 100},
                            ext: {"show": true});
                    print(
                        "-----------------> Result of /flutterdemo is $result");
                  },
                ),
                SizedBox(width: 1.0, height: 100.0),
                RaisedButton(
                  child: Text(
                    "Open Fragment Flutter",
                    style: txtTh.display2.merge(kTextStyle),
                  ),
                  onPressed: () async {
                    final Map<String, dynamic> result = await UniRouter.instance
                        .push("/fragdemo", instanceKey: 'f${num++}');
                    print("-----------------> Result of /fragdemo is $result");
                    if (mounted) {
                      setState(() {
                        // Set some value.
                      });
                    }
                  },
                ),
                SizedBox(width: 1.0, height: 100.0),
                RaisedButton(
                  child: Text(
                    "Open Native",
                    style: txtTh.display2.merge(kTextStyle),
                  ),
                  onPressed: () async {
                    final Map<String, dynamic> result = await UniRouter.instance
                        .push("/nativedemo", instanceKey: 'f${num++}');
                    print(
                        "-----------------> Result of /nativedemo is $result");
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
