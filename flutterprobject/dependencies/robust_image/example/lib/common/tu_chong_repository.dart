import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:robust_image_app/common/tu_chong_source.dart';

Future<String> getFileData(String path) async {
  return await rootBundle.loadString(path);
}

class TuChongRepository extends LoadingMoreBase<TuChongItem> {
  int pageindex = 1;

  @override
  // TODO: implement hasMore
  bool _hasMore = true;
  bool forceRefresh = false;
  bool get hasMore => (_hasMore && length < 100) || forceRefresh;
  static Client _client = Client();

  @override
  Future<bool> refresh([bool clearBeforeRequest = false]) async {
    // TODO: implement onRefresh
    _hasMore = true;
    pageindex = 1;
    //force to refresh list when you don't want clear list before request
    //for the case, if your list already has 20 items.
    forceRefresh = !clearBeforeRequest;
    var result = await super.refresh(clearBeforeRequest);
    forceRefresh = false;
    return result;
  }

  Future<bool> loadFromAssets() async {
    print('loadFromAssets');
    try {
      String data = await getFileData('data/imagelist.json');
      print('$data');
      var jsonData = json.decode(data);
      var source = TuChongSource.fromJson(jsonData);
      source.feedList.forEach((item) {
        this.clear();
        if (item.hasImage && !this.contains(item) && hasMore) {
          this.add(item);
        }
      });
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  @override
  Future<bool> loadData([bool isloadMoreAction = false]) async {
    debugPrint(
        'loadData length before load:$length, isloadMoreAction=$isloadMoreAction');
    String url = "";
    if (this.length == 0) {
      url =
          "https://api.tuchong.com/feed-app?os_api=22&device_type=MI&device_platform=android&ssmix=a&manifest_version_code=232&dpi=400&abflag=0&uuid=651384659521356&version_code=232&app_name=tuchong&version_name=2.3.2&openudid=65143269dafd1f3a5&resolution=1280*1000&os_version=5.8.1&ac=wifi&aid=0&page=1&type=refresh&count=1000";
      //"https://api.tuchong.com/feed-app?count=2000";
    } else {
      int lastPostId = this[this.length - 1].post_id;
      url =
          'https://api.tuchong.com/feed-app?os_api=22&device_type=MI&device_platform=android&ssmix=a&manifest_version_code=232&dpi=400&abflag=0&uuid=651384659521356&version_code=232&app_name=tuchong&version_name=2.3.2&openudid=65143269dafd1f3a5&resolution=1280*1000&os_version=5.8.1&ac=wifi&aid=0&post_id=$lastPostId&page=$pageindex&type=loadmore';
//          "https://api.tuchong.com/feed-app?post_id=$lastPostId&page=$pageindex&type=loadmore";
    }
    bool isSuccess = false;
    try {
      //to show loading more clearly, in your app,remove this
      //await Future.delayed(Duration(milliseconds: 500, seconds: 1));

      print('Load url:$url');
      var result = await _client.get(url);

      var source = TuChongSource.fromJson(json.decode(result.body));
      debugPrint('$source');
      if (pageindex == 1) {
        this.clear();
      }

      source.feedList.forEach((item) {
        if (item.hasImage && !this.contains(item) && hasMore) {
          print('${item.imageUrl}');
          this.add(item);
        }
      });

      _hasMore = source.feedList.length != 0;
      pageindex++;
//      this.clear();
//      _hasMore=false;
      isSuccess = true;
    } catch (exception) {
      isSuccess = false;
      print(exception);
    }
    return isSuccess;
  }
}
