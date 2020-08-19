import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:robust_image/src/robust_image_engine.dart';
import 'package:robust_image/src/robust_image_module.dart';
import 'package:robust_image/src/robust_image_provider.dart';

enum LoadState { loading, completed, failed }

typedef LoadStateWidgetResolver = Widget Function(BuildContext context,
    RobustImageProvider imageProvider, LoadState loadState);

typedef LoadStateChangeCallback = void Function(
    RobustImageProvider imageProvider, LoadState loadState);

/// A widget that displays an image.
///
/// Several constructors are provided for the various ways that an image can be
/// specified:
///
///  * [new Image], for obtaining an image from an [ImageProvider].
///  * [new Image.asset], for obtaining an image from an [AssetBundle]
///    using a key.
///  * [new Image.network], for obtaining an image from a URL.
///  * [new Image.file], for obtaining an image from a [File].
///  * [new Image.memory], for obtaining an image from a [Uint8List].
///
/// The following image formats are supported: {@macro flutter.dart:ui.imageFormats}
///
/// To automatically perform pixel-density-aware asset resolution, specify the
/// image using an [AssetImage] and make sure that a [MaterialApp], [WidgetsApp],
/// or [MediaQuery] widget exists above the [Image] widget in the widget tree.
///
/// The image is painted using [paintImage], which describes the meanings of the
/// various fields on this class in more detail.
///
/// See also:
///
///  * [Icon], which shows an image from a font.
///  * [new Ink.image], which is the preferred way to show an image in a
///    material application (especially if the image is in a [Material] and will
///    have an [InkWell] on top of it).
class RobustImage extends StatefulWidget {
  /// Creates a widget that displays an image.
  ///
  /// The [image], [alignment], [repeat], and [matchTextDirection] arguments
  /// must not be null.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  ///
  /// Use [filterQuality] to change the quality when scaling an image.
  /// Use the [FilterQuality.low] quality setting to scale the image,
  /// which corresponds to bilinear interpolation, rather than the default
  /// [FilterQuality.none] which corresponds to nearest-neighbor.
  ///
  /// If [excludeFromSemantics] is true, then [semanticLabel] will be ignored.
  const RobustImage(
      {Key key,
      @required this.image,
      this.semanticLabel,
      this.excludeFromSemantics = false,
      this.width,
      this.height,
      this.color,
      this.colorBlendMode,
      this.fit,
      this.alignment = Alignment.center,
      this.repeat = ImageRepeat.noRepeat,
      this.centerSlice,
      this.matchTextDirection = false,
      this.gaplessPlayback = false,
      this.filterQuality = FilterQuality.low,
      this.loadStateWidgetResolver,
      this.loadStateChangeCallback})
      : assert(image != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(filterQuality != null),
        assert(matchTextDirection != null),
        super(key: key);

  final LoadStateWidgetResolver loadStateWidgetResolver;

  final LoadStateChangeCallback loadStateChangeCallback;

  /// The image to display.
  final RobustImageProvider image;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  ///
  /// It is strongly recommended that either both the [width] and the [height]
  /// be specified, or that the widget be placed in a context that sets tight
  /// layout constraints, so that the image does not change size as it loads.
  /// Consider using [fit] to adapt the image's rendering to fit the given width
  /// and height if the exact image dimensions are not known in advance.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  ///
  /// It is strongly recommended that either both the [width] and the [height]
  /// be specified, or that the widget be placed in a context that sets tight
  /// layout constraints, so that the image does not change size as it loads.
  /// Consider using [fit] to adapt the image's rendering to fit the given width
  /// and height if the exact image dimensions are not known in advance.
  final double height;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color color;

  /// Used to set the [FilterQuality] of the image.
  ///
  /// Use the [FilterQuality.low] quality setting to scale the image with
  /// bilinear interpolation, or the [FilterQuality.none] which corresponds
  /// to nearest-neighbor.
  final FilterQuality filterQuality;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode colorBlendMode;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while an
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// To display a subpart of an image, consider using a [CustomPainter] and
  /// [Canvas.drawImageRect].
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect centerSlice;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with images in right-to-left environments, for
  /// images that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip images with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// Whether to continue showing the old image (true), or briefly show nothing
  /// (false), when the image provider changes.
  final bool gaplessPlayback;

  /// A Semantic description of the image.
  ///
  /// Used to provide a description of the image to TalkBack on Android, and
  /// VoiceOver on iOS.
  final String semanticLabel;

  /// Whether to exclude this image from semantics.
  ///
  /// Useful for images which do not contribute meaningful information to an
  /// application.
  final bool excludeFromSemantics;

  @override
  _RobustImageState createState() => _RobustImageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageProvider>('image', image));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties
        .add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(EnumProperty<BlendMode>('colorBlendMode', colorBlendMode,
        defaultValue: null));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(DiagnosticsProperty<AlignmentGeometry>(
        'alignment', alignment,
        defaultValue: null));
    properties.add(EnumProperty<ImageRepeat>('repeat', repeat,
        defaultValue: ImageRepeat.noRepeat));
    properties.add(DiagnosticsProperty<Rect>('centerSlice', centerSlice,
        defaultValue: null));
    properties.add(FlagProperty('matchTextDirection',
        value: matchTextDirection, ifTrue: 'match text direction'));
    properties.add(
        StringProperty('semanticLabel', semanticLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>(
        'this.excludeFromSemantics', excludeFromSemantics));
    properties.add(EnumProperty<FilterQuality>('filterQuality', filterQuality));
  }
}

class _RobustImageState extends State<RobustImage> {
  ImageStream _imageStream;
  ImageInfo _imageInfo;
  bool _isListeningToStream = false;
  bool _invertColors;
  bool _initResolved = false;

