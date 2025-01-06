import 'dart:async';
import 'dart:ui';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'om_console.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'substring_higlight.dart';

/// Custom scroll behavior that allows both touch and mouse dragging.
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

// ignore: must_be_immutable
/// A widget that displays console output in the UI.
///
/// The [ConsoleWidget] allows developers to render log messages and other
/// textual output in a scrollable format with a maximum number of displayable lines.
class ConsoleWidget extends StatefulWidget {
  /// Creates a [ConsoleWidget].
  ///
  /// The [child] parameter is required and specifies the widget to display inside the console area.
  /// The [showConsole] parameter determines whether the console is visible.
  /// The [maxLines] parameter sets the maximum number of lines to display in the console output.
  const ConsoleWidget({
    Key? key,
    required this.child,
    this.showConsole = true,
    this.maxLines = 200,
  }) : super(key: key);

  /// The widget to display inside the console area.
  ///
  /// This is typically a [Text] or other widget that renders the console output.
  final Widget child;

  /// Determines whether the console is visible.
  final bool showConsole;

  /// The maximum number of lines to display in the console output.
  ///
  /// The console will display up to [maxLines] lines before truncating.
  final int maxLines;

  @override
  State<ConsoleWidget> createState() => _ConsoleWidgetState();
}

class _ConsoleWidgetState extends State<ConsoleWidget>
    with WidgetsBindingObserver {
  double? orgScreenHeight;
  double orgConsoleHeight = 35;
  double? screenHeight;
  double consoleHeight = 35;
  double screenWidth = 0;
  double _lastConsoleHeight = 300;
  bool expandedConsole = false;
  bool copied = false;
  bool multiFilter = false;

  @override
  void didChangeDependencies() {
    screenWidth = MediaQuery.of(context).size.width;
    orgScreenHeight = MediaQuery.of(context).size.height -
        orgConsoleHeight -
        MediaQuery.of(context).padding.bottom;
    screenHeight = orgScreenHeight;
    super.didChangeDependencies();
  }

  @override
  void initState() {
    OmConsole.itemPositionsListener.itemPositions.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (OmConsole.itemPositionsListener.itemPositions.value.last.index ==
              (OmConsole.logs.value.length - 1)) {
            setState(() {
              OmConsole.scrollToBottom = false;
            });
            Future.microtask(() => OmConsole.scrollToBottom = false);
          } else {
            setState(() {
              OmConsole.scrollToBottom = true;
            });
            Future.microtask(() => OmConsole.scrollToBottom = true);
          }
        } catch (e) {
          // your error message
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    OmConsole.maxLines = widget.maxLines;
    if (!widget.showConsole) {
      OmConsole.showConsole = false;
      return widget.child;
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(height: orgScreenHeight, child: widget.child),
                ),
              ),
              MaterialApp(
                navigatorKey: OmConsole.navigatorKey,
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  scrollbarTheme: ScrollbarThemeData(
                    thumbColor: const WidgetStatePropertyAll(Colors.white),
                    thumbVisibility: WidgetStateProperty.all(true),
                    thickness: WidgetStateProperty.all(12),
                    radius: Radius.zero,
                  ),
                ),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                locale: const Locale("en"),
                home: SizedBox(
                  height: consoleHeight,
                  child: Scaffold(
                    body: Container(
                      color: const Color.fromARGB(255, 37, 37, 37),
                      child: Column(children: [
                        if (expandedConsole) const SizedBox(height: 10),
                        consoleHeader(),
                        if (expandedConsole) consoleBody(),
                      ]),
                    ),
                  ),
                ),
              )
            ],
          ),
          if (expandedConsole)
            Positioned(
              left: 0,
              right: 0,
              bottom: consoleHeight - 10,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    consoleHeight = (consoleHeight - details.primaryDelta!)
                        .clamp(
                            screenWidth <= 800
                                ? (orgConsoleHeight + 50)
                                : (orgConsoleHeight + 10),
                            (orgScreenHeight ?? 0));
                    screenHeight = (orgScreenHeight ?? 0) -
                        consoleHeight +
                        orgConsoleHeight;
                    _lastConsoleHeight = consoleHeight;
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeRow,
                  child: Container(
                    color: const Color.fromARGB(255, 82, 82, 82),
                    child: Center(
                        child: Icon(
                      Icons.drag_handle,
                      color: Colors.white,
                      size: screenWidth <= 800 ? 15 : 10,
                    )),
                  ),
                ),
              ),
            ),
          if (expandedConsole)
            Positioned(
                right: 20,
                bottom: 10,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      if (OmConsole.scrollToBottom) {
                        OmConsole.scrollToBottomMethod();
                        OmConsole.scrollToBottom = false;
                      } else {
                        if (OmConsole.logs.value.isNotEmpty) {
                          OmConsole.itemScrollController.scrollTo(
                            index: 0,
                            duration: const Duration(milliseconds: 100),
                          );
                        }
                        OmConsole.currentSearchScrollIndex = 0;
                        OmConsole.scrollToBottom = true;
                      }
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 65, 65, 65),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(
                        OmConsole.scrollToBottom
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ))
        ],
      ),
    );
  }

  Container consoleHeader() {
    return Container(
      decoration: BoxDecoration(
          color: const Color.fromARGB(255, 37, 37, 37),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 0),
              color: Colors.white.withAlpha((0.5 * 255).toInt()),
              blurRadius: 5,
            )
          ]),
      padding: const EdgeInsets.all(5),
      child: screenWidth <= 800
          ? Wrap(
              runSpacing: 10,
              children: [
                leftSideHeader(),
                if (expandedConsole) rightSideHeader(),
              ],
            )
          : Row(
              children: [
                leftSideHeader(),
                const Spacer(),
                if (expandedConsole) rightSideHeader(),
              ],
            ),
    );
  }

  Row rightSideHeader() {
    return Row(
      children: [
        SizedBox(
          width: 225,
          child: TextField(
            controller: OmConsole.searchConroller,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
            ),
            onChanged: (e) {
              OmConsole.currentSearchScrollIndex = 0;
              OmConsole.searchPaging();
              setState(() {});
            },
            decoration: InputDecoration(
                fillColor: const Color.fromARGB(255, 117, 117, 117),
                filled: true,
                contentPadding: const EdgeInsets.all(5),
                isDense: true,
                hintText: "Search...",
                border: InputBorder.none,
                hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 199, 199, 199),
                ),
                suffix: Text(
                  "${OmConsole.searchResultsLength == 0 ? 0 : OmConsole.currentSearchIndex + 1} of ${OmConsole.searchResultsLength}",
                )),
          ),
        ),
        const SizedBox(width: 5),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              OmConsole.lineNavigate(back: true);
              setState(() {});
            },
            child: const Icon(
              Icons.arrow_upward,
              size: 20,
              color: Color.fromARGB(255, 197, 197, 197),
            ),
          ),
        ),
        const SizedBox(width: 5),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              OmConsole.lineNavigate(forward: true);
              setState(() {});
            },
            child: const Icon(
              Icons.arrow_downward,
              size: 20,
              color: Color.fromARGB(255, 197, 197, 197),
            ),
          ),
        ),
        const SizedBox(width: 10),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              OmConsole.clear();
            },
            child: const Icon(
              Icons.delete,
              size: 20,
              color: Color.fromARGB(255, 197, 197, 197),
            ),
          ),
        ),
        const SizedBox(width: 10),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              closeConsole();
            },
            child: const Icon(
              Icons.remove,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Row leftSideHeader() {
    return Row(
      children: [
        consoleTab(text: "All Console"),
        const SizedBox(width: 15),
        consoleTab(
          text: "Normal",
          logType: LogType.normal,
        ),
        const SizedBox(width: 15),
        consoleTab(
          text: "Http",
          logType: LogType.http,
        ),
        const SizedBox(width: 15),
        consoleTab(
          text: "Error",
          logType: LogType.error,
        ),
        const SizedBox(width: 15),
        consoleTab(
          text: "Logs",
          logType: LogType.logs,
        ),
        const SizedBox(width: 15),
        consoleTab(
          text: "Sql",
          logType: LogType.sql,
        ),
      ],
    );
  }

  Expanded consoleBody() {
    return Expanded(
        child: SelectionArea(
      child: ValueListenableBuilder<List<Log>>(
        valueListenable: OmConsole.logs,
        builder: (BuildContext context, List<Log> value, child) {
          return Padding(
              padding: const EdgeInsetsDirectional.only(start: 10),
              child: ScrollablePositionedList.builder(
                itemPositionsListener: OmConsole.itemPositionsListener,
                itemScrollController: OmConsole.itemScrollController,
                itemCount: value.length,
                itemBuilder: (context, i) {
                  Log log = value[i];
                  if (log.type == LogType.http) {
                    return httpWidget(log);
                  }
                  if (log.type == LogType.sql) {
                    return sqlWidget(log);
                  } else {
                    return normalTextWidget(log);
                  }
                },
              ));
        },
      ),
    ));
  }

  Padding normalTextWidget(Log log) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 2, bottom: 2, end: 10),
      child: SubstringHighlight(
        text: log.message,
        term: OmConsole.searchConroller.text,
        textStyleHighlight: TextStyle(
          backgroundColor: const Color.fromARGB(139, 0, 140, 255),
          fontSize: 16,
          color: log.textColor,
          fontWeight: FontWeight.normal,
        ),
        textStyle: TextStyle(
          fontSize: 16,
          color: log.textColor,
          backgroundColor: OmConsole.currentSearch?.id == log.id
              ? const Color.fromARGB(255, 128, 180, 129)
              : null,
        ),
      ),
    );
  }

  Container httpWidget(Log log) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10, right: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: log.backgroundColor,
        border: const Border(
          top: BorderSide(width: 1),
          bottom: BorderSide(width: 1),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SubstringHighlight(
                    text: "${log.statusCode}",
                    term: OmConsole.searchConroller.text,
                    textStyle: const TextStyle(
                      color: Color.fromARGB(255, 21, 105, 0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textStyleHighlight: const TextStyle(
                      backgroundColor: Color.fromARGB(139, 0, 140, 255),
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  SubstringHighlight(
                    text: " ${log.method} ",
                    term: OmConsole.searchConroller.text,
                    textStyle: const TextStyle(
                      color: Colors.purple,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textStyleHighlight: const TextStyle(
                      backgroundColor: Color.fromARGB(139, 0, 140, 255),
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Expanded(
                    child: SubstringHighlight(
                      text: "(${log.url})",
                      term: OmConsole.searchConroller.text,
                      textStyle: const TextStyle(
                        color: Color.fromARGB(255, 81, 132, 173),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textStyleHighlight: const TextStyle(
                        backgroundColor: Color.fromARGB(139, 0, 140, 255),
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const Divider(color: Colors.black, thickness: 0.2),
              SubstringHighlight(
                text: "Headers: ${log.headers}",
                term: OmConsole.searchConroller.text,
                textStyle: TextStyle(
                  color: log.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textStyleHighlight: const TextStyle(
                  backgroundColor: Color.fromARGB(139, 0, 140, 255),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Divider(color: Colors.black, thickness: 0.2),
              SubstringHighlight(
                text: "Body: ${log.body}",
                term: OmConsole.searchConroller.text,
                textStyle: TextStyle(
                  color: log.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textStyleHighlight: const TextStyle(
                  backgroundColor: Color.fromARGB(139, 0, 140, 255),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Divider(color: Colors.black, thickness: 0.2),
              StatefulBuilder(builder: (context, responseSetState) {
                return GestureDetector(
                    onTap: () {
                      log.expandRes = !log.expandRes;
                      responseSetState(() {});
                    },
                    child: SubstringHighlight(
                      text: "Response: ${log.response}",
                      term: OmConsole.searchConroller.text,
                      maxLines: log.expandRes ? null : 3,
                      overflow: TextOverflow.ellipsis,
                      textStyle: TextStyle(
                        color: log.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textStyleHighlight: const TextStyle(
                        backgroundColor: Color.fromARGB(139, 0, 140, 255),
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ));
              }),
            ],
          ),
          Positioned(
            right: 0,
            child: CopyWidget(
              text: log.curlCommand,
            ),
          ),
        ],
      ),
    );
  }

  Container sqlWidget(Log log) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10, right: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: log.backgroundColor,
        border: const Border(
          top: BorderSide(width: 1),
          bottom: BorderSide(width: 1),
        ),
      ),
      child: Stack(
        children: [
          SubstringHighlight(
            text: log.message,
            term: OmConsole.searchConroller.text,
            textStyle: TextStyle(
              color: log.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textStyleHighlight: const TextStyle(
              backgroundColor: Color.fromARGB(139, 0, 140, 255),
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
          Positioned(
            right: 0,
            child: CopyWidget(
              text: log.curlCommand,
            ),
          ),
        ],
      ),
    );
  }

  void selectTag(LogType? logType) {
    if (HardwareKeyboard.instance.logicalKeysPressed
        .contains(LogicalKeyboardKey.controlLeft)) {
      if (OmConsole.logTypes.contains(logType)) {
        OmConsole.logTypes.remove(logType);
      } else {
        OmConsole.logTypes.add(logType);
      }
    } else {
      OmConsole.logTypes.clear();
      OmConsole.logTypes.add(logType);
    }
  }

  MouseRegion consoleTab({required String text, LogType? logType}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          selectTag(logType);
          if (!expandedConsole || OmConsole.logTypes.isNotEmpty) {
            openConsole();
          } else {
            OmConsole.logTypes.clear();
            closeConsole();
          }
        },
        child: Container(
          padding: const EdgeInsets.only(bottom: 3),
          decoration: expandedConsole && OmConsole.logTypes.contains(logType)
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
          child: Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  void openConsole() {
    expandedConsole = true;
    consoleHeight = _lastConsoleHeight;
    screenHeight = (orgScreenHeight ?? 0) - consoleHeight + orgConsoleHeight;
    OmConsole.filterWithTags(OmConsole.searchConroller.text);
    setState(() {});
  }

  void closeConsole() {
    expandedConsole = false;
    consoleHeight = orgConsoleHeight;
    screenHeight = orgScreenHeight;
    setState(() {});
  }
}

/// A widget that allows copying text to the clipboard.
///
/// This widget displays an icon that, when tapped, copies the provided [text]
/// to the clipboard and shows a brief visual confirmation.
class CopyWidget extends StatefulWidget {
  /// Creates a [CopyWidget].
  ///
  /// The [text] parameter is required and specifies the text to be copied
  /// when the widget is tapped.
  const CopyWidget({Key? key, required this.text}) : super(key: key);

  /// The text to be copied to the clipboard when the widget is tapped.
  final String text;

  @override
  State<CopyWidget> createState() => _CopyWidgetState();
}

class _CopyWidgetState extends State<CopyWidget> {
  bool copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: StatefulBuilder(builder: (context, setStateCopy) {
        return InkWell(
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: widget.text));
            setStateCopy(() {
              copied = true;
              _timer = Timer(const Duration(seconds: 3), () {
                setStateCopy(() {
                  copied = false;
                });
              });
            });
          },
          child: Icon(
            copied ? Icons.done : Icons.copy,
            color: Colors.black,
            size: 20,
          ),
        );
      }),
    );
  }
}
