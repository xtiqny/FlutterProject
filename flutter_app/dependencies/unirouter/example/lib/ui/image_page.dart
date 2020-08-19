import 'package:flutter/material.dart';

class ImagePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ImagePageState();
  }
}

class _ImagePageState extends State<ImagePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: GridView.builder(gridDelegate: null, itemBuilder: null),
    );
  }
}