  _RobustImageState() : super() {
    _imageStreamListener =
        ImageStreamListener(_handleImageChanged, onError: _handleLoadFailed);
  }

  LoadState _curLoadState;
  ImageStreamListener _imageStreamListener;

  bool voteImageStreamRetain(
      RobustImageKey key, ImageStreamCompleter completer) {
    final curKey = widget.image.request?.key;
    return (mounted && curKey == key && _imageStream?.completer == completer);
  }

  @override
  void initState() {
    _setLoadState(LoadState.loading);
    widget.image.engine.addImageStreamRetainVote(voteImageStreamRetain);
    _initResolved = false;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _invertColors = MediaQuery.of(context, nullOk: true)?.invertColors ??
        SemanticsBinding.instance.accessibilityFeatures.invertColors;
    if (!_initResolved) {
      _resolveImage();
      _initResolved = true;
      setState(() {
        _setLoadState(LoadState.loading);
      });
    }

    if (TickerMode.of(context))
      _listenToStream();
    else
      _stopListeningToStream();

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(RobustImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.image.engine, oldWidget.image.engine)) {
      oldWidget.image.engine.removeImageStreamRetainVote(voteImageStreamRetain);
      widget.image.engine.addImageStreamRetainVote(voteImageStreamRetain);
    }
    if (widget.image != oldWidget.image) {
//      debugPrint(
//          'didUpdateWidget: old: ${oldWidget.image.request?.key?.renderKey} new:${widget.image.request?.key?.renderKey}');
//      widget.image.request?.cancel();
      _resolveImage();
    }
  }

  @override
  void reassemble() {
    debugPrint('... reassemble');
    _resolveImage(); // in case the image cache was flushed
    super.reassemble();
  }

  void _resolveImage([bool reload = false]) {
    if (reload) {
      _evictMemCache();
    }
    final ImageStream newStream =
        widget.image.resolve(createLocalImageConfiguration(
      context,
      size: widget.width != null && widget.height != null
          ? Size(widget.width, widget.height)
          : null,
    ));
    assert(newStream != null);

    if (_imageInfo != null && !reload && _imageStream?.key == newStream?.key) {
      setState(() {
        _setLoadState(LoadState.completed);
      });
    }

    _updateSourceStream(newStream);
  }

  void _setLoadState(LoadState loadState) {
    final LoadState oldState = _curLoadState;
    _curLoadState = loadState;
    if (_curLoadState != oldState) {
      widget.loadStateChangeCallback?.call(widget.image, _curLoadState);
    }
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _imageInfo = imageInfo;
      _setLoadState(
          (imageInfo != null) ? LoadState.completed : LoadState.failed);
    });
  }

  // Update _imageStream to newStream, and moves the stream listener
  // registration from the old stream to the new stream (if a listener was
  // registered).
  void _updateSourceStream(ImageStream newStream, [bool reload = false]) {
    if (_imageStream?.key == newStream?.key) return;

    if (_isListeningToStream) _imageStream.removeListener(_imageStreamListener);

    if (!widget.gaplessPlayback)
      setState(() {
        _imageInfo = null;
        _setLoadState(LoadState.loading);
      });

    _imageStream = newStream;
    if (_isListeningToStream) _imageStream.addListener(_imageStreamListener);
  }

  void _listenToStream() {
    if (_isListeningToStream) return;
    _imageStream.addListener(_imageStreamListener);
    _isListeningToStream = true;
  }

  void _stopListeningToStream() {
    if (!_isListeningToStream) return;
    _imageStream.removeListener(_imageStreamListener);
    _isListeningToStream = false;
  }

  void _handleLoadFailed(dynamic exception, StackTrace stackTrace) {
    if (!mounted) {
      return;
    }
    if (exception is CancelationException) {
      print(
          'RobustImageState receive a CancelationException but it is still active, retry again.');
      Future<void>(() {
        if (mounted && context != null) _resolveImage(true);
      });
      return;
    } else {
      setState(() {
        _setLoadState(LoadState.failed);
      });
    }
  }

  void _evictMemCache() {
    RenderRequest request = widget.image.request;
    RobustImageKey key = request?.key;
    if (key != null) request?.module?.imageCache?.evict(key);
  }

  @override
  void dispose() {
    assert(_imageStream != null);
    widget.image.engine.removeImageStreamRetainVote(voteImageStreamRetain);
    _stopListeningToStream();
//    debugPrint('dispose: request:${widget.image.request?.key?.renderKey}');
    // Stop any pending task
//    widget.image.request?.cancel();
    if (widget.image.request != null) {
      widget.image.engine.discard(widget.image.request);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (_curLoadState == LoadState.completed) {
      img = _buildRawImage(context);
    } else {
      if (widget.loadStateWidgetResolver != null &&
          _curLoadState != LoadState.completed) {
        img = widget.loadStateWidgetResolver(
            context, widget.image, _curLoadState);
      }
      if (img == null) {
        img = Container();
      }
    }

    if (widget.excludeFromSemantics) return img;
    return Semantics(
      container: widget.semanticLabel != null,
      image: true,
      label: widget.semanticLabel == null ? '' : widget.semanticLabel,
      child: img,
    );
  }

  Widget _buildRawImage(BuildContext context) {
    final RawImage image = RawImage(
      image: _imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: _imageInfo?.scale ?? 1.0,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
      invertColors: _invertColors,
      filterQuality: widget.filterQuality,
    );
    return image;
  }

  void _reloadImage() {
    _resolveImage(true);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<ImageStream>('stream', _imageStream));
    description.add(DiagnosticsProperty<ImageInfo>('pixels', _imageInfo));
  }
}
