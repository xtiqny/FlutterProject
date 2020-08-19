import 'package:intl/intl.dart';
import 'package:cn21base/cn21base.dart';

class TimeUtils {
  static const String TAG = "TimeUtils";
  static const String LONGEST_FORMAT = "yyyy-MM-dd HH:mm:ss.SSS";
  static const String LONG_FORMAT = "yyyy-MM-dd HH:mm:ss";
  static const String SHORT_FORMAT = "yyyy-MM-dd";
  static const String TIME_FORMAT = "HH:mm:ss";
  static const String TIME_SHORT_FORMAT = "HH:mm";
  static const String LONGEST_FORMAT_WITHOUT_LINE = "yyyyMMddHHmmss";

  ///返回当前时间戳
  static int currentTimeMillis() {
    return new DateTime.now().millisecondsSinceEpoch;
  }

  /**
   * 判断两个日期是否是同一天
   *
   * @param date1 date1
   * @param date2 date2
   * @return
   */
  static bool isSameDate(DateTime date1, DateTime date2) {
    bool isSameYear = date1.year == date2.year;
    bool isSameMonth = isSameYear && date1.month == date2.month;
    bool isSameDay = isSameMonth && date1.day == date2.day;

    return isSameDay;
  }

  /**
   * 按指定的时间格式时间转换为字符串
   *
   * @param date       时间
   * @param timeFormat 时间格式
   * @return
   */
  static String dateToStr(DateTime date, String timeFormat) {
    DateFormat formater = new DateFormat(timeFormat);
    return formater.format(date);
  }

  /**
   * 将长时间格式(yyyy-MM-dd HH:mm:ss)字符串转换为时间
   *
   * @param dateStr
   * @return
   */
  static DateTime strToDateLong(String dateStr) {
    return strToDate(dateStr, LONG_FORMAT);
  }

  /**
   * 按指定的时间格式字符串转换为时间
   *
   * @param dateStr    日期字符串
   * @param timeFormat 日期格式
   * @return
   */
  static DateTime strToDate(String dateStr, String timeFormat) {
    DateTime date = null;
    DateFormat formater = new DateFormat(timeFormat);
    try {
      date = formater.parse(dateStr);
    } on Exception catch (e) {
      Log.w(TAG, ": strToDate $e");
    }

    return date;
  }

  static stringForTime(int timeMs) {
    if (timeMs == null || timeMs == -1 || timeMs == 0) {
      return "00:00";
    }
    int totalSeconds = timeMs ~/ 1000;
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds ~/ 60) % 60;
    int hours = totalSeconds ~/ 3600;
    if (hours > 0) {
      final formatter = new DateFormat("hh:mm:ss");
      DateTime dateTime = DateTime(0, 0, 0, hours, minutes, seconds);
      return formatter.format(dateTime);
    } else {
      final formatter = new DateFormat("mm:ss");
      DateTime dateTime = DateTime(0, 0, 0, 0, minutes, seconds);
      return formatter.format(dateTime);
    }
  }

  static stringForTimeToChinese(int totalSeconds) {
    if (totalSeconds == null || totalSeconds == -1 || totalSeconds == 0) {
      return "";
    }
    int seconds = totalSeconds;
    int minutes = totalSeconds ~/ 60;
    int hours = totalSeconds ~/ 3600;
    if (hours > 0) {
      final formatter = new DateFormat("h小时m分钟");
      DateTime dateTime = DateTime(0, 0, 0, hours, minutes);
      return formatter.format(dateTime);
    } else if (minutes > 0) {
      final formatter = new DateFormat("m分钟");
      DateTime dateTime = DateTime(0, 0, 0, 0, minutes);
      return formatter.format(dateTime);
    } else {
      final formatter = new DateFormat("s秒");
      DateTime dateTime = DateTime(0, 0, 0, 0, 0, seconds);
      return formatter.format(dateTime);
    }
  }

  // 获取当天日期的简短形式
  static String getNowDateShort() {
    DateTime now = DateTime.now();
    DateFormat format = DateFormat(SHORT_FORMAT);
    return format.format(now);
  }
}
