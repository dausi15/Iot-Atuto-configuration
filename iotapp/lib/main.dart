import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wifi_hunter/wifi_hunter.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // WiFiInfoWrapper _wifiObject;
  FlutterBlue flutterBlue;

  @override
  void initState() {
    scanWiFi();
    flutterBlue = FlutterBlue.instance;
    super.initState();
  }

  Future<WiFiInfoWrapper> scanWiFi() async {
    WiFiInfoWrapper wifiObject;

    try {
      wifiObject = await WiFiHunter.huntRequest;
    } on PlatformException {}

    return wifiObject;
  }

  // Future<void> scanHandler() async {
  //   _wifiObject = await scanWiFi();
  //   debugPrint("WiFi Results (SSIDs) : ");
  //   for (var i = 0; i < _wifiObject.ssids.length; i++) {
  //     debugPrint(
  //         "- " + _wifiObject.ssids[i] + " - bssid: " + _wifiObject.bssids[i]);
  //   }
  // }

  Future<List<Wifi>> getWifis() async {
    // var data = await scanWiFi();
    List<Wifi> wifis = [];

    // for (var i = 0; i < data.ssids.length; i++) {
    //   Wifi wifi = Wifi(data.ssids[i], data.bssids[i]);

    //   wifis.add(wifi);
    // }
    // print(wifis.length);
    // return wifis;
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    // Listen to scan results
    var subscription = flutterBlue.scanResults.listen((results) {
        // do something with scan results
        for (ScanResult r in results) {
            debugPrint('${r.device.name} found! rssi: ${r.rssi}');
        }
    });
    return wifis;
  }

  @override
  Widget build(BuildContext context) {
    // scanHandler();

    return MaterialApp(
        home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.directions_car)),
                Tab(icon: Icon(Icons.directions_transit)),
                Tab(icon: Icon(Icons.directions_bike)),
              ],
            ),
            title: Text('IoT Config App'),
          ),
          body: TabBarView(
            children: [
              FrontPage(getWifis()),
              Icon(Icons.directions_transit),
              Icon(Icons.directions_bike),
            ],
          ),
        ),
      ),
    );
  }
}

class FrontPage extends StatelessWidget{
  final Future<List<Wifi>> wifis;
  FrontPage(this.wifis);
  @override
  Widget build(BuildContext context){
    return Material(
      child: Container(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                  Text(
                    'SSID',
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: 'Enter a search term'),
                  ),
                  Expanded(
                    child: FutureBuilder(
                        future: wifis,
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.data == null) {
                            return Container(
                              child: Center(child: Text("Loading..")),
                            );
                          } else {
                            return ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount: snapshot.data.length,
                              itemBuilder: (BuildContext context, int index) {
                                return ListTile(
                                  title: Text(
                                      "ssid: " + snapshot.data[index].ssid),
                                  subtitle: Text(
                                      "bssid: " + snapshot.data[index].bssid),
                                );
                              },
                            );
                          }
                        }),
                  )
                ]),
              ),
            )
    );
  }
}

class Wifi {
  final String ssid;
  final String bssid;

  Wifi(this.ssid, this.bssid);
}
