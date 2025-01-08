import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:om_console/console_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// A wrapper widget that provides a console functionality.
///
/// This widget wraps a child widget and optionally displays a console.
/// The console can be toggled on/off and the maximum number of lines
/// can be specified.
class ConsoleWrapper extends StatelessWidget {
  /// Creates a ConsoleWrapper.
  ///
  /// The [child] parameter is required and represents the widget to be wrapped.
  /// [showConsole] determines whether the console should be displayed.
  /// [maxLines] sets the maximum number of lines in the console.
  const ConsoleWrapper({
    Key? key,
    required this.child,
    this.showConsole = true,
    this.maxLines = 200,
  }) : super(key: key);

  /// The widget to be wrapped by the console.
  final Widget child;

  /// Whether to show the console or not.
  final bool showConsole;

  /// The maximum number of lines to display in the console.
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

/// A class that provides logging functionality for the console.
class Console {
  /// Logs a message to the console.
  ///
  /// [message] is the content to be logged.
  /// [type] specifies the type of log (default is [LogType.normal]).
  /// [textColor] sets the color of the log text (default is white).
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

  /// Logs an SQL query to the console.
  ///
  /// [dbName] is the name of the database.
  /// [spName] is the name of the stored procedure.
  /// [params] is a map of parameters for the SQL query.
  /// [textColor] sets the color of the log text (default is black).
  /// [backgroundColor] sets the background color of the log (default is light green).
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

