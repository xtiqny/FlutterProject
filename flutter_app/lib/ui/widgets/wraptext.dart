import 'dart:ui' as ui show Gradient, Shader, TextBox;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 支持以字符为粒度的自动换行的文本控件
/// 类似[Text]，但提供了详细的ellipsis模式，包括start、middle、end
/// 另外该类对超出最大允许宽度的字符串自动进行换行处理（wrap）
class WrapText extends Text {
  WrapText(
    String data, {
    Key key,
    TextStyle style,
    StrutStyle strutStyle,
    TextAlign textAlign,
    Locale locale,
    TextOverflow overflow,
    EllipsisMode ellipsisMode,
    double textScaleFactor,
    int maxLines,
    String semanticsLabel,
  })  : ellipsisMode =
            (overflow == TextOverflow.ellipsis) ? ellipsisMode : null,
        super(data,
            key: key,
            style: style,
            strutStyle: strutStyle,
            textAlign: textAlign,
            textDirection: TextDirection.ltr,
            locale: locale,
            softWrap: false,
            overflow: ((overflow == null) ? TextOverflow.clip : overflow),
            textScaleFactor: textScaleFactor,
            maxLines: maxLines,
            semanticsLabel: semanticsLabel);
  final EllipsisMode ellipsisMode;

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = style;
    if (style == null || style.inherit)
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    if (MediaQuery.boldTextOverride(context))
      effectiveTextStyle = effectiveTextStyle
          .merge(const TextStyle(fontWeight: FontWeight.bold));
    Widget result = RawWrapText(
      textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
//      textDirection:
//          textDirection, // RichText uses Directionality.of to obtain a default if this is null.
      locale:
          locale, // RichText uses Localizations.localeOf to obtain a default if this is null
//      softWrap: softWrap ?? defaultTextStyle.softWrap,
      overflow: overflow ?? defaultTextStyle.overflow,
      ellipsisMode: ellipsisMode,
      textScaleFactor: textScaleFactor ?? MediaQuery.textScaleFactorOf(context),
      maxLines: maxLines ?? defaultTextStyle.maxLines,
      strutStyle: strutStyle,
      style: effectiveTextStyle,
      text: data,
    );
    if (semanticsLabel != null) {
      result = Semantics(
          textDirection: textDirection,
          label: semanticsLabel,
          child: ExcludeSemantics(
            child: result,
          ));
    }
    return result;
  }
}

/// 支持以字符为粒度的自动换行的基础文本控件
/// 一般情况下，应使用WrapText以和默认属性结合使用。
///
/// {@tool sample}
///
/// ```dart
/// RawPlainText(
///   text: 'Hello'
/// )
/// ```
/// {@end-tool}
///
/// See also:
///.
///  * [WrapText]
class RawWrapText extends LeafRenderObjectWidget {
  /// Creates a paragraph of rich text.
  ///
  /// The [text], [textAlign], [softWrap], [overflow], and [textScaleFactor]
  /// arguments must not be null.
  ///
  /// The [maxLines] property may be null (and indeed defaults to null), but if
  /// it is not null, it must be greater than zero.
  ///
  /// The [textDirection], if null, defaults to the ambient [Directionality],
  /// which in that case must not be null.
  const RawWrapText({
    Key key,
    @required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.clip,
    this.ellipsisMode = EllipsisMode.end,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.locale,
    this.strutStyle,
  })  : assert(text != null),
        assert(textAlign != null),
        assert(overflow != null),
        assert(textScaleFactor != null),
        assert(maxLines == null || maxLines > 0),
        super(key: key);
  final EllipsisMode ellipsisMode;

  /// The text to display in this widget.
  final String text;

  final TextStyle style;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  final int maxLines;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [WrapParagraph.locale] for more information.
  final Locale locale;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle strutStyle;

  @override
  WrapParagraph createRenderObject(BuildContext context) {
    return WrapParagraph(
      TextSpan(style: style, text: text),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      softWrap: false,
      overflow: overflow,
      ellipsisMode: ellipsisMode,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      strutStyle: strutStyle,
      locale: locale ?? Localizations.localeOf(context, nullOk: true),
    );
  }

