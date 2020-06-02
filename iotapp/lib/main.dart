import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:system_setting/system_setting.dart';
import 'dart:async';
import 'package:wifi_hunter/wifi_hunter.dart';
import 'package:flutter/services.dart';
//import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' show utf8;

BluetoothState state;
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'IoT Autoconf',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'IoT Autoconf'),
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
  BluetoothDevice _connectedDevice;
  BluetoothCharacteristic targetCharacteristic;
  final String SERVICE_UUID = "3f1a9658-a035-11ea-bb37-0242ac130002";
  final String CHARACTERISTIC_UUID = "3f1a987e-a035-11ea-bb37-0242ac130002";
  bool autoMode = false;
  WiFiInfoWrapper _wifiObject;
  bool connecting = false;

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
    for (var i = 0; i < _wifiObject.ssids.length; i++) {
      wifiStrenghts[_wifiObject.bssids[i].toString()] =
          _wifiObject.signalStrengths[i];
    }
    var sortedMap = Map.fromEntries(wifiStrenghts.entries.toList()
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

  _clearDevices() {
    widget.devicesList.clear();
    widget.flutterBlue.stopScan();
    widget.flutterBlue.startScan(timeout: Duration(seconds: 2)); 

    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      /* _setDevicelist(results); */
      for (ScanResult result in results) {
        if (result.device.name == "UART Service") {
          _addDeviceTolist(result.device);
        }
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
        clearDeviceView();
        //_clearDevices();
      }
    });
  }

  clearDeviceView() {
    const fiveSeconds = const Duration(seconds: 5);
    if (!connecting) {
      Timer.periodic(fiveSeconds, (Timer t) => _clearDevices());
    }
    debugPrint(widget.devicesList.toString());
  }

  discoverServices() async {
    final store = await SharedPreferences.getInstance();
    if (_connectedDevice == null) { 
      return;
    }

    List<BluetoothService> services = await _connectedDevice.discoverServices();
    print(_connectedDevice.name);
    services.forEach((service) {
      print("service: " + service.uuid.toString());
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristics) {
          print(characteristics.uuid.toString());
          if (characteristics.uuid.toString() == CHARACTERISTIC_UUID) {
            targetCharacteristic = characteristics;
            /* setState(() {
              connectionText = "All Ready with ${targetDevice.name}";
            }); */
          }
        });
      }
    });
    String ssid = store.getString("ssid");
    String identity = store.getString("identity");
    String password = store.getString("password");
    String server = store.getString("server");
    if (ssid != null) {
      writeData(ssid + ";" + identity + ";" + password + ";" + server);
    }
  }

  String dataClassifier(int value) {
    return "[" + value.toString() + "]";
  }

  writeData(String data) async {
    debugPrint(data);
    if (targetCharacteristic == null) return;
    print("writing: " + data);
    List<int> bytes = utf8.encode(data);
    await targetCharacteristic.write(bytes);
    _connectedDevice.disconnect();
    connecting = false;
    //clearDeviceView();
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
                  connecting = true;
                  debugPrint("should connect");
                  try {
                    print("device.connect");
                    await device.connect();
                  } catch (e) {
                    if (e.code != 'already_connected') {
                      throw e;
                    }
                  } finally {
                    print("finally connect");
                    //_services = await device.discoverServices();
                  }
                  setState(() {
                    _connectedDevice = device;
                  });
                  discoverServices();
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

  Future<List<String>> printWifis() async {
    List<String> wifis = new List<String>();
    scanHandler().asStream().listen((event) {
      //debugPrint(event.toString());
      for (var x in event.entries) {
        wifis.add(x.key.toString());
      }
      //wifis.add(event.toString());
    });
    return wifis;
  }

  Future<String> getClosestWifi() async {
    List<String> wifis = new List<String>();
    scanHandler().asStream().listen((event) {
      //debugPrint(event.toString());
      for (var x in event.entries) {
        wifis.add(x.key.toString());
      }
      //wifis.add(event.toString());
    });
    return wifis.toString();
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
  //String _myActivity;
  //String _myActivityResult;
  final dropdownFormKey = new GlobalKey<FormState>();
  var ssidTextController = new TextEditingController();
  var identityTextController = new TextEditingController();
  var passwordTextController = new TextEditingController();
  var serverTextController = new TextEditingController();

  final GlobalKey<FormState> _formKey2 = GlobalKey<FormState>();
  TextEditingController _typeAheadController = TextEditingController();
  String _selectedCity;
  Future<List<String>> wifiSuggenstions;

  @override
  void initState() {
    super.initState();
    wifiSuggenstions = _MyHomePageState().printWifis();
    SharedPreferences.getInstance().then((value) {
      ssidTextController.text = value.getString("ssid");
      identityTextController.text = value.getString("identity");
      passwordTextController.text = value.getString("password");
      serverTextController.text = value.getString("server");
    });
    //_myActivity = '';
    //_myActivityResult = '';
  }

  _saveForm() {
    var form = dropdownFormKey.currentState;
    if (form.validate()) {
      form.save();
      setState(() {
        //_myActivityResult = _myActivity;
      });
    }
  }

  Container inputContainer(
      String input, TextEditingController _controller, IconData icon) {
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
    Container ssid =
        inputContainer("ssid", ssidTextController, Icons.network_wifi);
    Container identity =
        inputContainer("identity", identityTextController, Icons.network_wifi);
    Container password =
        inputContainer("password", passwordTextController, Icons.lock);
    Container server =
        inputContainer("server", serverTextController, Icons.computer);
    return Form(
        key: _formKey,
        child: ListView(children: <Widget>[
          // Add TextFormFields and RaisedButton here.
          ssid,
          identity,
          password,
          server,
          FlatButton(
              color: Colors.blue,
              child: Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                final store = await SharedPreferences.getInstance();
                store.setString("ssid", ssidTextController.text.toString());
                store.setString(
                    "identity", identityTextController.text.toString());
                store.setString(
                    "password", passwordTextController.text.toString());
                store.setString("server", serverTextController.text.toString());
                return showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        // Retrieve the text the that user has entered by using the
                        // TextEditingController.
                        content: Text(
                          ssidTextController.text +
                              "\n" +
                              passwordTextController.text +
                              "\n" +
                              serverTextController.text +
                              "\n" +
                              store.getString("ssid"),
                        ),
                      );
                    });
              }),
          //dropDownForm(_typeAheadController, _formKey2, _selectedCity)
        ]));
  }

  Widget dropDownForm(TextEditingController _typeAheadController,
      GlobalKey<FormState> _formKey, String _selectedCity) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          children: <Widget>[
            Text('Located in:'),
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _typeAheadController,
                decoration: InputDecoration(
                  labelText: 'Room',
                ),
              ),
              suggestionsCallback: (pattern) async {
                //_typeAheadController.text = await wifiSuggenstions.first;
                return await wifiSuggenstions;
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              transitionBuilder: (context, suggestionsBox, controller) {
                return suggestionsBox;
              },
              onSuggestionSelected: (suggestion) {
                _typeAheadController.text = suggestion;
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                  Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text('Current room is ${_selectedCity}')));
                }
              },
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please select a room';
                }
              },
              onSaved: (value) => _selectedCity = value,
            )
          ],
        ),
      ),
    );
  }
}
