library om_console;

import 'package:flutter/material.dart';
export "console_wrapper.dart";


class Console {
  static final List<Log> _orgLogs = [];
  static final ValueNotifier<List<Log>> logs = ValueNotifier<List<Log>>([]);

  static final ScrollController scrollController = ScrollController();

  static void log(String message, {LogType type = LogType.normal}) {
    logs.value.add(Log(message, type: type));
    _orgLogs.add(Log(message, type: type));
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    logs.notifyListeners();
  }

  static void clear() {
    logs.value.clear();
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    logs.notifyListeners();
  }

  static void search(String text) {
    if (text.isEmpty) {
      logs.value = _orgLogs;
    } else {
      logs.value = _orgLogs
          .where(
              (log) => log.message.toLowerCase().contains(text.toLowerCase()))
          .toList();
    }
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    logs.notifyListeners();
  }
}

void print(Object? object, {LogType type = LogType.normal}) {
  String message = "$object";
  Console.log(message, type: type);
}

class Log {
  String message;
  LogType type;

  Log(this.message, {this.type = LogType.info});
}

enum LogType { normal, error, warning, info, success }

