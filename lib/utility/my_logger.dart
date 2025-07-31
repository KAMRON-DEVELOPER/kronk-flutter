import 'package:logger/logger.dart';

// ANSI color codes
const String reset = '\x1B[0m';
const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String blue = '\x1B[34m';
const String magenta = '\x1B[35m';
const String cyan = '\x1B[36m';
const String white = '\x1B[37m';

class SimplePrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final trace = event.stackTrace?.toString().split('\n') ?? StackTrace.current.toString().split('\n');

    String? location;
    for (var line in trace) {
      if (!line.contains('package:logger') && !line.contains('package:kronk/utility/my_logger.dart')) {
        location = RegExp(r'\((.*?)\)').firstMatch(line)?.group(1);
        break;
      }
    }

    location ??= 'unknown';

    final levelInfo =
        {
          Level.trace: {'emoji': '🔍', 'color': cyan},
          Level.debug: {'emoji': '🐛', 'color': blue},
          Level.info: {'emoji': '💡', 'color': green},
          Level.warning: {'emoji': '🚨', 'color': yellow},
          Level.error: {'emoji': '🌋', 'color': red},
          Level.fatal: {'emoji': '👾', 'color': magenta},
        }[event.level] ??
        {'emoji': '📌', 'color': white};

    final color = levelInfo['color'];
    final emoji = levelInfo['emoji'];

    return ['$color($location) $emoji ${event.message}$reset'];
  }
}

final myLogger = Logger(printer: SimplePrinter(), level: Level.trace);
