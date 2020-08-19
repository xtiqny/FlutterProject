import 'package:flutter/material.dart';
import 'package:robust_image/robust_image.dart';
import 'package:robust_image_app/common/tu_chong_source.dart';
import 'package:robust_image_app/main.dart';

Widget resolveLoadStateChanged(BuildContext context,
    RobustImageProvider imageProvider, LoadState loadState) {
  if (loadState == LoadState.loading) {
    return Container(
      color: const Color(0xFFCCCCCC),
//      width: 128,
//      height: 128,
//      child: Center(child: CircularProgressIndicator()),
    );
  } else {
    return Container(
      color: const Color(0xFFEFEFEF),
//      width: 128,
//      height: 128,
      child: Center(child: Icon(Icons.cloud_off)),
    );
  }
}

class ItemBuilder {
  static Widget urlItemBuilder(BuildContext context, String url, int index) {
    return Container(
//      height: 128,
      child: Stack(
        children: <Widget>[
          Positioned(
              child: Center(
            child: RobustImage(
              loadStateWidgetResolver: resolveLoadStateChanged,
              image: RobustImageProvider(
                imageEngine,
                (_, configuration) => RenderRequest<RobustImageKey>(
                    module: imageModule,
                    renderTarget:
                        ImageRender(RobustImageKey.source(url), configuration),
                    config: RequestConfig(
                        useDiskCache: true, useMemroyCache: true)),
                tag: RobustImageKey.source(url),
              ),
              fit: BoxFit.cover,
//              width: 64,
//              height: 64, //double.infinity,
            ),
          )),
//          Positioned(
//            left: 0.0,
//            right: 0.0,
//            bottom: 0.0,
//            child: Container(
//              padding: EdgeInsets.only(left: 8.0, right: 8.0),
//              height: 40.0,
//              color: Colors.grey.withOpacity(0.5),
//              alignment: Alignment.center,
//              child: Row(
//                mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                crossAxisAlignment: CrossAxisAlignment.center,
//                children: <Widget>[
//                  Row(
//                    children: <Widget>[
//                      Text(
//                        url.substring(url.length >= 12 ? url.length - 12 : 0),
//                        style: TextStyle(color: Colors.white, fontSize: 12),
//                      )
//                    ],
//                  ),
//                ],
//              ),
//            ),
//          )
        ],
      ),
    );
  }

  static Widget itemBuilder(BuildContext context, TuChongItem item, int index) {
    return Container(
//      height: 128,
      child: Stack(
        children: <Widget>[
          Positioned(
              child: Center(
            child: RobustImage(
              loadStateWidgetResolver: resolveLoadStateChanged,
              image: RobustImageProvider(
                imageEngine,
                (_, configuration) => RenderRequest<RobustImageKey>(
                    module: imageModule,
                    renderTarget: ImageRender(
                        RobustImageKey.source(item.imageUrl), configuration),
                    config: RequestConfig(
                        useDiskCache: true, useMemroyCache: true)),
                tag: RobustImageKey.source(item.imageUrl),
              ),
              fit: BoxFit.cover,
//              width: 128,
//              height: double.infinity,
            ),
          )
//            child: ExtendedImage.network(
//              item.imageUrl,
//              fit: BoxFit.cover,
//              width: 128, //double.infinity,
//              //height: 200.0,
//              height: double.infinity,
//            ),
              ),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: Container(
              padding: EdgeInsets.only(left: 8.0, right: 8.0),
              height: 40.0,
              color: Colors.grey.withOpacity(0.5),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
//                      Icon(
//                        Icons.comment,
//                        color: Colors.amberAccent,
//                      ),
                      Text(
                        item.imageUrl.substring(item.imageUrl.length >= 12
                            ? item.imageUrl.length - 12
                            : 0), //item.comments.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      )
                    ],
                  ),
//                  Row(
//                    children: <Widget>[
//                      Icon(
//                        Icons.favorite,
//                        color: Colors.deepOrange,
//                      ),
//                      Text(
//                        item.favorites.toString(),
//                        style: TextStyle(color: Colors.white, fontSize: 12),
//                      )
//                    ],
//                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
