import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:system_setting/system_setting.dart';
import 'dart:async';
import 'package:wifi_hunter/wifi_hunter.dart';
import 'package:flutter/services.dart';


BluetoothState state;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BLE Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter BLE Demo'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //BluetoothDevice _connectedDevice;
  //List<BluetoothService> _services;
  bool autoMode = false;
  WiFiInfoWrapper _wifiObject;

  Future<WiFiInfoWrapper> scanWiFi() async {
    WiFiInfoWrapper wifiObject;

    try {
      wifiObject = await WiFiHunter.huntRequest;
    } on PlatformException {
      debugPrint("did not work");
    }

    return wifiObject;
  }

  Future<Map<String, int>> scanHandler() async {
    _wifiObject = await scanWiFi();
    var wifiStrenghts = new Map<String, int>();
    //var wifiNames = new Map<String, String>();
    print("WiFi Results (SSIDs) : ");
    for (var i = 0; i < _wifiObject.ssids.length; i++) {
      wifiStrenghts[_wifiObject.bssids[i].toString()] = _wifiObject.signalStrengths[i];
      //wifiNames[_wifiObject.bssids[i].toString()] = _wifiObject.ssids[i];
      //debugPrint("- " + _wifiObject.ssids[i]+ "   bssid: "+ _wifiObject.bssids[i] + " : " + _wifiObject.signalStrengths[i].toString());
    }
    var sortedMap = Map.fromEntries(
    wifiStrenghts.entries.toList()
    ..sort((e1, e2) => e2.value.compareTo(e1.value)));
    return sortedMap;
  }

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

/*   _removeFromDeviceList(final List<ScanResult> results) {
    for (BluetoothDevice device in widget.devicesList) {
      if (!results.contains(device)) {
        setState(() {
          widget.devicesList.remove(device);
        });
      }
    }
  } */

  _clearDevices() {
    //debugPrint(widget.devicesList.length.toString());
    widget.devicesList.clear();
    widget.flutterBlue.stopScan();
    widget.flutterBlue.startScan(timeout: Duration(seconds: 2));

    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      /* _setDevicelist(results); */
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
      //widget.devicesList.sort();
      //_removeFromDeviceList(results);
    });
    //widget.flutterBlue.stopScan();
  }

/*     _setDevicelist(final List<ScanResult> results) {
      widget.devicesList.clear();
      for (ScanResult result in results) {
        widget.devicesList.add(result.device);
      }
  } */

  @override
  void initState() {
    scanWiFi();
    super.initState();
    FlutterBlue.instance.state.listen((state) {
      if (state == BluetoothState.off) {
        //Alert user to turn on bluetooth.
        _jumpToSetting();
      } else if (state == BluetoothState.on) {
        widget.flutterBlue.connectedDevices
            .asStream()
            .listen((List<BluetoothDevice> devices) {
          for (BluetoothDevice device in devices) {
            _addDeviceTolist(device);
          }
        });
        const fiveSeconds = const Duration(seconds: 5);
        Timer.periodic(fiveSeconds, (Timer t) => _clearDevices());
      }
    });
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = new List<Container>();
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              FlatButton(
                color: Colors.blue,
                child: Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  widget.flutterBlue.stopScan();
                  try {
                    await device.connect();
                  } catch (e) {
                    if (e.code != 'already_connected') {
                      throw e;
                    }
                  } finally {
                    //_services = await device.discoverServices();
                  }
                  setState(() {
                    //_connectedDevice = device;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  Widget _buildView() {
    return new MyCustomForm();
  }

  ListView _buildInputForms() {
    return _buildListViewOfDevices();
  }

  Widget myLayoutWidget() {
    return new Column(
      children: <Widget>[
        Expanded(child: _buildView()),
        Expanded(child: _buildInputForms())
      ],
    );
  }

  void printWifis(){
    scanHandler().asStream().listen((event) {
      debugPrint(event.toString());
    });
  }
//https://pub.dev/packages/dropdown_formfield
  @override
  Widget build(BuildContext context) {
  //scanHandler(); 
  return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Switch(
            value: autoMode,
            onChanged: (value) {
                  printWifis();
              setState(() {
                autoMode = value;
                //print(autoMode);
              });
            },
            activeTrackColor: Colors.lightGreenAccent,
            activeColor: Colors.green,
          ),
        ],
      ),
      body: myLayoutWidget() //_buildView()
      );
  }

  _jumpToSetting() {
    SystemSetting.goto(SettingTarget.BLUETOOTH);
  }
}

class MyCustomForm extends StatefulWidget {
  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

/* class Wifi {
  final String ssid;
  final String bssid;

  Wifi(this.ssid, this.bssid);
} */

class MyCustomFormState extends State<MyCustomForm> {
  
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
    var ssidTextController = new TextEditingController();
    var passwordTextController = new TextEditingController();
    var serverTextController = new TextEditingController();

  Container inputContainer(String input, TextEditingController _controller, IconData icon) {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    icon: Icon(icon),
                    hintText: 'What do people call you?',
                    labelText: input.toUpperCase(),
                  ),
                  controller: _controller,
                  onSaved: (String value) {
                    // This optional block of code can be used to run
                    // code when the user saves the form.
                  },
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    Container ssid = inputContainer("ssid", ssidTextController, Icons.network_wifi);
    Container password = inputContainer("password", passwordTextController, Icons.lock);
    Container server = inputContainer("server", serverTextController, Icons.computer);
    return Form(
        key: _formKey,
        child: Column(children: <Widget>[
          // Add TextFormFields and RaisedButton here.
          ssid,
          password,
          server,
          FlatButton(
              color: Colors.blue,
              child: Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                return showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      // Retrieve the text the that user has entered by using the
                      // TextEditingController.
                      content: Text(
                      ssidTextController.text + "\n"+
                      passwordTextController.text + "\n"+
                      serverTextController.text + "\n"),
                    );
                  },
                );
              })
        ]));
  }
}

