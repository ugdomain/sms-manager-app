import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readsms/readsms.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;


sendData(){
  print('Hiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii');
}

@pragma('vm:entry-point')
const taskName = 'firstTask';
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    switch(task){
      case 'firstTask' :
        sendData();
        break;
      default:
    }
    return Future.value(true);
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Workmanager().initialize(callbackDispatcher,isInDebugMode: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  void initState(){
    super.initState();
    getPermission().then((value) {
      if (value) {
        _plugin.read();
        _plugin.smsStream.listen((event) {
          setState(() {
            messages.add(Messages(
                sms: event.body,
                sender: event.sender,
                time: event.timeReceived.toString()));
            // Store incoming SMS in GetStorage when received
            storeMessages();
          });
        });
      }
    });
    loadStoredMessages();
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

  TextEditingController textController = TextEditingController();
  String? simpleText;
  final data = GetStorage;

  // Load stored messages from GetStorage
  void loadStoredMessages() {
    // Initialize GetStorage instance
    final box = GetStorage();

    // Retrieve stored messages from GetStorage
    final storedMessages = box.read<List>('messages') ?? [];

    // Convert stored message maps to Messages objects
    messages = storedMessages.map((map) => Messages.fromMap(map)).toList();
  }
  // Store messages in GetStorage
  void storeMessages() {
    // Initialize GetStorage instance
    final box = GetStorage();

    // Clear existing messages to avoid duplication
    box.remove('messages');

    // Store messages list in GetStorage
    box.write('messages', messages.map((message) => message.toMap()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
             Padding(
               padding: const EdgeInsets.all(14.0),
               child: TextField(
                controller: textController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 5,horizontal: 15)
                ),
                           ),
             ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message : ${message.sms}',
                        ),
                        Text(
                          'Sender : ${message.sender}',
                        ),
                        Text(
                          'Time : ${message.time}',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(
              height: 50,
            ),
            CupertinoButton(
              color: Colors.blue,
                child: Text('Send'),
                onPressed: ()async{
                var uniqueId = DateTime.now().second.toString();
                await Workmanager().registerOneOffTask(uniqueId, taskName,
                    initialDelay: Duration(seconds: 10),
                  constraints: Constraints(networkType: NetworkType.connected)
                );
                  // setState(() {
                  //   simpleText = textController.text;
                  //   textController.clear();
                  // });
                }
            ),
            SizedBox(height: 15,),
            Text('Url/Api end point',style: TextStyle(fontSize: 16),),
            SizedBox(height: 10),
            Text('${simpleText ?? 'No Url added'}'),
          ],
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

  // Convert Messages object to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'sms': sms,
      'sender': sender,
      'time': time,
    };
  }

  // Convert a Map object to a Messages object
  Messages.fromMap(Map<String, dynamic> map) {
    sms = map['sms'];
    sender = map['sender'];
    time = map['time'];
  }

  // Convert Messages object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'sms': sms,
      'sender': sender,
      'time': time,
    };
  }
}

void postMessages(List<Messages> messages, String url) async {
  try {
    var request = jsonEncode(messages.map((e) => e.toJson()).toList()); // Fix syntax error
    var response = await http.post(Uri.parse(url), body: request); // Use await for async method
    if (response.statusCode == 200) {
      print("Data successfully posted to the API");
      print(response.body);
    } else {
      print("Error in posting messages to API: ${response.statusCode}");
    }
  } catch (error) {
    print("Error in posting messages to API: $error");
  }
}

