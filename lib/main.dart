import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'global.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Global.init();
  runApp(const MyApp());
  doWhenWindowReady(() {
    const initialSize = Size(400, 600);
    appWindow.minSize = const Size(300, 450);
    appWindow.size = initialSize;
    // appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Global(),
      builder: (context, child) {
        final mode = context.select<Global, ThemeMode>((value) => value.mode);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.blue,
            useMaterial3: true,
          ),
          themeMode: mode,
          title: 'md2report',
          initialRoute: '/',
          routes: {'/': (context) => const HomePage()},
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String file = '';
  String terminal = '';
  int converting = 0;

  Future<void> chooseFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['md']);

    if (result != null) {
      file = result.files.single.path ?? '';
      converting = 0;
    }

    setState(() {});
  }

  Future<void> generate() async {
    File out = File('bin/output.docx');
    if (out.existsSync()) {
      out.deleteSync();
    }
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
              content: SizedBox(
                height: 50,
                width: 50,
                child: Center(child: LinearProgressIndicator()),
              ),
            ));
    await Future.delayed(const Duration(milliseconds: 200));
    await convert();
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
    setState(() {
      converting = 1;
    });
    out = File('bin/output.docx');

    // ignore: use_build_context_synchronously
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: out.existsSync()
                  ? Text('Output file: ${out.path}')
                  : const Text("An error occurred"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"))
              ],
            ));
  }

  Future<void> convert() async {
    try {
      final result = await Process.run('run.bat', [file]);
      terminal = '${result.stdout}\n${result.stderr}';
    } catch (e) {
      terminal = e.toString();
    }
  }

  void checkPandoc() async {
    try {
      await Process.run('pandoc', ['-h']);
    } catch (e) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text("Error"),
                content: const Text("Please install Pandoc first."),
                actions: [
                  TextButton(
                      onPressed: () {
                        _launchUrl("https://pandoc.org/installing.html");
                      },
                      child: const Text("Pandoc Home Page"))
                ],
              ));
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri sourceUrl = Uri.parse(url);

    if (!await launchUrl(sourceUrl)) {
      throw 'Could not launch $sourceUrl';
    }
  }

  @override
  void initState() {
    super.initState();
    checkPandoc();
  }

  @override
  Widget build(BuildContext context) {
    final global = context.watch<Global>();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(46.0),
        child: Row(children: [
          WindowTitleBarBox(
            child: MoveWindow(
              child: const Padding(
                padding: EdgeInsets.only(left: 9, right: 9),
                child: FlutterLogo(),
              ),
            ),
          ),
          WindowTitleBarBox(
            child: MoveWindow(
              child: const Padding(
                padding: EdgeInsets.only(left: 9, right: 9),
                child: Text(
                  "md2report",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                WindowTitleBarBox(
                  child: Row(
                    children: [
                      Expanded(child: MoveWindow()),
                      const WindowButtons(),
                    ],
                  ),
                ),
              ],
            ),
          )
        ]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    showAboutDialog(
                      context: context,
                      applicationName: "md2report",
                      applicationVersion: "1.1.0",
                      applicationIcon: const FlutterLogo(),
                      children: [
                        const Center(child: Text("Author: alfie")),
                        const Center(child: Text("Thanks to")),
                        const Center(
                          child: Text("woolen-sheep/md2report"),
                        )
                      ],
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "The selected file:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () async {
                      global.mode = global.mode == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                      await Global().save('mode', global.mode.index.toString());
                    },
                    icon: Icon(global.mode == ThemeMode.light
                        ? Icons.light_mode
                        : Icons.dark_mode)),
              ],
            ),
            Text(
              file,
              style: const TextStyle(fontSize: 14),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (file.isNotEmpty && converting == 1)
                    Container(
                      color: Colors.black12,
                      child: ListView(
                        children: [
                          SelectableText(
                            terminal,
                            // style: const TextStyle(color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  if (file.isNotEmpty)
                    Center(
                      child: FilledButton(
                        onPressed: generate,
                        child: const Text("Start converting"),
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: FilledButton(
                onPressed: () async {
                  await chooseFile();
                },
                child: const Text("File Select"),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColors = WindowButtonColors(
        iconNormal: Theme.of(context).iconTheme.color,
        mouseOver: Colors.grey.shade300,
        mouseDown: Colors.grey.shade400,
        iconMouseOver: Colors.black,
        iconMouseDown: Colors.black);

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: Theme.of(context).iconTheme.color,
      iconMouseOver: Colors.white,
    );
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
