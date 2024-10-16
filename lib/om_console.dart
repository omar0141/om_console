import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:om_console/console_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ConsoleWrapper extends StatelessWidget {
  const ConsoleWrapper({
    Key? key,
    required this.child,
    this.showConsole = true,
    this.maxLines = 200,
  }) : super(key: key);

  final Widget child;
  final bool showConsole;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return ConsoleWidget(
      showConsole: showConsole,
      maxLines: maxLines,
      child: child,
    );
  }
}

class Console {
  static void log(
    dynamic message, {
    LogType type = LogType.normal,
    Color textColor = Colors.white,
  }) {
    if (OmConsole.showConsole == false) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        int lastId =
            (OmConsole.orgLogs.isEmpty ? 0 : OmConsole.orgLogs.last.id) + 1;
        Log logData = Log(
          "$message",
          type: type,
          textColor: textColor,
          id: lastId,
        );
        OmConsole.orgLogs.add(logData);
        OmConsole.logs.value.add(logData);
        if (type != LogType.error) {
          OmConsole.limitTotalLines(textStyle: const TextStyle(fontSize: 16));
        }
        OmConsole.filterWithTags(OmConsole.searchConroller.text);

        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        OmConsole.logs.notifyListeners();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!OmConsole.scrollToBottom) {
            OmConsole.scrollToBottomMethod();
          }
        });
      } catch (e) {
        // print(e.toString());
      }
    });
  }

  static void logSql({
    required String dbName,
    required String spName,
    required Map<String, dynamic> params,
    Color textColor = Colors.black,
    Color backgroundColor = const Color.fromARGB(255, 207, 223, 190),
  }) {
    if (OmConsole.showConsole == false) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        int lastId =
            (OmConsole.orgLogs.isEmpty ? 0 : OmConsole.orgLogs.last.id) + 1;
        Log logSql = Log(
          OmConsole.generateSqlQuery(dbName, spName, params),
          textColor: textColor,
          backgroundColor: backgroundColor,
          id: lastId,
          type: LogType.sql,
          curlCommand: OmConsole.generateSqlQuery(dbName, spName, params),
        );
        OmConsole.orgLogs.add(logSql);
        OmConsole.logs.value.add(logSql);

        OmConsole.filterWithTags(OmConsole.searchConroller.text);
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        OmConsole.logs.notifyListeners();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!OmConsole.scrollToBottom) {
            OmConsole.scrollToBottomMethod();
          }
        });
      } catch (e) {
        // print(e.toString());
      }
    });
  }

  static void logHttp({
    required String url,
    required String method,
    required Map<String, dynamic> headers,
    required Map<String, dynamic> body,
    Color textColor = Colors.black,
    Color backgroundColor = const Color.fromARGB(255, 207, 223, 190),
    required int statusCode,
    required Map<String, dynamic> response,
  }) {
    if (OmConsole.showConsole == false) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        int lastId =
            (OmConsole.orgLogs.isEmpty ? 0 : OmConsole.orgLogs.last.id) + 1;
        String prettyResponse =
            const JsonEncoder.withIndent('  ').convert(response);
        if (prettyResponse.length > 300) {
          prettyResponse = prettyResponse.substring(0, 300);
        }
        Log logHttp = Log(
          "",
          url: url,
          method: method,
          headers: const JsonEncoder.withIndent('  ').convert(headers),
          body: const JsonEncoder.withIndent('  ').convert(body),
          statusCode: statusCode,
          response: prettyResponse,
          textColor: textColor,
          backgroundColor: backgroundColor,
          id: lastId,
          type: LogType.http,
          curlCommand:
              OmConsole.generateCurlCommandWithJson(url, headers, body),
        );
        OmConsole.orgLogs.add(logHttp);
        OmConsole.logs.value.add(logHttp);

        OmConsole.filterWithTags(OmConsole.searchConroller.text);
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        OmConsole.logs.notifyListeners();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!OmConsole.scrollToBottom) {
            OmConsole.scrollToBottomMethod();
          }
        });
      } catch (e) {
        // print(e.toString());
      }
    });
  }

  static void consoleLisitener(function) {
    runZoned(
      () {
        function();
      },
      zoneSpecification: ZoneSpecification(
        handleUncaughtError: (self, parent, zone, error, stackTrace) {
          parent.print(zone, error.toString());
          Console.log(
            error.toString(),
            type: LogType.error,
            textColor: const Color.fromARGB(255, 255, 107, 97),
          );
        },
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          parent.print(zone, line);
          Console.log(line);
        },
      ),
    );
  }
}

class OmConsole {
  static List<Log> orgLogs = [];
  static final ValueNotifier<List<Log>> logs = ValueNotifier<List<Log>>([]);
  static List<LogType?> logTypes = [];
  static TextEditingController searchConroller = TextEditingController();
  static int currentSearchScrollIndex = 0;
  static Log? currentSearch;
  static bool showConsole = true;
  static bool scrollToBottom = false;
  static int maxLines = 20000;
  static int currentSearchIndex = 0;
  static int searchResultsLength = 0;
  static final ItemScrollController itemScrollController =
      ItemScrollController();
  static ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void clear() {
    try {
      for (var log in logs.value) {
        orgLogs.removeWhere((e) => e.id == log.id);
      }
      logs.value.clear();
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      logs.notifyListeners();
    } catch (e) {
      // print(e.toString());
    }
  }