  /// Logs an HTTP request to the console.
  ///
  /// [url] is the URL of the HTTP request.
  /// [method] is the HTTP method used.
  /// [headers] is a map of HTTP headers.
  /// [body] is the request body.
  /// [textColor] sets the color of the log text (default is black).
  /// [backgroundColor] sets the background color of the log (default is light green).
  /// [statusCode] is the HTTP status code of the response.
  /// [response] is the response body.
  static void logHttp({
    required String url,
    required String method,
    required Map<String, dynamic> headers,
    required Map<String, dynamic> body,
    Color textColor = Colors.black,
    Color backgroundColor = const Color.fromARGB(255, 207, 223, 190),
    required int statusCode,
    required Map<String, dynamic> response,
    BodyType bodyType = BodyType.raw,
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
          curlCommand: OmConsole.generateCurlCommandWithJson(
            url,
            headers,
            body,
            bodyType: bodyType,
          ),
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

  /// Sets up a console listener that captures print statements and errors.
  ///
  /// [function] is the function to be executed within the zone.
  static void consoleLisitener(Function function) {
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

/// A class that manages the console functionality.
class OmConsole {
  /// List of original logs.
  static List<Log> orgLogs = [];

  /// ValueNotifier for the list of logs to be displayed.
  static final ValueNotifier<List<Log>> logs = ValueNotifier<List<Log>>([]);

  /// List of log types to filter.
  static List<LogType?> logTypes = [];

  /// Controller for the search text field.
  static TextEditingController searchConroller = TextEditingController();

  /// Current scroll index for search results.
  static int currentSearchScrollIndex = 0;

  /// Currently selected search result.
  static Log? currentSearch;

  /// Flag to determine if the console should be shown.
  static bool showConsole = true;

  /// Flag to determine if the console should scroll to bottom.
  static bool scrollToBottom = false;

  /// Maximum number of lines to display in the console.
  static int maxLines = 20000;

  /// Current index in search results.
  static int currentSearchIndex = 0;

  /// Total number of search results.
  static int searchResultsLength = 0;

  /// Controller for scrolling the list of logs.
  static final ItemScrollController itemScrollController =
      ItemScrollController();

  /// Listener for item positions in the scrollable list.
  static ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  /// Global key for the navigator state.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Clears logs based on specified log types or all logs if no types are specified.
  /// Resets search-related properties and reapplies filters if necessary.
  static void clear() {
    try {
      if (logTypes.isEmpty || logTypes.contains(null)) {
        // Clear all logs
        orgLogs.clear();
        logs.value.clear();
      } else {
        // Clear only logs of specified types
        orgLogs.removeWhere((log) => logTypes.contains(log.type));
        logs.value.removeWhere((log) => logTypes.contains(log.type));
      }

      // Reset search-related properties
      currentSearchIndex = 0;
      searchResultsLength = 0;
      currentSearch = null;

      // Notify listeners of the change
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      logs.notifyListeners();

      // Reapply filters if any
      if (searchConroller.text.isNotEmpty) {
        searchPaging();
      } else {
        filterWithTags(searchConroller.text);
      }
    } catch (e) {
      print("Error in clear: $e");
    }
  }

  /// Scrolls the console to the bottom.
  static void scrollToBottomMethod() {
    try {
      OmConsole.itemScrollController.scrollTo(
        index: OmConsole.logs.value.length - 1,
        duration: const Duration(milliseconds: 100),
      );
    } catch (e) {
      // Error handling omitted
    }
  }

  /// Processes logs for search functionality, splitting long messages and updating search results.
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

  /// Navigates through search results in the console logs.
  ///
  /// [forward] moves to the next search result if true.
  /// [back] moves to the previous search result if true.
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

  /// Generates an SQL query string for a stored procedure call.
  ///
  /// [dbName] is the name of the database.
  /// [spName] is the name of the stored procedure.
  /// [params] is a map of parameter names and values for the stored procedure.
  ///
  /// Returns a formatted SQL query string.
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

  /// Generates a cURL command string for an HTTP request with JSON data.
  ///
  /// [url] is the target URL for the request.
  /// [headers] is a map of HTTP headers to include in the request.
  /// [jsonData] is the data to be sent as JSON in the request body.
  ///
  /// Returns a formatted cURL command string.
  static String generateCurlCommandWithJson(
    String url,
    Map<String, dynamic> headers,
    Map<String, dynamic> bodyData, {
    BodyType bodyType = BodyType.raw,
  }) {
    // Start building the curl command
    String curlCommand = "curl --location '$url' \\\n";

    // Add headers to the command
    headers.forEach((key, value) {
      curlCommand += "--header '$key: $value' \\\n";
    });

    // Add the data payload to the command based on the body type
    switch (bodyType) {
      case BodyType.formData:
        bodyData.forEach((key, value) {
          curlCommand += "--form '$key=$value' \\\n";
        });
        break;
      case BodyType.xWwwFormUrlencoded:
        String formUrlEncoded = bodyData.entries
            .map((entry) =>
                '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
            .join('&');
        curlCommand += "--data '$formUrlEncoded' \\\n";
        break;
      case BodyType.raw:
        String jsonString = jsonEncode(bodyData);
        curlCommand += "--data '$jsonString' \\\n";
        break;
      default: // BodyType.json
        String jsonString = jsonEncode(bodyData);
        curlCommand += "--data '$jsonString' \\\n";
        break;
    }

    // Remove the trailing backslash and newline
    curlCommand = curlCommand.trimRight().replaceAll(RegExp(r'\\\n$'), '');

    return curlCommand;
  }

  /// Filters and updates the console logs based on selected log types and search text.
  ///
  /// [text] is the search text to filter logs by.
  static void filterWithTags(String text) {
    try {
      currentSearchScrollIndex = 0;
      if (logTypes.isEmpty || logTypes.contains(null)) {
        logs.value = List.from(orgLogs); // Create a new list from orgLogs
      } else {
        logs.value =
            orgLogs.where((log) => logTypes.contains(log.type)).toList();
      }
      if (text.isNotEmpty) {
        searchPaging();
      } else {
        // Reset search-related properties when there's no search text
        currentSearchIndex = 0;
        searchResultsLength = logs.value.length;
        currentSearch = null;
        // Notify listeners of the change
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        logs.notifyListeners();
      }
    } catch (e) {
      print("Error in filterWithTags: $e");
    }
  }

  /// Limits the total number of lines in the console logs.
  ///
  /// [textStyle] is the TextStyle used for calculating line heights.
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

/// Represents a log entry in the console.
class Log {
  /// Unique identifier for the log entry.
  final int id;

  /// The main content of the log message.
  final String message;

  /// The type of the log entry (e.g., normal, error, http).
  final LogType type;

  /// The color of the log text.
  final Color textColor;

  /// The background color of the log entry.
  final Color backgroundColor;

  /// The HTTP method (for HTTP log types).
  final String method;

  /// The URL (for HTTP log types).
  final String url;

  /// The HTTP status code (for HTTP log types).
  final int statusCode;

  /// The HTTP headers (for HTTP log types).
  final String headers;

  /// The HTTP request body (for HTTP log types).
  final String body;

  /// The HTTP response (for HTTP log types).
  final String? response;

  /// Whether the response is expanded in the UI.
  bool expandRes;

  /// The cURL command equivalent of the HTTP request.
  final String curlCommand;

  /// Creates a new Log instance.
  ///
  /// The [message], [id], [type], and [textColor] are required.
  /// Other parameters are optional and have default values.
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

/// Defines the types of log entries.
enum LogType {
  /// Normal log entry.
  normal,

  /// Error log entry.
  error,

  /// HTTP request/response log entry.
  http,

  /// General logs entry.
  logs,

  /// SQL query log entry.
  sql
}

/// Defines the types of request bodies.
enum BodyType {
  /// Form data body type.
  formData,

  /// x-www-form-urlencoded body type.
  xWwwFormUrlencoded,

  /// Raw body type.
  raw,
}
