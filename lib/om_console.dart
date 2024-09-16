import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class Console {
  static void log(
    dynamic message, {
    LogType type = LogType.normal,
    Color textColor = Colors.white,
  }) {
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
        OmConsole.logs.value.add(logData);
        OmConsole.orgLogs.add(logData);
        OmConsole.filterWithTags(OmConsole.searchConroller.text);
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        OmConsole.logs.notifyListeners();
      } catch (e) {
        print(e.toString());
      }
    });
  }

  static void logHttp({
    required String url,
    required String method,
    required Map<String, dynamic> headers,
    required Map<String, dynamic> body,
    Color textColor = Colors.white,
    Color backgroundColor = const Color.fromARGB(255, 207, 223, 190),
    required int statusCode,
    required Map<String, dynamic> response,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        int lastId =
            (OmConsole.orgLogs.isEmpty ? 0 : OmConsole.orgLogs.last.id) + 1;
        String prettyResponse =
            const JsonEncoder.withIndent('  ').convert(response);
        Log logHttp = Log(
          "$url $method $headers $body $statusCode $response",
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
        OmConsole.logs.value.add(logHttp);
        OmConsole.orgLogs.add(logHttp);
        OmConsole.filterWithTags(OmConsole.searchConroller.text);
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        OmConsole.logs.notifyListeners();
      } catch (e) {
        print(e.toString());
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
  static final List<Log> orgLogs = [];
  static final ValueNotifier<List<Log>> logs = ValueNotifier<List<Log>>([]);
  static List<LogType?> logTypes = [];
  static TextEditingController searchConroller = TextEditingController();
  static int currentSearchScrollIndex = 0;
  static Log? currentSearch;
  static final ItemScrollController itemScrollController =
      ItemScrollController();

  static void clear() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        for (var log in logs.value) {
          orgLogs.removeWhere((e) => e.id == log.id);
        }
        logs.value.clear();

        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        logs.notifyListeners();
      } catch (e) {
        print(e.toString());
      }
    });
  }

  static void searchPaging({
    bool forward = false,
    bool back = false,
  }) {
    try {
      String text = searchConroller.text;
      List<Log> searchLogs = [];
      if (text.isEmpty) {
        searchLogs = [];
      } else {
        searchLogs = logs.value
            .where(
                (log) => log.message.toLowerCase().contains(text.toLowerCase()))
            .toList();
      }
      if (searchLogs.isEmpty) {
        currentSearch = null;
        currentSearchScrollIndex = 0;
        return;
      }
      if (forward) {
        back = false;
        currentSearchScrollIndex += 1;
        if (currentSearchScrollIndex > searchLogs.length - 1) {
          currentSearchScrollIndex = searchLogs.length - 1;
        }
        currentSearch = searchLogs[currentSearchScrollIndex];
        int index = logs.value.indexWhere((e) => currentSearch!.id == e.id);
        if (index < 0) {
          itemScrollController.scrollTo(
              index: 0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOutCubic);
        } else {
          itemScrollController.scrollTo(
              index: index,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOutCubic);
        }
      } else {
        forward = false;
        currentSearchScrollIndex -= 1;
        if (currentSearchScrollIndex < 0) currentSearchScrollIndex = 0;
        currentSearch = searchLogs[currentSearchScrollIndex];
        int index = logs.value.indexWhere((e) => currentSearch!.id == e.id);
        if (index < 0) {
          itemScrollController.scrollTo(
              index: 0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOutCubic);
        } else {
          itemScrollController.scrollTo(
              index: index,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOutCubic);
        }
      }
    } catch (e) {
      print(e.toString());
    }
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
        // logs.value.clear();
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
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      logs.notifyListeners();
    } catch (e) {
      print(e.toString());
    }
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

enum LogType { normal, error, http, logs }
