import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readsms/readsms.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    // Your background task logic goes here
    return Future.value(true);
  });
}
void main() {


}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Manager App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'SMS Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _plugin = Readsms();
  List<Messages> messages = [];

  @override
  void initState() {
    getPermission().then((value) {
      if (value) {
        _plugin.read();
        _plugin.smsStream.listen((event) {
          setState(() {
            messages.add(Messages(
                sms: event.body,
                sender: event.sender,
                time: event.timeReceived.toString()));
          });
        });
      }
    });
    super.initState();
  }

  Future<bool> getPermission() async {
    if (await Permission.sms.status == PermissionStatus.granted) {
      return true;
    } else {
      if (await Permission.sms.request() == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ...messages.map((e) => Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message : ${e.sms}',
                        ),
                        Text(
                          'Sender : ${e.sender}',
                        ),
                        Text(
                          'Time : ${e.time}',
                        ),
                      ],
                    ),
                  ),
                )).toList(),
                const SizedBox(height: 50,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Messages {
  String? sms;
  String? sender;
  String? time;

  Messages({this.sms, this.time, this.sender});
}