  static void scrollToBottomMethod() {
    try {
      OmConsole.itemScrollController.scrollTo(
        index: OmConsole.logs.value.length - 1,
        duration: const Duration(milliseconds: 100),
      );
    } catch (e) {
      //
    }
  }

  static void searchPaging() {
    try {
      String searchText = searchConroller.text.toLowerCase();
      List<Log> processedLogs = [];
      TextStyle textStyle = const TextStyle(fontSize: 16);
      double maxWidth =
          MediaQuery.of(navigatorKey.currentContext!).size.width - 70;

      for (Log originalLog in logs.value) {
        bool shouldSplit = false;

        if (originalLog.type == LogType.http) {
          shouldSplit = originalLog.statusCode
                  .toString()
                  .toLowerCase()
                  .contains(searchText) ||
              originalLog.url.toLowerCase().contains(searchText) ||
              originalLog.method.toLowerCase().contains(searchText) ||
              originalLog.headers.toLowerCase().contains(searchText) ||
              originalLog.body.toLowerCase().contains(searchText) ||
              (originalLog.response ?? "").toLowerCase().contains(searchText);
        } else {
          shouldSplit = originalLog.message.toLowerCase().contains(searchText);
        }

        if (shouldSplit &&
            originalLog.type != LogType.http &&
            originalLog.type != LogType.sql) {
          final textSpan = TextSpan(
            text: originalLog.message,
            style: textStyle,
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
            maxLines: null,
          );
          textPainter.layout(maxWidth: maxWidth);

          final List<LineMetrics> lines = textPainter.computeLineMetrics();
          String remainingText = originalLog.message;
          int lastOffset = 0;

          for (int i = 0; i < lines.length; i++) {
            final LineMetrics line = lines[i];
            final TextPosition endPosition = textPainter.getPositionForOffset(
              Offset(maxWidth, line.baseline),
            );

            String lineText = '';
            if (i == lines.length - 1) {
              // Last line
              lineText = remainingText.substring(lastOffset).trim();
            } else {
              lineText = remainingText
                  .substring(lastOffset, endPosition.offset)
                  .trim();
            }

            lastOffset = endPosition.offset;

            if (lineText.isNotEmpty) {
              processedLogs.add(Log(
                lineText,
                id: originalLog.id * 1000 + i,
                type: originalLog.type,
                textColor: originalLog.textColor,
                backgroundColor: originalLog.backgroundColor,
              ));
            }
          }
        } else {
          // If not splitting, add the original log
          processedLogs.add(originalLog);
        }
      }

      // Update logs.value with processed logs
      logs.value = processedLogs;
      searchResultsLength = logs.value.where((log) {
        if (log.type == LogType.http) {
          return log.statusCode.toString().toLowerCase().contains(searchText) ||
              log.url.toLowerCase().contains(searchText) ||
              log.method.toLowerCase().contains(searchText) ||
              log.headers.toLowerCase().contains(searchText) ||
              log.body.toLowerCase().contains(searchText) ||
              (log.response ?? "").toLowerCase().contains(searchText);
        } else {
          return log.message.toLowerCase().contains(searchText);
        }
      }).length;
      currentSearchIndex = 0;
      lineNavigate();
      // Notify listeners of the change
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      logs.notifyListeners();
    } catch (e) {
      print("Error in searchPaging: $e");
    }
  }

