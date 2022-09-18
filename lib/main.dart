import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hypertrack_plugin/const/constants.dart';
import 'package:hypertrack_plugin/hypertrack.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  // await dotenv.load();

  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  HyperTrack _hypertrackFlutterPlugin = HyperTrack();
  final String _publishableKey =
      "LdoSqiKd51p2A1BKM7q4oQbJ2CrAzx36XF1vDCQdNAlGS7o0Gjduj8hEyGtErKzVVeAXPjLWj3zRLVUmjhyV2A";
  final String _deviceName = "DEVICE NAME";
  String _result = 'Not initialized';
  bool isRunning = false;
  late Timer timer;
  double longitude1 = 0;
  double deltaLong1 = 0;
  double latitude1 = 0;
  double deltaLat1 = 0;
  double longitude2 = 0;
  double deltaLong2 = 0;
  double latitude2 = 0;
  double deltaLat2 = 0;
  int count = 0;
  bool shouldWarn = false;
  bool isShowingPopup = false;

  @override
  void initState() {
    super.initState();
    // Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    initHyperTrack();

    this.timer = Timer.periodic(new Duration(seconds: 5), (timer) async {
      print(timer.tick);
      http.Response response1 = await http.get(
          Uri.parse(
              'https://v3.api.hypertrack.com/devices/09D92AA3-92A2-3409-B3B9-7F94F4D4F6F3/'),
          headers: {
            'Authorization':
                "Basic dHJDd0hwYS1QUVpmTG5nNFExWGZUcGJLZWZVOmxOTTljc1pYN1FYME5PQ3RrU1NjYVJSYjVlMWYtSlk1RFJhXzRta1c1V1RhREtJSE0wWk96UQ=="
          });

      http.Response response2 = await http.get(
          Uri.parse(
              'https://v3.api.hypertrack.com/devices/BADF4DC9-B768-43A6-80A7-1295B419EAC2/'),
          headers: {
            'Authorization':
                "Basic dHJDd0hwYS1QUVpmTG5nNFExWGZUcGJLZWZVOmxOTTljc1pYN1FYME5PQ3RrU1NjYVJSYjVlMWYtSlk1RFJhXzRta1c1V1RhREtJSE0wWk96UQ=="
          });

      if (response1.statusCode == 200) {
        final dynamic data1 = jsonDecode(response1.body);
        final dynamic data2 = jsonDecode(response2.body);

        setState(() {
          deltaLong1 =
              longitude1 - data1["location"]["geometry"]["coordinates"][0];
          longitude1 = data1["location"]["geometry"]["coordinates"][0];
          deltaLat1 =
              latitude1 - data1["location"]["geometry"]["coordinates"][1];
          latitude1 = data1["location"]["geometry"]["coordinates"][1];

          deltaLong2 =
              longitude2 - data2["location"]["geometry"]["coordinates"][0];
          longitude2 = data2["location"]["geometry"]["coordinates"][0];
          deltaLat2 =
              latitude2 - data2["location"]["geometry"]["coordinates"][1];
          latitude2 = data2["location"]["geometry"]["coordinates"][1];
          count++;

          shouldWarn = (latitude1 - latitude2).abs() * 10000 < 1.91 &&
              (longitude1 - longitude2).abs() * 10000 < 2.1;
        });
      } else {
        print("ERROR: ${response1.statusCode}");
      }
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    this.timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.green),
      ),
      home: Scaffold(
          appBar: AppBar(
            title: const Text('HyperTrack Quickstart'),
            centerTitle: true,
          ),
          body: ListView(
            children: [
              SizedBox(height: 10),
              ListTile(
                leading: const Text("Device name"),
                trailing: Text(
                  _deviceName,
                ),
              ),
              ButtonBar(
                alignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: isRunning ? Colors.red : Colors.green),
                    onPressed: () {
                      isRunning
                          ? _hypertrackFlutterPlugin.stop()
                          : _hypertrackFlutterPlugin.start();
                      setState(() {});
                    },
                    child: Text(isRunning ? "Stop Tracking" : "Start Tracking"),
                  ),
                  ElevatedButton(
                    onPressed: () async =>
                        _hypertrackFlutterPlugin.syncDeviceSettings(),
                    child: const Text("Sync Settings"),
                  ),
                ],
              ),
              if (shouldWarn)
                AlertDialog(
                  title: const Text('COLLISION COURSE'),
                  content: const Text('Collision Course'),
                ),
              Text("Their Long: $longitude1"),
              Text("Their Long change: $deltaLong1"),
              Text("Their Lat: $latitude1"),
              Text("Their Lat change: $deltaLat1"),
              Text("Our Long: $longitude2"),
              Text("Our Long change: $deltaLong2"),
              Text("Our Lat: $latitude2"),
              Text("Our Lat change: $deltaLat2"),
              Text("Count: $count"),
              Text("WARN: $shouldWarn"),
              Text("DELTA LAT: ${(latitude1 - latitude2).abs() * 10000}"),
              Text("DELTA LONG: ${(longitude1 - longitude2).abs() * 10000}"),
            ],
          ),
          bottomNavigationBar: ListTile(
            leading: Text("Status"),
            trailing: Text(_result),
          )),
    );
  }

  void initHyperTrack() async {
    _hypertrackFlutterPlugin = await HyperTrack().initialize(_publishableKey);
    _hypertrackFlutterPlugin.enableDebugLogging();
    _hypertrackFlutterPlugin.setDeviceName(_deviceName);
    _hypertrackFlutterPlugin.setDeviceMetadata({"source": "flutter sdk"});
    _hypertrackFlutterPlugin.onTrackingStateChanged
        .listen((TrackingStateChange event) {
      if (mounted) {
        updateButtonState();
        _result = getTrackingStatus(event);
        setState(() {});
      }
    });
  }

  void updateButtonState() async {
    final temp = await _hypertrackFlutterPlugin.isRunning();
    isRunning = temp;
    setState(() {});
  }
}

String getTrackingStatus(TrackingStateChange event) {
  Map<TrackingStateChange, String> statusMap = {
    TrackingStateChange.start: "Tracking Started",
    TrackingStateChange.stop: "Tracking Stop",
    TrackingStateChange.unknownError: "Unknown Error",
    TrackingStateChange.authError: "Authentication Error",
    TrackingStateChange.networkError: "Network Error",
    TrackingStateChange.invalidToken: "Invalid Token",
    TrackingStateChange.locationDisabled: "Location Disabled",
    TrackingStateChange.permissionsDenied: "Permissions Denied",
  };
  if (statusMap[event] == null) {
    throw Exception("Unexpected null value in getTrackingStatus");
  }
  return statusMap[event]!;
}
