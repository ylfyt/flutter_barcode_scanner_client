import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _scanBarcode = 'Unknown';

  Socket? _socket;
  String _serverResponse = "";

  @override
  void initState() {
    super.initState();

    print("Start to connect");
    Socket.connect('127.0.0.1', 8080).then((socket) {
      print("COnnected");
      socket.encoding = utf8; // <== force the encoding
      _socket = socket;
      socket.listen((List<int> data) {
        String result = utf8.decode(data);
        print("Server: $result");
        setState(() {
          _serverResponse = "Server: $result";
        });
      });
    }).catchError(print);
  }

  Future<void> startBarcodeScanStream() async {
    FlutterBarcodeScanner.getBarcodeStreamReceiver(
            '#ff6666', 'Cancel', true, ScanMode.BARCODE)!
        .listen((barcode) => print(barcode));
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    print(1);

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    print(2);

    setState(() {
      print(_socket);
      _scanBarcode = barcodeScanRes;
      _socket?.write(barcodeScanRes);
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(title: const Text('Barcode scan client')),
            body: Builder(builder: (BuildContext context) {
              return Container(
                  alignment: Alignment.center,
                  child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ElevatedButton(
                            onPressed: () => scanBarcodeNormal(),
                            child: Text('Start barcode scan')),
                        Text(
                          'Scan result : $_scanBarcode\n',
                          style: TextStyle(fontSize: 20),
                        ),
                        TextField(
                          decoration: InputDecoration(hintText: 'Scan barcode'),
                          onChanged: (val) {
                            setState(() {
                              _scanBarcode = val;
                            });
                          },
                        ),
                        ElevatedButton(
                            onPressed: () {
                              _socket?.write(_scanBarcode);
                            },
                            child: Text('Send to server')),
                        Text(_serverResponse, style: TextStyle(fontSize: 20)),
                      ]));
            })));
  }
}
