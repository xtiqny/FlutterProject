import 'dart:developer';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fileselectmodel.dart';


List<FileSelectModle> getCurFileDatas()
{

  FileSelectModle modle1 = new FileSelectModle();
  modle1.title = '自定义文件夹名称1';
  modle1.iconPath = 'assets/images/cctv.jpg';

  FileSelectModle modle2 = new FileSelectModle();
  modle2.title = '自定义文件夹名称2';
  modle2.iconPath = 'assets/images/cctv.jpg';

  FileSelectModle modle3 = new FileSelectModle();
  modle3.title = '自定义文件夹名称3';
  modle3.iconPath = 'assets/images/cctv.jpg';

  FileSelectModle modle4 = new FileSelectModle();
  modle4.title = '自定义文件夹名称4';
  modle4.iconPath = 'assets/images/cctv.jpg';

  FileSelectModle modle5 = new FileSelectModle();
  modle5.title = '自定义文件夹名称5';
  modle5.iconPath = 'assets/images/cctv.jpg';

  List<FileSelectModle> list = [modle1,modle2,modle3,modle4,modle5];
  return list;
}

Widget buildListData(BuildContext context,String title,String iocnPath)
{
  return new ListTile(
    leading: new Container(
      height: 40,
      width: 40,
      //margin: EdgeInsets.only(left: 16),
      child: new Image.asset(iocnPath),
    ),
    title: new Text(title),
    trailing: new Container(
      height: 16,
      width: 16,
      //margin: EdgeInsets.only(right: 8),
      child: Image.asset(iocnPath),
    ),
    onTap: _fileSelect,
  );
}

_fileSelect()
{
  FileSelectFinlect cctv = new FileSelectFinlect();
  var map = {
    'name': 'cctv',
  };
  Future<dynamic> str = cctv.getNativeData('envType',map);
  print('dgdsgda');
}

class FileSelectPage extends StatefulWidget {
  @override
  _FileSelectPageState createState() => _FileSelectPageState();
}

class _FileSelectPageState extends State<FileSelectPage> {



  @override
  Widget build(BuildContext context) {
    List<FileSelectModle> _list = getCurFileDatas();
    List<Widget> _listWidget = [];
    for(int i = 0;i < _list.length - 1;i++)
      {
        FileSelectModle curmodle = _list[i];
        _listWidget.add(buildListData(context,curmodle.title, curmodle.iconPath));
      }

     const EventChannel _eventChannel = const EventChannel('ios_event_channel');


    void _onEvent(dynamic event) {
      print("我进来了");
      Map map = event;
      //此处为从iOS端接收到的数据
      if (map['key'] == 'wifi'){
        print("wifi名字:${map['name']}");
      }
    }

    void _onError(dynamic error){
      print("我进入了错误");
      print("--------------error:${error}");
    }

    _eventChannel.receiveBroadcastStream("init").listen(_onEvent, onError: _onError);

    // 分割线
    var divideTiles = ListTile.divideTiles(context: context, tiles: _listWidget).toList();
    return Scaffold(
      // appBar: new AppBar(
      //   title: new Text('文件选择'),
      // ),

      body: new Scrollbar(
          // child: new ListView(
          //   children: _listWidget,
          // ),
        
        child: new ListView.builder(
          itemCount: _list.length,
            itemBuilder: (BuildContext context, int index)
                {
                  FileSelectModle cctv = _list[index];
                  return new Container(
                    // decoration: BoxDecoration(
                    //   border: Border(bottom: BorderSide(width: 0.5, color: Color(0xffe5e5e5)))
                    // ),
                    child: Column(
                      children: <Widget>[

                        buildListData(context, cctv.title, cctv.iconPath),
                        //分割线
                        Container(
                          margin: EdgeInsets.only(left: 16),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(width: 0.5, color: Color(0xffe5e5e5)))
                          ),
                        )
                      ],
                    ),
                  );
                }
        ),
        ),


    );
  }



}
