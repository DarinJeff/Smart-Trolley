import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_trolley/pages/radar_map.dart';
import 'package:smart_trolley/pages/select_device.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePage createState() => new _HomePage();
}

class _HomePage extends State<HomePage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  bool _autoAcceptPairingRequests = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Text(
          'Smart Trolley',
          style: GoogleFonts.abrilFatface(
              color: Colors.black, fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: RadialGradient(colors: [
          Color(0xDD505050),
          Colors.black,
        ], radius: 1)),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 10,
            ),
            ListTile(
                title: Text(
              'Bluetooth Setup',
              style: GoogleFonts.openSans(fontSize: 20, color: Colors.white),
            )),
            Divider(color: Colors.blueGrey),
            SizedBox(
              height: 10,
            ),
            SwitchListTile(
              activeColor: Colors.green,
              title: const Text(
                'Enable Bluetooth',
                style: TextStyle(color: Colors.white),
              ),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                future() async {
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            Divider(color: Colors.blueGrey),
            SizedBox(
              height: 10,
            ),
            ListTile(
              title: const Text('Bluetooth status',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                  _bluetoothState == BluetoothState.STATE_ON
                      ? 'Bluetooth ON'
                      : _bluetoothState == BluetoothState.STATE_OFF
                          ? 'Bluetooth OFF'
                          : _bluetoothState == BluetoothState.STATE_TURNING_OFF
                              ? 'Turning OFF BlueTooth'
                              : _bluetoothState ==
                                      BluetoothState.STATE_TURNING_ON
                                  ? 'Turning ON BlueTooth'
                                  : 'Bluetooth State Unknown',
                  style: TextStyle(color: Colors.white)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.green),
                child: const Text('Settings',
                    style: TextStyle(color: Colors.black)),
                onPressed: () {
                  FlutterBluetoothSerial.instance.openSettings();
                },
              ),
            ),
            Divider(color: Colors.blueGrey),
            Spacer(),
            ElevatedButton(
                child: Icon(FontAwesomeIcons.bluetoothB, color: Colors.black, size: 40,),
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(20),
                  primary: Colors.green, // <-- Button color
                  onPrimary: Colors.red, // <-- Splash color
                ),
                onPressed: () async {
                  final BluetoothDevice? selectedDevice =
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return SelectBondedDevicePage(checkAvailability: false);
                      },
                    ),
                  );

                  if (selectedDevice != null) {
                    print('Connect -> selected ' + selectedDevice.address);
                    _showMap(context, selectedDevice);
                  } else {
                    print('Connect -> no device selected');
                  }
                }),
            SizedBox(
              height: 65,
            ),
            Divider(color: Colors.blueGrey),
            SizedBox(
              height: 35,
            )
          ],
        ),
      ),
    );
  }

  void _showMap(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return RadarMap(server: server);
        },
      ),
    );
  }
}
