import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:cn21base/cn21base_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:robust_image/robust_image.dart';
import 'package:image/image.dart' as img;

import 'common/tu_chong_repository.dart';
import 'image_grid_demo.dart';

RobustImageModule imageModule;
RobustImageEngine imageEngine =
    RobustImageEngine.auto(maxDiskCacheConcurrent: 2);

class MyImageCache extends ImageCache {
  @override
  ImageStreamCompleter putIfAbsent(Object key, ImageStreamCompleter loader(),
      {ImageErrorListener onError}) {
    RobustImageKey imageKey = key as RobustImageKey;
    ImageStreamCompleter completer =
        super.putIfAbsent(key, loader, onError: onError);
//    print('Get ${imageKey.renderKey} from memory cache. completer:$completer');
    return completer;
  }

  @override
  bool evict(Object key) {
    RobustImageKey imageKey = key as RobustImageKey;
    bool result = super.evict(key);
//    print(
//        '------------ evict ${imageKey.renderKey} from memory cache. result=$result');
    return result;
  }

  @override
  void clear() {
    print('----------------- clear ------------------');
  }
}

HttpClient _httpClient = HttpClient();

Uint8List _resizeCropSquare(Uint8List bytes) {
  // 裁剪为适合作为缩略图显示的尺寸
  final img.Image rawImage = img.decodeImage(bytes);
  final img.Image thumbnail = img.copyResizeCropSquare(rawImage, 240);
  final data = img.encodeJpg(thumbnail, quality: 65);
  if (data is Uint8List) {
    return data;
  } else {
    return Uint8List.fromList(data);
  }
}

IsolateService _isolateService;

class MyHttpFetcher extends RemoteHttpFetcher {
  MyHttpFetcher({Duration timeout}) : super(timeout: timeout);

  Future closeResponse(HttpClientResponse response) async {
    final Socket socket = await response.detachSocket();
    socket.destroy();
  }

  @override
  CancelableOperation<BinaryData> fetch(RobustImageKey key) {
    HttpClientRequest request;
    HttpClientResponse response;
    String url;
    Future waitUrl;
    Future waitRequest;
    Future waitThumbnail;
    final completer = CancelableCompleter<BinaryData>(onCancel: () {
      if (waitUrl != null) {
        print('cancel while waiting url:$url');
        return waitUrl.catchError((e) {}).whenComplete(() {
          print('cancel waitUrl:$url done.');
        });
      }
      if (waitRequest != null) {
        print('cancel while waiting request:$url');
        return waitRequest.catchError((e) {}).whenComplete(() {
          print('cancel waitRequest:$url done.');
        });
      }
      if (response != null) {
        print(
            'response for ${request.uri} is on going, close it to cancel now.');
        try {
          return closeResponse(response).whenComplete(() {
            print('cancel response for $url done.');
          });
        } catch (e) {
          print('MyHttpFetcher onCancel error: $e');
        }
      }
      if (waitThumbnail != null) {
        print('cancel while creating thumbnail url:$url');
        return waitThumbnail.catchError((e) {}).whenComplete(() {
          print('cancel waitThumbnail:$url done.');
        });
      }
      return null;
    });
    void requestBody(CancelableCompleter<BinaryData> completer) async {
      try {
        final result = resolveUrl(key);
        if (result is Future) {
          url = await result;
        } else {
          url = result;
        }

        waitUrl = _httpClient.getUrl(Uri.parse(url));
        request = await waitUrl;
        waitUrl = null;
        if (completer.isCanceled || completer.isCompleted) {
          return;
        }
        waitRequest = request.close();
//            Future.delayed(Duration(seconds: 10), () => request.close());
        response = await waitRequest;
        waitRequest = null;
        if (completer.isCanceled || completer.isCompleted) {
          if (response != null) {
            await closeResponse(response);
          }
          return;
        }
        if (response.statusCode != HttpStatus.ok) {
          throw Exception(
              'HTTP request failed, statusCode: ${response?.statusCode}, $url');
        }

        final Uint8List bytes =
            await consolidateHttpClientResponseBytes(response);
        response = null;
        if (completer.isCanceled || completer.isCompleted) {
          return;
        }
        if (bytes == null || bytes.lengthInBytes == 0) {
          throw Exception(
              'NetworkImage is an empty file: $url'); //_isolateService.execute(_downloadAndCrop, [url, 20]);
        }
        waitThumbnail = _isolateService.execute(_resizeCropSquare, bytes);
        final imgBytes = await waitThumbnail;
        waitThumbnail = null;

        if (!completer.isCompleted) {
          completer.complete(Uint8ListData(imgBytes));
        }

//        completer.complete(Uint8ListData(response?.bodyBytes));
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    }

    requestBody(completer);
    return completer.operation;
  }
}

void main() async {
  Directory tempdir = await getTemporaryDirectory();
  assert(tempdir != null);
  Directory cacheDir = Directory(p.join(tempdir.path, "robustImages"));
  cacheDir.createSync();
  _isolateService = IsolateService()..initService();
  runApp(MyApp());
  MyImageCache imageCache = MyImageCache();
  imageCache.maximumSize = 6000;
  imageCache.maximumSizeBytes = 150 * 1024 * 1024;
  _httpClient.connectionTimeout = Duration(seconds: 10);
  imageModule = RobustImageModule(
      imageCache: imageCache, //PaintingBinding.instance.imageCache,
      diskCache: FileDiskCache(cacheDir),
      sourceFetcher: MyHttpFetcher(timeout: Duration(seconds: 20)));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TuChongRepository listSourceRepository;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (c, w) {
        ScreenUtil.instance =
            ScreenUtil(width: 750, height: 1334, allowFontScaling: true)
              ..init(c);
        var data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(textScaleFactor: 1.0),
          child: Scaffold(
            body: w,
          ),
        );
      },
      home: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
                child: Text('Simple Url'),
                onPressed: () {
                  final pageWidget = ImageGridDemo(
                    useSimpleUrl: true,
                  );
                  Navigator.push(context,
                      new MaterialPageRoute(builder: (BuildContext context) {
                    return pageWidget;
                  }));
                }),
            SizedBox(
              height: 32,
            ),
            RaisedButton(
                child: Text('TuChong API'),
                onPressed: () {
                  final pageWidget = ImageGridDemo(
                    useSimpleUrl: false,
                  );
                  Navigator.push(context,
                      new MaterialPageRoute(builder: (BuildContext context) {
                    return pageWidget;
                  }));
                }),
          ],
        ),
      ),
    );
  }
}