  @override
  void updateRenderObject(BuildContext context, WrapParagraph renderObject) {
//    debugPrint('updateRenderObject:$text');
    renderObject
      ..text = TextSpan(style: style, text: text)
      ..textAlign = textAlign
      ..textDirection = TextDirection.ltr
      ..softWrap = false
      ..overflow = overflow
      .._ellipsisMode = ellipsisMode
      ..textScaleFactor = textScaleFactor
      ..maxLines = maxLines
      ..strutStyle = strutStyle
      ..locale = locale ?? Localizations.localeOf(context, nullOk: true);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign,
        defaultValue: TextAlign.start));
//    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
//        defaultValue: null));
//    properties.add(FlagProperty('softWrap',
//        value: softWrap,
//        ifTrue: 'wrapping at box width',
//        ifFalse: 'no wrapping except at line break characters',
//        showName: true));
    properties.add(EnumProperty<TextOverflow>('overflow', overflow,
        defaultValue: TextOverflow.clip));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
    properties.add(IntProperty('maxLines', maxLines, ifNull: 'unlimited'));
    properties.add(StringProperty('text', text));
  }
}

const String _kEllipsis = '\u2026';
//const String _kEllipsis = ' ... ';

enum EllipsisMode { start, middle, end }

class _WrapLine {
  _WrapLine(this.text, this.rawLine, this.endl)
      : assert(text != null && rawLine != null);
  final String text;
  final int rawLine;
  final bool endl;
}

class _CharPos {
  _CharPos(this.offset, this.boundBox);
  final int offset;
  final TextBox boundBox;
}

/// A render object that displays a paragraph of text
class WrapParagraph extends RenderBox {
  /// Creates a paragraph render object.
  ///
  /// The [text], [textAlign], [textDirection], [overflow], [softWrap], and
  /// [textScaleFactor] arguments must not be null.
  ///
  /// The [maxLines] property may be null (and indeed defaults to null), but if
  /// it is not null, it must be greater than zero.
  WrapParagraph(
    TextSpan text, {
    TextAlign textAlign = TextAlign.start,
    @required TextDirection textDirection,
    bool softWrap = false,
    TextOverflow overflow = TextOverflow.clip,
    EllipsisMode ellipsisMode = EllipsisMode.end,
    double textScaleFactor = 1.0,
    int maxLines,
    Locale locale,
    StrutStyle strutStyle,
  })  : assert(text != null),
        assert(text.text != null && text.children == null),
        assert(text.debugAssertIsValid()),
        assert(textAlign != null),
        assert(textDirection != null),
        assert(softWrap != null),
        assert(overflow != null),
        assert(textScaleFactor != null),
        assert(maxLines == null || maxLines > 0),
        _softWrap = softWrap,
        _overflow = overflow,
        _textPainter = TextPainter(
          text: text,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          ellipsis: overflow == TextOverflow.ellipsis ? _kEllipsis : null,
          locale: locale,
          strutStyle: strutStyle,
        ),
        _ellipsisMode = ellipsisMode,
        _ellipsisPainter = TextPainter(
          text: TextSpan(text: _kEllipsis, style: text.style),
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
          maxLines: 1,
          ellipsis: null,
          locale: locale,
          strutStyle: strutStyle,
        ) {
    _updateRawLines();
  }

  void _updateRawLines() {
    var str = text.text;
    _rawLines.clear();
    _rawLines.addAll(str.split("\n"));
  }

  final TextPainter _textPainter;
  TextPainter _ellipsisPainter;
  EllipsisMode _ellipsisMode;
  EllipsisMode get ellipsisMode => _ellipsisMode;
  set ellipsisMode(EllipsisMode mode) {
    _ellipsisMode = mode;
    _lastMaxWidth = -1;
    _lastMinWidth = -1;
    markNeedsLayout();
  }

  final _rawLines = <String>[];
  final _wrapLines = <_WrapLine>[];
  double _lastMinWidth = -1;
  double _lastMaxWidth = -1;

  /// The text to display
  TextSpan get text => _textPainter.text;
  set text(TextSpan value) {
    assert(value != null);
    switch (_textPainter.text.compareTo(value)) {
      case RenderComparison.identical:
      case RenderComparison.metadata:
        return;
      case RenderComparison.paint:
        _textPainter.text = value;
        _lastMaxWidth = -1;
        _lastMinWidth = -1;
        _ellipsisPainter.text = TextSpan(style: value.style, text: _kEllipsis);
        _updateRawLines();
        markNeedsPaint();
        markNeedsSemanticsUpdate();
        break;
      case RenderComparison.layout:
        _textPainter.text = value;
        _overflowShader = null;
        _lastMaxWidth = -1;
        _lastMinWidth = -1;
        _updateRawLines();
        markNeedsLayout();
        break;
    }
  }

