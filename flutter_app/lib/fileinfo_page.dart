import 'package:flutter/material.dart';
import 'dart:ui';
//import 'package:unirouter/unirouter.dart';
//import 'base_page.dart';


class FileInfoPage extends  StatefulWidget{
  FileInfoPage(String instanceKey, Map params);
  @override
  State<StatefulWidget> createState() {
    return FileInfoPageState('gddsgsa');
  }
}

Color getCurColor()
{
  return  Colors.white;
}

@override
Widget FileInfoWidget(String title,String name,bool bShowLink ,bool bShowRName) {

  final double bottonSize = 16;
  return new Container(
    height: 48,
    width: 414,
    decoration: new BoxDecoration(
      color: Colors.white,
    ),

    child: new Row(
     //mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(width: 16,),
       Text(title,style: TextStyle(color:Color(0xff666666),fontSize: 14,decorationColor: Colors.white),),
        //new Expanded(child: null)
      Expanded(
        child: new Text(name,
          style: TextStyle(color: Color(0xff222222),
              fontSize: 14,
              decorationColor: Colors.white,
              fontFamily:'PingFangSC-Medium'),
        )
      ),

       // new Expanded(child: null)
        new Container(
          width: 16,
          height: 16,
          margin: EdgeInsets.only(right: 16),
          color: Colors.red,
        ),
      ],

      
    ),
  );
  // return new Container(
  //   height: 48,
  //   //width: 414,
  //   child: new Row(
  //     children: <Widget>[
  //       new Container(
  //         padding: EdgeInsets.only(left: 16,top: 14.0,bottom: 14.0),
  //         child: Text(title),
  //       ),
  //       new Container(
  //         padding: EdgeInsets.only(right: bottonSize + 16 + 5),
  //         child: Text(name),
  //       ),
  //     bShowRName ?
  //     new Expanded(
  //         child: new Container(
  //           padding: EdgeInsets.only(right: 16.0),
  //           child: new IconButton(icon: Image.asset('cctv.jpg'), onPressed: null),
  //         ),
  //     ) :  Container(
  //       width: 0.0,
  //       height: 0.0,
  //     ),
  //
  //     bShowLink ? getSegmentLine() :  Container(
  //       width: 0.0,
  //       height: 0.0,
  //     ),
  //     ],
  //   ),
  // );
}

//分割线
getSegmentLine() {
  return Container(
    margin: EdgeInsets.only(left: 16, top: 0, right: 0, bottom: 0),
    height: 1,
    child: Container(
      color: Colors.grey[200],
    ),
  );
}

@override
Widget CenterImage()
{
  return Container(
    height: 120,
    width: 120,
    decoration: new BoxDecoration(
      border: new Border.all(width: 1.0,color: Color(0xffE3E3E3)), color: Color(0xffFAFAFA),
    ),
    //color: Color(0xffFAFAFA),

    child: new Center(
      child: new Container(
        padding: EdgeInsets.all(20),
        child: new Image.asset('assets/images/cctv.jpg'),
      ),
    ),
  );
}

class FileInfoPageState extends State<FileInfoPage> {
  final String instanceKey;

  FileInfoPageState(this.instanceKey);

  final width = window.physicalSize.width;

  @override
  Widget curview = Container(
    child: new Row(
      children: <Widget>[
        Container(
          height: 200,
          width: 414,
          //color: Colors.white,
          padding: EdgeInsets.only(top: 40),
          decoration: new BoxDecoration(
            //border: new Border.all(width: 1.0,color: Color(0xffE3E3E3)),
              color: getCurColor()
          ),
          child: new Column(
            children: <Widget>[
              CenterImage(),
            ],
          ),
        ),
      ],

    ),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: new ListView(
        //禁止滚动
        physics: const NeverScrollableScrollPhysics(),

        children: <Widget>[
          curview,
          FileInfoWidget('文件命名：', 'jdsjgjk.txt', true, true),
          //添加下滑线
          getSegmentLine(),
          FileInfoWidget('文件命名：', 'jdsjgjk.txt', true, true),
          FileInfoWidget('文件命名：', 'jdsjgjk.txt', true, true),
        ],
      ),
    );
  }
}







