import 'dart:async';
import 'dart:ui';
import 'package:om_console/om_console.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

// ignore: must_be_immutable
class ConsoleWrapper extends StatefulWidget {
  ConsoleWrapper({super.key, required this.child});

  Widget child;

  @override
  State<ConsoleWrapper> createState() => _ConsoleWrapperState();
}

class _ConsoleWrapperState extends State<ConsoleWrapper>
    with WidgetsBindingObserver {
  double? orgScreenHeight;
  double orgConsoleHeight = 30;

  double? screenHeight;
  double consoleHeight = 30;
  double _lastConsoleHeight = 300;
  bool expandedConsole = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool scrollToBottom = true;
  bool copied = false;
  bool multiFilter = false;

  @override
  void didChangeDependencies() {
    orgScreenHeight = MediaQuery.of(context).size.height - orgConsoleHeight;
    screenHeight = orgScreenHeight;
    super.didChangeDependencies();
  }

  @override
  void initState() {
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_scrollController.position.atEdge) {
          scrollToBottom = false;
        }
        setState(() {});
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_scrollController.position.atEdge) {
          scrollToBottom = true;
        }
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(() {});
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = (screenHeight! <= (orgScreenHeight! / 3))
        ? (orgScreenHeight! / 3)
        : screenHeight;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          ListView(
            children: [
              SizedBox(
                height: screenHeight,
                child: widget.child,
              ),
              MaterialApp(
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
                    backgroundColor: Colors.red,
                    body: Container(
                      color: const Color.fromARGB(255, 37, 37, 37),
                      child: Column(children: [
                        if (expandedConsole) const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 37, 37, 37),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 0),
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 5,
                                )
                              ]),
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              const Spacer(),
                              if (expandedConsole)
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 250,
                                      child: TextField(
                                        controller: OmConsole.searchConroller,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                        onChanged: OmConsole.search,
                                        decoration: const InputDecoration(
                                            fillColor: Color.fromARGB(
                                                255, 117, 117, 117),
                                            filled: true,
                                            contentPadding: EdgeInsets.all(5),
                                            isDense: true,
                                            hintText: "Search...",
                                            border: InputBorder.none,
                                            hintStyle: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 199, 199, 199))),
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
                                          color: Color.fromARGB(
                                              255, 197, 197, 197),
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
                                ),
                            ],
                          ),
                        ),
                        if (expandedConsole)
                          Expanded(
                              child: SelectionArea(
                            child: ValueListenableBuilder<List<Log>>(
                              valueListenable: OmConsole.logs,
                              builder: (BuildContext context, List<Log> value,
                                  child) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!_scrollController.position.atEdge) {
                                    scrollToBottom = true;
                                    setState(() {});
                                  }
                                });

                                return Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 10),
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: value.length,
                                    itemBuilder: (context, i) {
                                      Log log = value[i];
                                      if (log.type == LogType.http) {
                                        return httpWidget(log);
                                      } else {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2),
                                          child: Text(
                                            log.message,
                                            style:
                                                TextStyle(color: log.textColor),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          )),
                      ]),
                    ),
                  ),
                ),
              )
            ],
          ),
          if (expandedConsole)
            Positioned(
              top: screenHeight,
              left: 0,
              right: 0,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    consoleHeight = (consoleHeight - details.primaryDelta!)
                        .clamp(30, MediaQuery.of(context).size.height - 50);
                    screenHeight = (orgScreenHeight ?? 0) -
                        consoleHeight +
                        orgConsoleHeight;
                    _lastConsoleHeight = consoleHeight;
                  });
                },
                child: Container(
                  color: const Color.fromARGB(255, 82, 82, 82),
                  child: const Center(
                      child: Icon(
                    Icons.drag_handle,
                    color: Colors.white,
                    size: 10,
                  )),
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
                      if (scrollToBottom) {
                        _scrollController
                            .jumpTo(_scrollController.position.maxScrollExtent);
                        scrollToBottom = false;
                      } else {
                        _scrollController
                            .jumpTo(_scrollController.position.minScrollExtent);
                        scrollToBottom = true;
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
                        scrollToBottom
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
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: "${log.statusCode}  ",
                    style: const TextStyle(
                      color: Color.fromARGB(255, 21, 105, 0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: "${log.method} ",
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text: "(",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: "${log.url})",
                    style: const TextStyle(
                        color: Color.fromARGB(255, 81, 132, 173),
                        fontSize: 14),
                  ),
                ]),
                style: TextStyle(color: log.textColor, fontSize: 14),
              ),
              const Divider(color: Colors.black, thickness: 0.2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Headers: ${log.headers}",
                      style: TextStyle(color: log.textColor, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(
                          text: "Body: ",
                        ),
                        TextSpan(
                          text: log.body,
                        ),
                      ]),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 85, 83, 0),
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.black, thickness: 0.2),
              StatefulBuilder(builder: (context, responseSetState) {
                return GestureDetector(
                  onTap: () {
                    log.expandRes = !log.expandRes;
                    responseSetState(() {});
                  },
                  child: Text(
                    "Response: ${log.response}",
                    overflow: TextOverflow.ellipsis,
                    maxLines: log.expandRes ? null : 3,
                    style: TextStyle(color: log.textColor, fontSize: 12),
                  ),
                );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollOffset);
    });
    setState(() {});
  }

  void closeConsole() {
    _scrollOffset = _scrollController.offset;
    expandedConsole = false;
    consoleHeight = orgConsoleHeight;
    screenHeight = orgScreenHeight;
    setState(() {});
  }
}

class CopyWidget extends StatefulWidget {
  const CopyWidget({super.key, required this.text});

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
