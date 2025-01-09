// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crmx_timotwo_example_app/bluetooth_models/scanner.dart';
import 'package:crmx_timotwo_example_app/models/device.dart';
import 'package:crmx_timotwo_example_app/models/mode.dart';
import 'package:crmx_timotwo_example_app/models/mode_notifier.dart';
import 'package:crmx_timotwo_example_app/resources/constants.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothRepository {
  final _deviceScanController = StreamController<List<ScanResult>>.broadcast();
  StreamSubscription<List<ScanResult>>? _subscriptionScanController;
  final connectedDeviceNameController = StreamController<String>.broadcast();
  final manufactureIDController = StreamController<String>.broadcast(); // 0
  final productTypeController = StreamController<String>.broadcast(); // 1
  final deviceNameController = StreamController<String>.broadcast(); // 2
  final dmxAddressController = StreamController<List<int>>.broadcast(); // 3
  final deviceModeController = StreamController<Mode>.broadcast(); // 4
  Device? _device;
  final _scanner = Scanner();
  List<BluetoothService>? services;
  Device? get device => _device;
  late StreamSubscription<BluetoothConnectionState> subscription;
  Mode deviceMode = Mode(label: '', byteValue: null);

  set device(Device? value) {
    _device = value;
    services?.clear();
    device?.device.discoverServices().then((value) => services = value);
  }

  final ModeNotifier modeNotifier;

  BluetoothRepository(this.modeNotifier);

  Stream<List<ScanResult>> fetchDevices() {
    _subscriptionScanController = _scanner.startScan().listen((event) {
      _deviceScanController.add(event);
    });
    _subscriptionScanController?.resume();
    return _deviceScanController.stream;
  }

  subscribeToScanControllerStream() {
    return _deviceScanController.stream;
  }

  Future stopScan() {
    _subscriptionScanController?.pause();
    return _scanner.stopScan();
  }

  Future<List<BluetoothDevice>> Function(List<Guid> withServices)
      connectedDevices() {
    return _scanner.connectedDevices();
  }

  Future<bool> disconnect() async {
    var completer = Completer<bool>();
    if (_device != null) {
      _subscriptionScanController?.pause();
      await _device?.device.disconnect();
      _device = null;
      completer.complete(true);
    } else {
      completer.complete(false);
    }
    return completer.future;
  }

  Future<List<BluetoothService>?> _fetchBLEServices() async {
    if (services == null || services?.isEmpty == true) {
      return services = await device?.device.discoverServices();
    } else {
      return services;
    }
  }

  Future<Stream<String>> fetchDeviceName() async {
    Completer<bool> completer = Completer();
    List<BluetoothService>? services = await _fetchBLEServices();
    var service = services?.firstWhere(
        (element) => element.uuid.toString() == Constants.configService);
    var characteristics = service?.characteristics;
    var characteristic = characteristics?.firstWhere(
        (element) => element.uuid.toString() == Constants.nameCharacteristic);
    await characteristic?.read().then((value) {
      String decoded = utf8.decode(value);
      decoded = decoded.replaceAll('\x00', '');
      connectedDeviceNameController.add(decoded);
      completer.complete(true);
    }, onError: (error) {
      completer.completeError('setDeviceName finished with error');
    });
    return connectedDeviceNameController.stream;
  }

  Stream<String> subscribeToNameStream() {
    return connectedDeviceNameController.stream;
  }

  getDataCommand(List<int> dataTosend, int controllerNumber) async {
    Completer<bool> completer = Completer();
    int maxTries = 20;
    int tries = 0;
    List<BluetoothService>? services = await _fetchBLEServices();
    var service = services?.firstWhere(
        (element) => element.uuid.toString() == Constants.genericRxTxService);
    var characteristics = service?.characteristics;
    var txCharacteristic = characteristics?.firstWhere(
        (element) => element.uuid.toString() == Constants.bleTxCharacteristic);
    var dataAvailableCharacteristic = characteristics?.firstWhere((element) =>
        element.uuid.toString() == Constants.bleDataAvailableCharacteristic);
    var rxCharacteristic = characteristics?.firstWhere(
        (element) => element.uuid.toString() == Constants.bleRxCharacteristic);
    try {
      await txCharacteristic?.write(dataTosend);
      var dataFromRead = await dataAvailableCharacteristic?.read();
      if (dataFromRead != null) {
        while (dataFromRead?[0] == 0) {
          await Future.delayed(const Duration(milliseconds: 100));
          tries++;
          dataFromRead = await dataAvailableCharacteristic?.read();
          if (dataFromRead?[0] != 0) {
            break;
          }
          if (tries >= maxTries) {
            break;
          }
        }
      }
      if (dataFromRead != null) {
        var data = await rxCharacteristic?.read();
        if (data != null) {
          if (controllerNumber == 0) {
            manufactureIDController.add(makeHexString(data));
          } else if (controllerNumber == 1) {
            productTypeController.add(makeHexString(data));
          } else if (controllerNumber == 2) {
            deviceNameController.add(utf8.decode(data));
          } else if (controllerNumber == 3) {
            dmxAddressController.add(data);
          } else if (controllerNumber == 4) {
            var mode = Mode.fromByteValue(data.first);
            deviceModeController.add(Mode.fromByteValue(data.first));
            if (mode.byteValue == 0) {
              deviceMode.label = 'RX';
              deviceMode.byteValue = 0;
            } else {
              deviceMode.label = 'TX';
              deviceMode.byteValue = 1;
            }
          }
        }
        completer.complete(true);
      }
    } catch (error) {
      print(error);
      completer.completeError('setDeviceName finished with error');
    }
  }

  String makeHexString(List<int> string) {
    String newValue =
        string.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return newValue;
  }

  manufactureIDControllerStream() {
    return manufactureIDController.stream;
  }

  productTypeControllerStream() {
    return productTypeController.stream;
  }

  deviceNameControllerStream() {
    return deviceNameController.stream;
  }

  dmxAddressControllerStream() {
    return dmxAddressController.stream;
  }

  deviceModeControllerStream() {
    return deviceModeController.stream;
  }

  setDataCommand(List<int> writeValue, String? stringData) async {
    Completer<bool> completer = Completer();
    int maxTries = 20;
    int tries = 0;
    await checkDeviceConnected().catchError((onError) async {
      try {
        if (device != null) {
          await autoConnectToDevice();
        }
      } catch (error) {
        print('device not connecter error: $onError');
        completer.complete(false);
        return false;
      }
      return false;
    });

    List<BluetoothService>? services = await _fetchBLEServices();
    var service = services?.firstWhere(
        (element) => element.uuid.toString() == Constants.genericRxTxService);
    var characteristics = service?.characteristics;
    var txCharacteristic = characteristics?.firstWhere(
        (element) => element.uuid.toString() == Constants.bleTxCharacteristic);
    var clearToSendCharacteristic = characteristics?.firstWhere((element) =>
        element.uuid.toString() == Constants.bleClearToSendCharacteristic);
    try {
      var dataFromRead = await clearToSendCharacteristic?.read();
      if (dataFromRead != null) {
        while (dataFromRead?[0] == 0) {
          await Future.delayed(const Duration(milliseconds: 100));
          tries++;
          print('dataFromRead: $dataFromRead' ' + ${dataFromRead?[0]}');
          dataFromRead = await clearToSendCharacteristic?.read();
          if (dataFromRead?[0] != 0) {
            print('data is not 0 anymore');
            break;
          }
          if (tries >= maxTries) {
            print('Max tries reached.');
            break;
          }
        }
      }
      if (dataFromRead != null && stringData == null) {
        await txCharacteristic?.write(writeValue); //0x00 eller 0x01
      } else {
        List<int> newData = writeValue + utf8.encode(stringData!);
        await txCharacteristic?.write(newData);
        await getDataCommand(Constants.GET_DEVICE_LABEL, 2);
        await getDataCommand(Constants.GET_DMX_ADDRESS, 3);
      }
    } on FlutterBluePlusException catch (error) {
      if (error.code == 133) {
        print('Gatterror from listen'); //here
      } else if (error.code == 6) {
        await autoConnectToDevice();
      } else {
        print(error);
        print('FlutterBluePlusException');
      }
    } catch (error) {
      print(error);
      completer.completeError(error);
    }
  }

  Future<bool> checkDeviceConnected() async {
    final stream = await device?.device.connectionState.first;
    return stream == BluetoothConnectionState.connected;
  }

  listenForDeviceState(bool shouldListen) async {
    if (device != null && shouldListen) {
      subscription = device!.device.connectionState
          .listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.disconnected) {
          if (device != null) {
            try {
              await Future.delayed(const Duration(seconds: 3));
              if (Platform.isAndroid) {
                await device!.device.requestMtu(512);
              }
              await device!.device.connect(
                  timeout: const Duration(seconds: 1), autoConnect: true);
            } on FlutterBluePlusException catch (error) {
              if (error.code == 133) {
                print('Gatterror from listen');
              } else if (error.code == 6) {
                await autoConnectToDevice(); //here 2
              } else {
                print(error);
                print('FlutterBluePlusException');
              }
            } catch (error) {
              print(error);
            }
          }
        }
      });
    } else {
      subscription.cancel();
    }
  }

  reconnectToDevice() async {
    if (device != null) {
      try {
        await Future.delayed(const Duration(seconds: 3));
        if (Platform.isAndroid) {
          await device!.device.requestMtu(512);
        }
        await device!.device
            .connect(timeout: const Duration(seconds: 1), autoConnect: true);
      } on FlutterBluePlusException catch (error) {
        if (error.code == 133) {
          print('Gatterror from listen');
        } else {
          print(error);
          print('FlutterBluePlusException');
        }
      } catch (error) {
        print(error);
      }
    }
  }

  Future<void> autoConnectToDevice() async {
    try {
      await device!.device.connect(timeout: const Duration(seconds: 10));
      services!.clear();
      await device!.device.discoverServices().then((value) => services = value);
      await getDataCommand(Constants.GET_MODE, 4);
      return Future.value();
    } catch (error) {
      return;
    }
  }
}
