/// Base日志类
class BaseLog {
  static void d(String tag, String message) {
    _printAll("[D]$tag: $message");
  }

  static void i(String tag, String message) {
    _printAll("[I]$tag: $message");
  }

  static void w(String tag, String message) {
    _printAll("[W]$tag: $message");
  }

  static void e(String tag, String message) {
    _printAll("[E]$tag: $message");
  }

  static void _printAll(String text) {
    /// Console一次print有长度限制,所以要分开多次print
    /// 如果总长度小于512就直接print,避免截断url
    if (text.length < 512) {
      print(text);
    } else {
      int lineNo = 0;
      int ix = 0;
      const int lineMax = 128;
      while (ix < text.length && lineNo < 5) {
        int end = (ix + lineMax < text.length) ? (ix + lineMax) : text.length;
        print((ix > 0 ? "    " : "") + text.substring(ix, end));
        ix += lineMax;
        lineNo++; // 行数加1，最多打印5行，避免影响效率
      }
    }
  }
}
