import 'package:flutter/material.dart';
import 'package:robust_image/robust_image.dart';
import 'package:robust_image_app/common/item_builder.dart';
import 'package:robust_image_app/common/tu_chong_repository.dart';
import 'package:robust_image_app/common/tu_chong_source.dart';
import 'package:robust_image_app/main.dart';

import 'common/simple_repository.dart';

class ImageGridDemo extends StatefulWidget {
  ImageGridDemo({this.useSimpleUrl = true});
  final bool useSimpleUrl;
  @override
  _ImageGridDemoState createState() => _ImageGridDemoState();
}

enum TuChongLoadState { loading, loaded, failed }

class _ImageGridDemoState extends State<ImageGridDemo> {
  TuChongRepository listSourceRepository = TuChongRepository();
  TuChongLoadState _curLoadState;
  List<TuChongItem> _imageDatas;
  List<String> _imageUrls;

  void _loadData() async {
    bool result = false;
    setState(() {
      _curLoadState = TuChongLoadState.loading;
    });
    try {
      if (widget.useSimpleUrl) {
        _imageUrls = await loadRemoteImageList();
        if (_imageUrls != null) {
          result = true;
        }
      } else {
        result = await listSourceRepository.loadData();
      }
      if (result) _imageDatas = listSourceRepository.toList();
    } catch (e) {
      print(e);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _curLoadState =
          result ? TuChongLoadState.loaded : TuChongLoadState.failed;
    });
  }

  @override
  void initState() {
    print('$this initState');
    _loadData();
    super.initState();
  }

  @override
  void dispose() {
    print('$this dispose');
    listSourceRepository.dispose();
    super.dispose();
  }

  Widget _buildLoad(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Center(
        child: (_curLoadState == TuChongLoadState.loading)
            ? CircularProgressIndicator()
            : RaisedButton(
                child: Text('重试'),
                onPressed: () => _loadData(),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_curLoadState == TuChongLoadState.loaded) {
      return Material(
        child: Column(
          children: <Widget>[
            AppBar(
              title: Text("ImageGridDemo"),
            ),
            Text(
              'Items:${(widget.useSimpleUrl) ? _imageUrls.length : (_imageDatas?.length ?? 0)}',
              style: TextStyle(fontSize: 16),
            ),
            Expanded(
              child: Scrollbar(
                child: ExcludeSemantics(
                  excluding: true,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4),
                    cacheExtent: 2,
                    itemCount: (widget.useSimpleUrl)
                        ? _imageUrls.length
                        : _imageDatas.length,
                    itemBuilder: (context, index) {
                      Widget child;
                      String url;
                      if (widget.useSimpleUrl) {
                        url = _imageUrls[index];
                        child = ItemBuilder.urlItemBuilder(
                            context, _imageUrls[index], index);
                      } else {
                        url = _imageDatas[index].imageUrl;
                        child = ItemBuilder.itemBuilder(
                            context, _imageDatas[index], index);
                      }
                      return GestureDetector(
                        child: child,
                        onTap: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            return Container(
                                color: Colors.black,
                                child: Center(
                                  child: RobustImage(
                                    loadStateWidgetResolver:
                                        resolveLoadStateChanged,
                                    image: RobustImageProvider(
                                      imageEngine,
                                      (_, configuration) =>
                                          RenderRequest<RobustImageKey>(
                                              module: imageModule,
                                              renderTarget: ImageRender(
                                                  RobustImageKey.source(url),
                                                  configuration),
                                              config: RequestConfig(
                                                  useDiskCache: true,
                                                  useMemroyCache: true)),
                                      tag: RobustImageKey.source(url),
                                    ),
                                  ),
                                ));
                          }));
                        },
                      );
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      );
    } else {
      return _buildLoad(context);
    }
  }
}
