import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_trolley/map/radar_map.dart';

class RadarMap extends StatefulWidget {
  final BluetoothDevice server;

  const RadarMap({required this.server});

  @override
  _RadarMapState createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap> {
  bool danger = false;
  bool useSides = false;
  String transmission = '';
  int distance = 0;
  int directionIndex = 0;
  static List<int> ticks = [20, 40, 60, 80, 100, 120, 140];
  static List<String> features = [
    "Ahead",
    "",
    "Right",
    "",
    "Behind",
    "",
    "Left",
    ""
  ];
  List<List<int>> mapData = [
    [0, 0, 0, 0, 0, 0, 0, 0]
  ];
  int mapDataIndex = 0;
  BluetoothConnection? connection;
  bool isConnecting = true;

  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;

  Color axisGreen = Color(0xFF50F090);
  Color chartGreen = Color(0x8850F090);

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occurred');
      print(error);
    });
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: danger ? Color(0xFF903030) : Colors.green,
        centerTitle: true,
        title: Text(
          'Smart Trolley',
          style: GoogleFonts.abrilFatface(
              color: Colors.black, fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: danger
            ? BoxDecoration(
                gradient: RadialGradient(colors: [
                Color(0xDD505050),
                Color(0xFF200000),
              ], radius: 1))
            : BoxDecoration(
                gradient: RadialGradient(colors: [
                Color(0xDD505050),
                Color(0xFF001000),
              ], radius: 1)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 10,
            ),
            ListTile(
                title: Text(
              'Radar Map',
              style: GoogleFonts.openSans(fontSize: 20, color: Colors.white),
            )),
            Divider(color: Colors.blueGrey),
            SizedBox(
              height: 10,
            ),
            Expanded(
                child: RadarChart.dark(
              ticks: ticks,
              features: features,
              data: mapData,
              reverseAxis: false,
              useSides: useSides,
              axisColor: danger ? Colors.pinkAccent : axisGreen,
              outlineColor: danger ? Colors.red : Colors.lightGreenAccent,
              graphColors: danger ? [Colors.redAccent] : [Colors.lightGreen],
            )),
          ],
        ),
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    String dataString = String.fromCharCodes(data);
    if (data.contains(13)) {
      if (data.length > 2) {
        transmission =
            transmission + dataString.substring(0, dataString.length - 2);
      }
      print('transmission: $transmission');
      if (transmission == '-1') {
        mapDataIndex = 0;
        print(mapData[0].reduce(min));
        if (mapData[0].reduce(min) > 10)
          setState(() {
            danger = false;
          });
      } else {
        setState(() {
          distance = min(int.parse(transmission), 150);
          mapData[0][mapDataIndex] = distance;
          mapDataIndex = (mapDataIndex + 1) % mapData[0].length;
          if (distance <= 10) {
            HapticFeedback.vibrate();
            danger = true;
          }
        });
      }
      transmission = '';
    } else {
      transmission = transmission + dataString;
    }
    print(mapData);
  }
}