  static void lineNavigate({
    bool forward = false,
    bool back = false,
  }) {
    if (logs.value.isEmpty || searchConroller.text.isEmpty) {
      currentSearch = null;
      currentSearchIndex = 0;
      searchResultsLength = 0;
      return;
    }

    String searchText = searchConroller.text.toLowerCase();
    List<Log> matchingLogs = logs.value.where((log) {
      if (log.type == LogType.http) {
        return log.statusCode.toString().toLowerCase().contains(searchText) ||
            log.url.toLowerCase().contains(searchText) ||
            log.method.toLowerCase().contains(searchText) ||
            log.headers.toLowerCase().contains(searchText) ||
            log.body.toLowerCase().contains(searchText) ||
            (log.response ?? "").toLowerCase().contains(searchText);
      } else {
        return log.message.toLowerCase().contains(searchText);
      }
    }).toList();

    searchResultsLength = matchingLogs.length;

    if (matchingLogs.isEmpty) {
      currentSearch = null;
      currentSearchIndex = 0;
      return;
    }

    if (forward) {
      currentSearchIndex += 1;
      if (currentSearchIndex >= searchResultsLength) {
        currentSearchIndex = 0; // Wrap around to the beginning
      }
    } else if (back) {
      currentSearchIndex -= 1;
      if (currentSearchIndex < 0) {
        currentSearchIndex = searchResultsLength - 1; // Wrap around to the end
      }
    }

    currentSearch = matchingLogs[currentSearchIndex];
    int index = logs.value.indexWhere((e) => currentSearch!.id == e.id);

    if (index >= 0) {
      itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  static String generateSqlQuery(
      String dbName, String spName, Map<String, dynamic> params) {
    // Start building the SQL query
    StringBuffer sqlQuery = StringBuffer();

    // Add USE statement if needed (you might want to make this configurable)
    sqlQuery.writeln("USE [$dbName]");
    sqlQuery.writeln("GO");

    // Declare variables
    sqlQuery.writeln("DECLARE @return_value int,");
    sqlQuery.writeln("\t\t@State int,");
    sqlQuery.writeln("\t\t@Message nvarchar(500)");

    // Initialize state variables
    sqlQuery.writeln("SELECT\t@State = 0");
    sqlQuery.writeln("SELECT\t@Message = N'0'");

    // Start EXEC statement
    sqlQuery.write("EXEC\t@return_value = $spName");

    // Add parameters
    List<String> paramStrings = [];
    params.forEach((key, value) {
      String paramValue = value is String
          ? "N'${value.replaceAll("'", "''")}'"
          : value.toString();
      paramStrings.add("@$key = $paramValue");
    });

    if (paramStrings.isNotEmpty) {
      sqlQuery.writeln();
      sqlQuery.writeln("\t\t${paramStrings.join(',\n\t\t')}");
    }

    // Add return statements
    sqlQuery.writeln();
    sqlQuery.writeln("SELECT\t@State as N'@State',");
    sqlQuery.writeln("\t\t@Message as N'@Message'");
    sqlQuery.writeln("SELECT\t'Return Value' = @return_value");
    sqlQuery.writeln("GO");

    return sqlQuery.toString();
  }

  static String generateCurlCommandWithJson(
      String url, Map<String, dynamic> headers, Map<String, dynamic> jsonData) {
    // Start building the curl command
    String curlCommand = "curl --location '$url' \\\n";

    // Add headers to the command
    headers.forEach((key, value) {
      curlCommand += "--header '$key: $value' \\\n";
    });

    // Convert the Map to a pretty-printed JSON string
    String jsonString = jsonEncode(jsonData);

    // Add the data payload to the command
    curlCommand += "--data '$jsonString'";

    return curlCommand;
  }

  static void filterWithTags(String text) {
    try {
      currentSearchScrollIndex = 0;
      if (logTypes.isEmpty || logTypes.contains(null)) {
        logs.value = orgLogs
            .map((e) => Log(
                  e.message,
                  url: e.url,
                  method: e.method,
                  headers: e.headers,
                  body: e.body,
                  statusCode: e.statusCode,
                  response: e.response,
                  textColor: e.textColor,
                  id: e.id,
                  type: e.type,
                  curlCommand: e.curlCommand,
                  backgroundColor: e.backgroundColor,
                ))
            .toList();
      } else {
        logs.value =
            orgLogs.where((log) => logTypes.contains(log.type)).toList();
      }
      searchPaging();
    } catch (e) {
      // print(e.toString());
    }
  }

  static void limitTotalLines({required TextStyle textStyle}) {
    List<Log> limitedLogs = [];
    int totalLines = 0;
    double maxWidth =
        MediaQuery.of(navigatorKey.currentContext!).size.width - 70;

    // First pass: Only count the lines of non-HTTP logs
    for (int i = orgLogs.length - 1; i >= 0; i--) {
      Log log = orgLogs[i];

      if (log.type != LogType.http && log.type != LogType.sql) {
        final textSpan = TextSpan(text: log.message, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: null,
        );
        textPainter.layout(maxWidth: maxWidth);
        final logLines =
            (textPainter.height / textPainter.preferredLineHeight).ceil();

        if (totalLines + logLines <= maxLines) {
          limitedLogs.insert(0, log); // Add each log as its own entry
          totalLines += logLines;
        } else {
          break; // Stop when exceeding the max line limit
        }
      }
    }

    // Add all HTTP logs back without counting them in the line limit
    for (int i = orgLogs.length - 1; i >= 0; i--) {
      Log log = orgLogs[i];

      if (log.type == LogType.http || log.type == LogType.sql) {
        limitedLogs.insert(
            0, log); // Insert HTTP logs without altering line count
      }
    }

    // Replace the orgLogs with the properly limited logs
    orgLogs.clear();
    orgLogs
        .addAll(limitedLogs); // Ensure each log is added as an individual item

    // Notify listeners after updating the logs list
    OmConsole.logs.value = List.from(limitedLogs); // Rebuild the value
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    OmConsole.logs.notifyListeners();
  }
}

class Log {
  int id;
  String message;
  LogType type;
  Color textColor;
  Color backgroundColor;
  String method;
  String url;
  int statusCode;
  String headers;
  String body;
  String? response;
  bool expandRes;
  String curlCommand;

  Log(
    this.message, {
    required this.id,
    required this.type,
    required this.textColor,
    this.backgroundColor = Colors.transparent,
    this.method = '',
    this.url = '',
    this.statusCode = 0,
    this.headers = "",
    this.body = "",
    this.response = '',
    this.expandRes = false,
    this.curlCommand = '',
  });
}

enum LogType { normal, error, http, logs, sql }
