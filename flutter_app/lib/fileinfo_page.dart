import 'dart:developer';

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

_renameClick()
{
  //TODO 文件重命名功能
  log('gsdfdsafg');
}

/*
* 功能：文件详情列表项
* title :文件信息项说明
* name:显示的内容
* bShowRName:是否展示重命名按钮
* */
@override
Widget FileInfoWidget(String title,String name ,bool bShowRName) {

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
        Container(
           width:70.0,
          margin: EdgeInsets.only(left: 16),
          child: new Text(title,
            style: TextStyle(
                color:Color(0xff666666),
                fontSize: 14,
                decorationColor: Colors.white,
                fontWeight: FontWeight.w400),
          ),
        ),
        //SizedBox(width: 16,),

        //new Expanded(child: null)
      Expanded(
        child: new Text(name,
          style: TextStyle(color: Color(0xff222222),
              fontSize: 14,
              decorationColor: Colors.white,
              fontWeight: FontWeight.w600),
        )
      ),

       // new Expanded(child: null)
        bShowRName ?
        new Container(
          width: 16,
          height: 16,
          margin: EdgeInsets.only(right: 20),
          child: new FloatingActionButton(
            onPressed: _renameClick,
            child: new Image.asset('assets/images/op_tool_rename_black.png'),
            backgroundColor: Colors.transparent,
          )
        ) : new Container( padding: EdgeInsets.all(0),)
      ],

      
    ),
  );
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
/*
* 文件详情图片显示
* assetName:显示图片的路径
* */
@override
Widget CenterImage(String assetName)
{
  return Container(
    height: 120,
    width: 120,
    //设置边框
    decoration: new BoxDecoration(
      border: new Border.all(width: 1.0,color: Color(0xffE3E3E3)), color: Color(0xffFAFAFA),
    ),
    //color: Color(0xffFAFAFA),

    child: new Center(
      child: new Container(
        padding: EdgeInsets.all(20),
        child: new Image.asset(assetName.length > 0 ? assetName : 'assets/images/cctv.jpg'),
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
          //设置背景颜色
          decoration: new BoxDecoration(
            //border: new Border.all(width: 1.0,color: Color(0xffE3E3E3)),
              color: getCurColor()
          ),
          child: new Column(
            children: <Widget>[
              CenterImage(''),
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
          FileInfoWidget('文件命名：', '好看的书.pdf', true),
          //添加下滑线
          getSegmentLine(),
          FileInfoWidget('文件大小：', '335K', false),
          getSegmentLine(),
          FileInfoWidget('创建者：', '张三', false),
          getSegmentLine(),
          FileInfoWidget('创建时间：', '03-03 15.43', false),
          FileInfoWidget('修改时间：', '03-03 15.43', false),
          getSegmentLine(),
          FileInfoWidget('文件路径：', '工作空间', false),
        ],
      ),
    );
  }
}







