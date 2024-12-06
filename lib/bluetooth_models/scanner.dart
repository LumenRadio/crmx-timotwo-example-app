import 'dart:async';

import 'package:crmx_timotwo_example_app/resources/constants.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Scanner {
  Stream<List<ScanResult>> startScan() {
    FlutterBluePlus.startScan(
        withServices: [Guid(Constants.dmxServiceUuid)],
        timeout: const Duration(seconds: 10));
    return FlutterBluePlus.scanResults;
  }

  Future stopScan() {
    return FlutterBluePlus.stopScan();
  }

  Future<List<BluetoothDevice>> Function(List<Guid> withServices)
      connectedDevices() {
    return FlutterBluePlus.systemDevices;
  }
}
