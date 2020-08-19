import 'package:flutter/material.dart';
import 'package:unirouter/unirouter.dart';

import 'app_ui_theme.dart';

class UniRouteDemoApp extends StatefulWidget {
  UniRouteDemoApp();
  State<StatefulWidget> createState() {
    return new UniRouteDemoAppState();
  }
}

class UniRouteDemoAppState extends State<UniRouteDemoApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Unirouter Demo',
      theme: kAppTheme,
      color: Colors.green,
      locale: Locale("zh", "CN"),
      builder: UniRouter.getBuilder(),
      home: Container(
        color: Colors.transparent,
      ),
    );
  }
}

class MyHomeWidget extends StatefulWidget {
  MyHomeWidget({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new MyHomeWidgetState();
  }
}

class MyHomeWidgetState extends State<MyHomeWidget> {
  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.white,
    );
  }
}
