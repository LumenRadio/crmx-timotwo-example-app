import 'package:crmx_timotwo_example_app/models/device.dart';
import 'package:crmx_timotwo_example_app/repository/bluetooth_repository.singleton.dart';
import 'package:crmx_timotwo_example_app/screens/device_screen.dart';
import 'package:crmx_timotwo_example_app/ui/DeviceListItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreen createState() => _MainScreen();
}

Device? _device;

class _MainScreen extends State<MainScreen> {
  final List<String> bleDeviceList =
      List<String>.generate(3, (index) => 'Item ${index + 1}');

  final List<BluetoothDevice> scannedDevices = [];
  bool isScanning = false;
  static const connectDeviceDialog = ['Connect'];
  late List<ScanResult> devices;

  final RepositoryBluetoothSingleton _repositorySingleton =
      RepositoryBluetoothSingleton();

  @override
  void initState() {
    startScanning();
    super.initState();
    _repositorySingleton.getBluetoothRepository.fetchDevices();
  }

  @override
  Widget build(BuildContext context) {
    Set<ScanResult> sortedSet = {};
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: const Text('Example app'),
      ),
      //body: Flexible(
      body: SingleChildScrollView(
        child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                StreamBuilder<List<ScanResult>>(
                    stream: _repositorySingleton.getBluetoothRepository
                        .subscribeToScanControllerStream(),
                    builder: (context, dataSnapshot) {
                      if (dataSnapshot.hasData) {
                        devices = dataSnapshot.data!;
                        var sortedList = devices.toList();
                        sortedList.sort((b, a) => a.rssi.compareTo(b.rssi));
                        sortedSet = sortedList.toSet();
                        return ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount: sortedList.length,
                            itemBuilder: (context, index) {
                              try {
                                devices[index] =
                                    sortedSet.toList()[index]; //remove
                              } catch (e) {
                                print('error from setting list');
                              }
                              return DeviceListItem(
                                  onPressed: () async {
                                    BluetoothDevice? chosenDevice =
                                        devices[index].device;
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(devices[index]
                                                .device
                                                .platformName),
                                            content: SizedBox(
                                                width: double.maxFinite,
                                                child: ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount:
                                                        connectDeviceDialog
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) =>
                                                            ListTile(
                                                              title: Text(
                                                                  connectDeviceDialog[
                                                                      index]),
                                                              onTap: () async {
                                                                switch (index) {
                                                                  case 0:
                                                                    Navigator.pop(
                                                                        context);
                                                                    await showProgressDialog(
                                                                        context);
                                                                    await _connectToDevice(
                                                                        chosenDevice,
                                                                        _device);
                                                                }
                                                              },
                                                            ))),
                                          );
                                        });
                                  },
                                  title: devices[index].device.platformName,
                                  rssi: devices[index].rssi);
                            });
                      } else if (!dataSnapshot.hasData ||
                          dataSnapshot.data!.isEmpty) {
                        return const Center(child: Text('No devices found.'));
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    }),
                TextButton(
                    onPressed: () async {
                      await _repositorySingleton.getBluetoothRepository
                          .stopScan();
                      setState(() {
                        devices.clear();
                      });
                      await _repositorySingleton.getBluetoothRepository
                          .fetchDevices();
                    },
                    child: const Text('Refresh list')),
              ],
            )),
      ),
    );
  }

  void startScanning() {
    setState(() {
      isScanning = true;
      scannedDevices.clear();
    });
  }

  Future<void> _connectToDevice(
      BluetoothDevice bleDevice, Device? device) async {
    try {
      await bleDevice.connect();
      Device newDevice = Device.name(bleDevice.remoteId, bleDevice,
          bleDevice.servicesList, bleDevice.platformName);
      _repositorySingleton.getBluetoothRepository.device = newDevice;
      _repositorySingleton.getBluetoothRepository.listenForDeviceState(true);
      _navigateToDeviceScreen();
    } catch (error) {
      print(error);
    }
  }

  showProgressDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          Container(
              margin: const EdgeInsets.only(left: 7),
              child: const Text("Connecting...")),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void _navigateToDeviceScreen() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DeviceScreen()));
  }
}