  /// How the text should be aligned horizontally.
  TextAlign get textAlign => _textPainter.textAlign;
  set textAlign(TextAlign value) {
    assert(value != null);
    if (_textPainter.textAlign == value) return;
    _textPainter.textAlign = value;
    _lastMaxWidth = -1;
    _lastMinWidth = -1;
    markNeedsPaint();
  }

  /// The directionality of the text.
  ///
  /// This decides how the [TextAlign.start], [TextAlign.end], and
  /// [TextAlign.justify] values of [textAlign] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// This must not be null.
  TextDirection get textDirection => _textPainter.textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textPainter.textDirection == value) return;
    _textPainter.textDirection = value;
    _lastMaxWidth = -1;
    _lastMinWidth = -1;
    markNeedsLayout();
  }

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was
  /// unlimited horizontal space.
  ///
  /// If [softWrap] is false, [overflow] and [textAlign] may have unexpected
  /// effects.
  bool get softWrap => _softWrap;
  bool _softWrap;
  set softWrap(bool value) {
    assert(value != null);
    if (_softWrap == value) return;
    _softWrap = value;
    _lastMaxWidth = -1;
    _lastMinWidth = -1;
    markNeedsLayout();
  }

  /// How visual overflow should be handled.
  TextOverflow get overflow => _overflow;
  TextOverflow _overflow;
  set overflow(TextOverflow value) {
    assert(value != null);
    if (_overflow == value) return;
    _overflow = value;
    _textPainter.ellipsis = value == TextOverflow.ellipsis ? _kEllipsis : null;
    _lastMaxWidth = -1;
    _lastMinWidth = -1;
    markNeedsLayout();
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  double get textScaleFactor => _textPainter.textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_textPainter.textScaleFactor == value) return;
    _textPainter.textScaleFactor = value;
    _overflowShader = null;
    _lastMaxWidth = -1;
    _lastMinWidth = -1;
    markNeedsLayout();
  }

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow] and [softWrap].
  int get maxLines => _textPainter.maxLines;

  /// The value may be null. If it is not null, then it must be greater than zero.
  set maxLines(int value) {
    assert(value == null || value > 0);
    if (_textPainter.maxLines == value) return;
    _textPainter.maxLines = value;
    _overflowShader = null;
    _lastMaxWidth = -1;
    _lastMinWidth = -1;
    markNeedsLayout();
  }

  /// Used by this paragraph's internal [TextPainter] to select a locale-specific
  /// font.
  ///
  /// In some cases the same Unicode character may be rendered differently depending
  /// on the locale. For example the '骨' character is rendered differently in
  /// the Chinese and Japanese locales. In these cases the [locale] may be used
  /// to select a locale-specific font.
  Locale get locale => _textPainter.locale;

  /// The value may be null.
  set locale(Locale value) {
    if (_textPainter.locale == value) return;
    _textPainter.locale = value;
    _overflowShader = null;
    _lastMaxWidth = -1;
    _lastMinWidth = -1;
    markNeedsLayout();
  }

  /// {@macro flutter.painting.textPainter.strutStyle}
  StrutStyle get strutStyle => _textPainter.strutStyle;

  /// The value may be null.
  set strutStyle(StrutStyle value) {
    if (_textPainter.strutStyle == value) return;
    _lastMaxWidth = -1;
    _lastMinWidth = -1;
    _textPainter.strutStyle = value;
    _overflowShader = null;
    _lastMaxWidth = -1;
    _lastMinWidth = -1;
    markNeedsLayout();
  }

  TextBox _getBoundBox(TextPainter painter, int offset) {
    var sel = TextSelection(
        baseOffset: offset,
        extentOffset: painter.getOffsetAfter(offset) ?? offset);
    var boxes = painter.getBoxesForSelection(sel);
    if (boxes != null && boxes.isNotEmpty) {
      return boxes.first;
    }
    return null;
  }

  _CharPos _getBoundPosition(TextPainter painter, Offset offset) {
    var pos = painter.getPositionForOffset(offset);
    var index = pos.offset;
    TextBox box;
    box = _getBoundBox(painter, index);
    if (box == null || (box.left > offset.dx || box.right <= offset.dx)) {
      if (index > 0 && offset.dx >= 0 && offset.dx < painter.width) {
        // 当前的offset.dx有可能更加靠近后面的字符index，
        // 由于我们希望返回offset.dx当前所在的index，因此检查上一个
        // 字符看是否适合
//        debugPrint(
//            '_getBoundBox returns $box and expected offset=$offset, should try prev of $index');
        index = painter.getOffsetBefore(index) ?? index;
        box = _getBoundBox(painter, index);
        if (box != null && (box.left > offset.dx || box.right <= offset.dx)) {
          // offset.dx仍然不在此字符中
          box = null;
        }
      } else {
        box = null;
      }
    }
    return _CharPos(index, box);
  }

  void _replaceEllipsisMiddle(int index,
      {double minWidth = 0.0, double maxWidth = double.infinity}) {
//    debugPrint(
//        '_replaceEllipsisMiddle(index:$index, minWith:$minWidth, maxWidth:$maxWidth)');
    int linesCount = _wrapLines.length;
    assert(index < linesCount);
    if (index < 0 || index >= linesCount) {
      return;
    }
    var line = _wrapLines[index];
    TextStyle textStyle = _textPainter.text.style;
    _ellipsisPainter.layout();
    double ellipsisWidth = _ellipsisPainter.width;
    int start = 0;
    int end = 0;
    _textPainter.text = TextSpan(style: textStyle, text: line.text);
    _textPainter.layout(minWidth: minWidth);
    double textWidth = _textPainter.width;

    // 由于中间行是由两行合并，首先检查行是否超出 maxWidth
    _CharPos charpos;
    var str = line.text;
    end = str.length;
    double half = maxWidth / 2;
    // 第一行的最大长度为maxWidth的一半再减去半个ellipsis
    double usedWidth = half - ellipsisWidth / 2;
    if (usedWidth >= 0 && textWidth >= ellipsisWidth) {
      if (textWidth <= usedWidth) {
        // 该行可以完整显示在屏幕上，_kEllipsis直接显示在该行中间
        usedWidth = (textWidth - ellipsisWidth) / 2;
      }
      charpos = _getBoundPosition(_textPainter, Offset(usedWidth, 0));
      if (charpos?.boundBox != null) {
        // usedWidth的位置位于该字符中间，忽略该字符确保
        // 总长度不会超过usedWidth
        end = charpos.offset;
//        debugPrint('1st break at index $end, boundBox=${charpos.boundBox}');
//        debugPrint(
//            'expected usedWidth=$usedWidth, actual usedWidth=${charpos.boundBox.left}');
        assert(usedWidth >= charpos.boundBox.left);
        // 更新实际使用长度
        usedWidth = charpos.boundBox.left;
      }
      str = str.substring(start, end);
      // 在第一行截取的尾部加上ellipsis
      str = str + _kEllipsis;
      usedWidth += ellipsisWidth;
      //debugPrint('Final 1st:$str, usedWidth=$usedWidth');

      double remainWidth =
          ((maxWidth > textWidth) ? textWidth : maxWidth) - usedWidth;
      start = 0;
      end = line.text.length;
      if (textWidth > remainWidth) {
        // 带合并的第二行长度超出剩余的可用宽度
        // 从最后面截取不多于remainWidth长的字符串
        double delta = textWidth - remainWidth;
        //debugPrint(
        //    '2nd textWidth=$textWidth, remainWidth=$remainWidth, delta=$delta');
        charpos = _getBoundPosition(_textPainter, Offset(delta, 0));
        assert(charpos.boundBox != null);
        start = charpos.offset;
        //debugPrint('2nd start=$start, boundBox:${charpos.boundBox}');
        if ((charpos.boundBox?.right ?? 0) > delta && start < end) {
          // delta的位置刚好在此字符中间，因此截取从下一字符开始
          start = _textPainter.getOffsetAfter(start) ?? start;
          //debugPrint('2nd start boundBox.right > delta, so start=$start');
        }
      }
      str = str + line.text.substring(start, end);
    } else {
      //debugPrint('No enough room for ellipsis.');
      // 整行用空字符串代替
      str = "";
    }
    // 合并line和subline
    line = _WrapLine(str, line.rawLine, line.endl);
    _wrapLines[index] = line;
//    debugPrint('替换后:${line.text}');
  }

  void _replaceEllipsis(int index, EllipsisMode mode,
      {double minWidth = 0.0, double maxWidth = double.infinity}) {
//    debugPrint(
//        '_replaceEllipsis(index:$index, mode:$mode, minWith:$minWidth, maxWidth:$maxWidth)');
    assert(index < _wrapLines.length);
    if (index < 0 || index >= _wrapLines.length) {
      return;
    }
    if (EllipsisMode.middle == mode) {
      _replaceEllipsisMiddle(index, minWidth: minWidth, maxWidth: maxWidth);
      return;
    }
    var line = _wrapLines[index];
    TextStyle textStyle = _textPainter.text.style;
    _ellipsisPainter.layout();
    double ellipsisWidth = _ellipsisPainter.width;
    Offset offset;
    int start = 0;
    int end = 0;
    _textPainter.text = TextSpan(style: textStyle, text: line.text);
    _textPainter.layout(minWidth: minWidth);
    double textWidth = _textPainter.width;
    switch (mode) {
      case EllipsisMode.start:
        if (textWidth <= maxWidth) {
          offset = Offset(ellipsisWidth, 0);
        } else {
          offset = Offset(textWidth - maxWidth + ellipsisWidth, 0);
        }
        var pos = _getBoundPosition(_textPainter, offset);
        end = (pos.offset + 1).clamp(0, line.text.length);
        break;
      case EllipsisMode.end:
        offset = Offset(
            ((textWidth < maxWidth) ? textWidth : maxWidth) - ellipsisWidth, 0);
        var pos = _getBoundPosition(_textPainter, offset);
        start = pos.offset;
        end = line.text.length;
        break;
      default:
        return;
    }
    int num = end - start;
    if (num >= 0) {
      // 把字符串[start, end]部分替换为_kEllipsis
    } else {
      // 把字符串从start开始替换为_kEllipsis
      end = null;
    }
    line = _WrapLine(line.text.replaceRange(start, end, _kEllipsis),
        line.rawLine, line.endl);
    _wrapLines[index] = line;
//    print('start=$start, end=$end, 替换后:${line.text}');
  }

  void _joinAndLayout(TextStyle textStyle, {double minWidth = 0.0}) {
    // 合并所有处理后的行，再计算一次布局
    StringBuffer buffer = StringBuffer();
    bool addLF = false;
    _wrapLines.forEach((l) {
      if (addLF) {
        buffer.write("\n");
      }
      buffer.write(l.text);
      addLF = true;
    });
    _textPainter.text = TextSpan(style: textStyle, text: buffer.toString());
    // 虽然使用 double.infinity，但是由于已经经过处理，宽度实际能够适应 maxWidth
    // 这里用 double.infinity 只是保险处理，保证不会再换行
    _textPainter.layout(minWidth: minWidth, maxWidth: double.infinity);
  }

  void _layoutWrap({double minWidth = 0.0, double maxWidth = double.infinity}) {
    if (_lastMaxWidth < 0 ||
        minWidth != _lastMinWidth ||
        maxWidth != _lastMaxWidth) {
      // 布局的测量宽度发生改变
//      debugPrint(
//          'layout changed: lastmin=$_lastMinWidth, lastmax=$_lastMaxWidth, min=$minWidth, max=$maxWidth, overflow=$overflow');
      _wrapLines.clear();
      TextStyle textStyle = _textPainter.text.style;
      int rawLine = 0;
      int processedLines = 0;
      StringBuffer buffer = StringBuffer();
      bool processTruncation = false;
      for (var line in _rawLines) {
        int end = 0;
//        debugPrint('---> Start process line:$line');
        do {
//          debugPrint('Remains:$line');
          _textPainter.text = TextSpan(style: textStyle, text: line);
          _textPainter.layout(minWidth: minWidth, maxWidth: double.infinity);

          var charpos = _getBoundPosition(_textPainter, Offset(maxWidth, 0));
          end = charpos.offset;
          if (end == null || end > line.length) {
            end = line.length;
//            debugPrint(
//                'Last segment to process. segment lenght=$end, offset=${charpos.offset}, boundBox=${charpos.boundBox}');
            charpos = null;
          } else if (end == 0 && charpos.boundBox != null && line.isNotEmpty) {
//            debugPrint('No enough room for render at least one char!');
            // 第0个字符用空字符串代替插入到_wrapLines中作为一行，原line中
            // 将第0个字符删除以避免死循环
            int next = _textPainter.getOffsetAfter(0) ?? 0;
            if (next <= 0) {
              assert(false,
                  "String is not empty, but getOffsetAfter(0) returned zero!");
              break;
            }
            line = line.substring(next);
          }
//          debugPrint('Ends at index $end, line length:${line.length}');
          var boundBox = charpos?.boundBox;
//          debugPrint('boundBox:$boundBox, maxWidth=$maxWidth');
          var subline =
              _WrapLine(line.substring(0, end), rawLine, (end == line.length));
//          debugPrint('wrap line:${subline.text}');
          _wrapLines.add(subline);
          line = line.substring(end);
          ++processedLines;
          if (maxLines != null &&
              processedLines >= maxLines &&
              TextOverflow.ellipsis == _overflow) {
            //  达到最大行数，将剩余的部分写到缓冲区中，以便后续合并行
            buffer.write(line);
            processTruncation = true;
            break;
          }
        } while (line.length > 0);
        rawLine++;
        if (processTruncation) {
          bool exceed = buffer.isNotEmpty || rawLine < _rawLines.length;
          if (exceed) {
            // 超出最大行数，后续所有行进行合并
            assert(_wrapLines.length == maxLines);
            int last = _wrapLines.length - 1;
            _WrapLine lastLine = _wrapLines[last];
            _rawLines
                .getRange(rawLine, _rawLines.length)
                .forEach((l) => buffer.write("$l"));
            String s = '${lastLine.text}${buffer.toString()}';
            _wrapLines[last] = _WrapLine(s, -1, true);
            _replaceEllipsis(last, _ellipsisMode,
                minWidth: minWidth, maxWidth: maxWidth);
          }
          break;
        }
      }
//      debugPrint('Done wrap process.');
      _joinAndLayout(textStyle, minWidth: minWidth);
      _lastMinWidth = minWidth;
      _lastMaxWidth = maxWidth;
    }
  }

  void _layoutText({double minWidth = 0.0, double maxWidth = double.infinity}) {
    _layoutWrap(minWidth: minWidth, maxWidth: maxWidth);
//    final bool widthMatters = softWrap || overflow == TextOverflow.ellipsis;
//    _textPainter.layout(
//        minWidth: minWidth,
//        maxWidth: widthMatters ? maxWidth : double.infinity);
  }

  void _layoutTextWithConstraints(BoxConstraints constraints) {
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _layoutText();
    return _textPainter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layoutText();
    return _textPainter.maxIntrinsicWidth;
  }

  double _computeIntrinsicHeight(double width) {
    _layoutText(minWidth: width, maxWidth: width);
    return _textPainter.height;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    assert(constraints != null);
    assert(constraints.debugAssertIsValid());
    _layoutTextWithConstraints(constraints);
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is! PointerDownEvent) return;
    _layoutTextWithConstraints(constraints);
    final Offset offset = entry.localPosition;
    final TextPosition position = _textPainter.getPositionForOffset(offset);
    final TextSpan span = _textPainter.text.getSpanForPosition(position);
    span?.recognizer?.addPointer(event);
  }

  bool _hasVisualOverflow = false;
  ui.Shader _overflowShader;

  /// Whether this paragraph currently has a [dart:ui.Shader] for its overflow
  /// effect.
  ///
  /// Used to test this object. Not for use in production.
  @visibleForTesting
  bool get debugHasOverflowShader => _overflowShader != null;

  @override
  void performLayout() {
    _layoutTextWithConstraints(constraints);
    // We grab _textPainter.size here because assigning to `size` will trigger
    // us to validate our intrinsic sizes, which will change _textPainter's
    // layout because the intrinsic size calculations are destructive.
    // Other _textPainter state like didExceedMaxLines will also be affected.
    // See also RenderEditable which has a similar issue.
    final Size textSize = _textPainter.size;
    final bool didOverflowHeight = _textPainter.didExceedMaxLines;
    size = constraints.constrain(textSize);

    final bool didOverflowWidth = size.width < textSize.width;
    // TODO(abarth): We're only measuring the sizes of the line boxes here. If
    // the glyphs draw outside the line boxes, we might think that there isn't
    // visual overflow when there actually is visual overflow. This can become
    // a problem if we start having horizontal overflow and introduce a clip
    // that affects the actual (but undetected) vertical overflow.
    _hasVisualOverflow = didOverflowWidth || didOverflowHeight;
    if (_hasVisualOverflow) {
      switch (_overflow) {
        case TextOverflow.clip:
        case TextOverflow.ellipsis:
          _overflowShader = null;
          break;
        case TextOverflow.fade:
          assert(textDirection != null);
          final TextPainter fadeSizePainter = TextPainter(
            text: TextSpan(style: _textPainter.text.style, text: '\u2026'),
            textDirection: textDirection,
            textScaleFactor: textScaleFactor,
            locale: locale,
          )..layout();
          if (didOverflowWidth) {
            double fadeEnd, fadeStart;
            switch (textDirection) {
              case TextDirection.rtl:
                fadeEnd = 0.0;
                fadeStart = fadeSizePainter.width;
                break;
              case TextDirection.ltr:
                fadeEnd = size.width;
                fadeStart = fadeEnd - fadeSizePainter.width;
                break;
            }
            _overflowShader = ui.Gradient.linear(
              Offset(fadeStart, 0.0),
              Offset(fadeEnd, 0.0),
              <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
            );
          } else {
            final double fadeEnd = size.height;
            final double fadeStart = fadeEnd - fadeSizePainter.height / 2.0;
            _overflowShader = ui.Gradient.linear(
              Offset(0.0, fadeStart),
              Offset(0.0, fadeEnd),
              <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
            );
          }
          break;
        default:
          _overflowShader = null;
      }
    } else {
      _overflowShader = null;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Ideally we could compute the min/max intrinsic width/height with a
    // non-destructive operation. However, currently, computing these values
    // will destroy state inside the painter. If that happens, we need to
    // get back the correct state by calling _layout again.
    //
    // TODO(abarth): Make computing the min/max intrinsic width/height
    // a non-destructive operation.
    //
    // If you remove this call, make sure that changing the textAlign still
    // works properly.
    _layoutTextWithConstraints(constraints);
    final Canvas canvas = context.canvas;

    assert(() {
      if (debugRepaintTextRainbowEnabled) {
        final Paint paint = Paint()..color = debugCurrentRepaintColor.toColor();
        canvas.drawRect(offset & size, paint);
      }
      return true;
    }());

    if (_hasVisualOverflow) {
      final Rect bounds = offset & size;
      if (_overflowShader != null) {
        // This layer limits what the shader below blends with to be just the text
        // (as opposed to the text and its background).
        canvas.saveLayer(bounds, Paint());
      } else {
        canvas.save();
      }
      canvas.clipRect(bounds);
    }
    _textPainter.paint(canvas, offset);
    if (_hasVisualOverflow) {
      if (_overflowShader != null) {
        canvas.translate(offset.dx, offset.dy);
        final Paint paint = Paint()
          ..blendMode = BlendMode.modulate
          ..shader = _overflowShader;
        canvas.drawRect(Offset.zero & size, paint);
      }
      canvas.restore();
    }
  }

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after [layout].
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getOffsetForCaret(position, caretPrototype);
  }

  /// Returns a list of rects that bound the given selection.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  ///
  /// Valid only after [layout].
  List<ui.TextBox> getBoxesForSelection(TextSelection selection) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getBoxesForSelection(selection);
  }

  /// Returns the position within the text for the given pixel offset.
  ///
  /// Valid only after [layout].
  TextPosition getPositionForOffset(Offset offset) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getPositionForOffset(offset);
  }

  /// Returns the size of the text as laid out.
  ///
  /// This can differ from [size] if the text overflowed or if the [constraints]
  /// provided by the parent [RenderObject] forced the layout to be bigger than
  /// necessary for the given [text].
  ///
  /// This returns the [TextPainter.size] of the underlying [TextPainter].
  ///
  /// Valid only after [layout].
  Size get textSize {
    assert(!debugNeedsLayout);
    return _textPainter.size;
  }

  final List<int> _recognizerOffsets = <int>[];
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    _recognizerOffsets.clear();
    _recognizers.clear();
    int offset = 0;
    text.visitTextSpan((TextSpan span) {
      if (span.recognizer != null &&
          (span.recognizer is TapGestureRecognizer ||
              span.recognizer is LongPressGestureRecognizer)) {
        _recognizerOffsets.add(offset);
        _recognizerOffsets.add(offset + span.text.length);
        _recognizers.add(span.recognizer);
      }
      offset += span.text.length;
      return true;
    });
    if (_recognizerOffsets.isNotEmpty) {
      config.explicitChildNodes = true;
      config.isSemanticBoundary = true;
    } else {
      config.label = text.toPlainText();
      config.textDirection = textDirection;
    }
  }

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config,
      Iterable<SemanticsNode> children) {
    assert(_recognizerOffsets.isNotEmpty);
    assert(_recognizerOffsets.length.isEven);
    assert(_recognizers.isNotEmpty);
    assert(children.isEmpty);
    final List<SemanticsNode> newChildren = <SemanticsNode>[];
    final String rawLabel = text.toPlainText();
    int current = 0;
    double order = -1.0;
    TextDirection currentDirection = textDirection;
    Rect currentRect;

    SemanticsConfiguration buildSemanticsConfig(int start, int end) {
      final TextDirection initialDirection = currentDirection;
      final TextSelection selection =
          TextSelection(baseOffset: start, extentOffset: end);
      final List<ui.TextBox> rects = getBoxesForSelection(selection);
      Rect rect;
      for (ui.TextBox textBox in rects) {
        rect ??= textBox.toRect();
        rect = rect.expandToInclude(textBox.toRect());
        currentDirection = textBox.direction;
      }
      // round the current rectangle to make this API testable and add some
      // padding so that the accessibility rects do not overlap with the text.
      // TODO(jonahwilliams): implement this for all text accessibility rects.
      currentRect = Rect.fromLTRB(
        rect.left.floorToDouble() - 4.0,
        rect.top.floorToDouble() - 4.0,
        rect.right.ceilToDouble() + 4.0,
        rect.bottom.ceilToDouble() + 4.0,
      );
      order += 1;
      return SemanticsConfiguration()
        ..sortKey = OrdinalSortKey(order)
        ..textDirection = initialDirection
        ..label = rawLabel.substring(start, end);
    }

    for (int i = 0, j = 0; i < _recognizerOffsets.length; i += 2, j++) {
      final int start = _recognizerOffsets[i];
      final int end = _recognizerOffsets[i + 1];
      if (current != start) {
        final SemanticsNode node = SemanticsNode();
        final SemanticsConfiguration configuration =
            buildSemanticsConfig(current, start);
        node.updateWith(config: configuration);
        node.rect = currentRect;
        newChildren.add(node);
      }
      final SemanticsNode node = SemanticsNode();
      final SemanticsConfiguration configuration =
          buildSemanticsConfig(start, end);
      final GestureRecognizer recognizer = _recognizers[j];
      if (recognizer is TapGestureRecognizer) {
        configuration.onTap = recognizer.onTap;
      } else if (recognizer is LongPressGestureRecognizer) {
        configuration.onLongPress = recognizer.onLongPress;
      } else {
        assert(false);
      }
      node.updateWith(config: configuration);
      node.rect = currentRect;
      newChildren.add(node);
      current = end;
    }
    if (current < rawLabel.length) {
      final SemanticsNode node = SemanticsNode();
      final SemanticsConfiguration configuration =
          buildSemanticsConfig(current, rawLabel.length);
      node.updateWith(config: configuration);
      node.rect = currentRect;
      newChildren.add(node);
    }
    node.updateWith(config: config, childrenInInversePaintOrder: newChildren);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      text.toDiagnosticsNode(
          name: 'text', style: DiagnosticsTreeStyle.transition)
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
    properties.add(FlagProperty('softWrap',
        value: softWrap,
        ifTrue: 'wrapping at box width',
        ifFalse: 'no wrapping except at line break characters',
        showName: true));
    properties.add(EnumProperty<TextOverflow>('overflow', overflow));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
    properties
        .add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, ifNull: 'unlimited'));
  }
}
