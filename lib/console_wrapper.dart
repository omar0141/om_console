import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:om_console/om_console.dart';

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

class _ConsoleWrapperState extends State<ConsoleWrapper> {
  double? orgScreenHeight;
  double orgConsoleHeight = 30;

  double? screenHeight;
  double consoleHeight = 30;
  double _lastConsoleHeight = 300;
  bool expandedConsole = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    orgScreenHeight ??= MediaQuery.of(context).size.height - orgConsoleHeight;
    screenHeight ??= orgScreenHeight;
    screenHeight = (screenHeight! <= (orgScreenHeight! / 3))
        ? (orgScreenHeight! / 3)
        : screenHeight;

    return runZoned(
      () {
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
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (!expandedConsole) {
                                          openConsole();
                                        } else {
                                          closeConsole();
                                        }
                                      },
                                      child: Container(
                                        decoration: expandedConsole
                                            ? const BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    width: 1,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              )
                                            : null,
                                        child: const Text(
                                          "Console",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (expandedConsole)
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 250,
                                          child: TextField(
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                            onChanged: Console.search,
                                            decoration: InputDecoration(
                                                fillColor: Color.fromARGB(
                                                    255, 117, 117, 117),
                                                filled: true,
                                                contentPadding:
                                                    EdgeInsets.all(5),
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
                                              Console.clear();
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
                                  valueListenable: Console.logs,
                                  builder: (BuildContext context,
                                      List<Log> value, child) {
                                    return Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 10),
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        itemCount: value.length,
                                        itemBuilder: (context, i) {
                                          Log log = value[i];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2),
                                            child: Text(
                                              log.message,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          );
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
            ],
          ),
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          Console.log(line);
        },
      ),
    );
  }

  void openConsole() {
    expandedConsole = true;
    consoleHeight = _lastConsoleHeight;
    screenHeight = (orgScreenHeight ?? 0) - consoleHeight + orgConsoleHeight;
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
