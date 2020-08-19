/// 日志类
class Log {
  /// 正常的信息打印行数
  static const int DEBUG_MAX_LINE = 5;

  /// ERROR的信息打印行数
  static const int ERROR_MAX_LINE = 50;

  static void d(String tag, String message) {
    _printAll("[D]$tag: $message", DEBUG_MAX_LINE);
  }

  static void i(String tag, String message) {
    _printAll("[I]$tag: $message", DEBUG_MAX_LINE);
  }

  static void w(String tag, String message) {
    _printAll("[W]$tag: $message", DEBUG_MAX_LINE);
  }

  static void e(String tag, String message) {
    _printAll("[*ERROR*]$tag: $message", ERROR_MAX_LINE);
  }

  static void _printAll(String text, final int maxLine) {
    /// Console一次print有长度限制,所以要分开多次print
    /// 如果总长度小于512就直接print,避免截断url
    if (text.length < 512) {
      print(text);
    } else {
      int lineNo = 0;
      int ix = 0;
      const int lineMax = 128;
      while (ix < text.length && lineNo < maxLine) {
        int end = (ix + lineMax < text.length) ? (ix + lineMax) : text.length;
        print((ix > 0 ? "    " : "") + text.substring(ix, end));
        ix += lineMax;
        lineNo++;
      }
    }
  }
}
