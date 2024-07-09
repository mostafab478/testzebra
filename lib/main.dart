
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zebra_rfid_reader_sdk/zebra_rfid_reader_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  List<String> tags = [];

  final _zebraRfidReaderSdkPlugin = ZebraRfidReaderSdk();
  List<DropdownMenuItem> dropDowns = [];
  String device = '';
  Future<void> requestAccess() async {
    var status = await Permission.bluetoothConnect.request();
    var scanStatus = await Permission.bluetoothScan.request();
    if(!status.isGranted && !scanStatus.isGranted) return;
    _zebraRfidReaderSdkPlugin.getAvailableReaderList().then((value) {
      try {
        if (value.isNotEmpty){
          for (var element in value) {
            dropDowns.add(DropdownMenuItem(child: Text(element.name??""),onTap: () {
              print(element);
              device = element.name??"";

            },value: element.name,));
            setState(() {});
          }
          // _zebraRfidReaderSdkPlugin.connect(value.first.name.toString())
          //     .onError((error, stackTrace) =>
          //     print('Error Connecting :: $error'));
          // _zebraRfidReaderSdkPlugin.connectedReaderDevice.listen((event) {
          //   final result = jsonDecode(event.toString());
          //   log("::::::::::::::::::::::::::::::::::::::::::::::::Result::::::::::::::::::::::::::::::::::::::::::$result");
          // });
          // _zebraRfidReaderSdkPlugin.getTagList().then((value) => print('::::::::::::::::::::::::::::Result111111::::::::::::::::::::::::::${value}')).onError((error, stackTrace) => print("eeeeeee:::::::::::::::::::$error"));
        }else{
          print('::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;No Devices');
        }
      } catch (e) {
        print(e);
      }
    });
  }
  static const EventChannel _eventChannel = EventChannel('zebra_rfid_reader');

  static Stream<String> get tagStream {
    return _eventChannel.receiveBroadcastStream().map((event) => event);
  }

  convertHex(hex){
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    String decodedString = ascii.decode(bytes);
    return decodedString;
  }
  readTags() async {
          tagStream.listen((tagIDs) {
              print('Tag read ::: $tagIDs');
              List<String> tagsList=tagIDs.replaceAll(' ', '').split(',');

              for(String tag in tagsList){
                if(!tags.contains(tag) && tag.length == 24){

                  print("dddd${convertHex(tag)}");
                  tags.add(tag);
                  print("tags:::::::::::::::::::::::::::::::::::::$tags");
                }
              }
              setState(() {

              });
              // if(tagIDs is List<dynamic>){
              //   for(int i = 0; i <= tagIDs.length; i++){
              //     if(!tags.contains(tagIDs[i])){
              //       tags.add(tagIDs[i]);
              //     }
              //   }
              // }else if(tags.contains(tagIDs) == false){
              //   setState(() {
              //   tags.add(tagIDs);
              //   });
              // }else{
              //   print('tage repeated');
              // }
          });
        }
@override
  void initState() {
  requestAccess().then((value) {

    readTags();
  });
  super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: SizedBox(height: MediaQuery.of(context).size.height,
          child: Column(crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              DropdownButtonFormField(items: dropDowns, onChanged: (value) {
              },),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: () {
                    _zebraRfidReaderSdkPlugin.disconnect();
                    tags.clear();
                    setState(() {});
                  }, child: const Text('disconnect')),
                  ElevatedButton(onPressed: () {
                    tags.clear();
                    setState(() {});
                  }, child: const Text('reset')),
                  ElevatedButton(onPressed: () {
                    if(device.isNotEmpty)
                    _zebraRfidReaderSdkPlugin.connect(device);
                  }, child: const Text('connect')),
                ],
              ),
              const SizedBox(height: 100,),
              SizedBox(height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                child: ListView.builder(
                  itemBuilder:
                (context, i) => Center(child: Text(tags[i])),
                itemCount: tags.length,),
              ),
              const Text(
                'Tags you have',
              ),
              Text(
                '${tags.length}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
