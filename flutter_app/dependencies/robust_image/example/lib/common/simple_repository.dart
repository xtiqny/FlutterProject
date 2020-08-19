import 'package:flutter/services.dart' show rootBundle;

Future<List<String>> loadRemoteImageList() async {
  String data = await rootBundle.loadString('data/imagelist.json');
  List<String> lines = data.split('\n');
  lines.removeWhere((line) => line.isEmpty);
  return lines;
}
