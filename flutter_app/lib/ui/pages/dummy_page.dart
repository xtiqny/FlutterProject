import 'package:flutter/material.dart';
import 'package:unirouter/unirouter.dart';
import 'base_page.dart';

class DummyPage extends BasePageStatefulWidget {
  DummyPage(String instanceKey, Map params) : super(instanceKey, params);

  @override
  State<StatefulWidget> createState() {
    return DummyPageState(instanceKey);
  }
}

class DummyPageState extends BasePageState {
  DummyPageState(String instanceKey) : super(instanceKey);

  @override
  Widget createPageBody() {
    return Center(
      child: RaisedButton(
        child: Text("Hello world."),
        onPressed: () => UniRouter.instance.push("/dummy_page2"),
      ),
    );
  }
}

class DummyPage2 extends BasePageStatefulWidget {
  DummyPage2(String instanceKey, Map params) : super(instanceKey, params);

  @override
  _DummyPage2State createState() => _DummyPage2State(instanceKey);
}

class _DummyPage2State extends BasePageState {
  _DummyPage2State(String instanceKey) : super(instanceKey);

  @override
  Widget createPageBody() {
    return Center(
      child: Text("In developing."),
    );
  }
}
