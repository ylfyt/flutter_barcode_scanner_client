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

  RawDatagramSocket? _socket;
  String _serverResponse = "";

  @override
  void initState() {
    super.initState();

    RawDatagramSocket.bind(InternetAddress.anyIPv4, 1054)
        .then((RawDatagramSocket socket) {
      print('Datagram socket ready to receive');
      print('${socket.address.address}:${socket.port}');

      socket.send('Datagram socket ready to receive'.codeUnits,
          InternetAddress("127.0.0.1"), 1053);
      _socket = socket;
      socket.listen((RawSocketEvent e) {
        Datagram? d = socket.receive();
        if (d == null) return;

        String message = String.fromCharCodes(d.data).trim();
        print('Datagram from $d.address.address:${d.port}: $message');
      });
    });
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
      _socket?.send(
          barcodeScanRes.codeUnits, InternetAddress("127.0.0.1"), 1053);
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
                              _socket?.send(_scanBarcode.codeUnits,
                                  InternetAddress("127.0.0.1"), 1053);
                            },
                            child: Text('Send to server')),
                        Text(_serverResponse, style: TextStyle(fontSize: 20)),
                      ]));
            })));
  }
}
