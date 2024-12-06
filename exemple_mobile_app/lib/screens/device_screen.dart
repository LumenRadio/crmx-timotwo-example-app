// ignore_for_file: prefer_const_constructors, avoid_print

import 'package:crmx_timotwo_example_app/models/device.dart';
import 'package:crmx_timotwo_example_app/models/mode.dart';
import 'package:crmx_timotwo_example_app/models/mode_notifier.dart';
import 'package:crmx_timotwo_example_app/repository/bluetooth_repository.dart';
import 'package:crmx_timotwo_example_app/repository/bluetooth_repository.singleton.dart';
import 'package:crmx_timotwo_example_app/resources/constants.dart';
import 'package:crmx_timotwo_example_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeviceScreen extends StatefulWidget {
  //final Device device;

  const DeviceScreen({super.key});

  @override
  _DeviceScreen createState() => _DeviceScreen();
}

class _DeviceScreen extends State<DeviceScreen> {
  Device? get device =>
      RepositoryBluetoothSingleton().getBluetoothRepository.device;
  String? appBarDeviceName;
  final deviceNameController = TextEditingController();
  final dmxAddressController = TextEditingController();
  bool loadingData = true;
  List<int> modes = [0, 1];
  String currentMode = '';
  //Mode mode = Mode();
  final Mode _deviceMode =
      RepositoryBluetoothSingleton().getBluetoothRepository.deviceMode;

  //State<DeviceScreen>
  @override
  void initState() {
    fetchDeviceData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final modeNotifier = Provider.of<ModeNotifier>(context);
    final repository = BluetoothRepository(modeNotifier);
    return Scaffold(
        //resizeToAvoidBottomInset: false,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(''),
        ),
        body: Column(
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: loadingData
                              ? const Row(children: [
                                  Text('Fetching data...'),
                                  SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator())
                                ])
                              : const Text(''),
                        ),
                      ],
                    ),
                    Align(
                      child: StreamBuilder<String>(
                          stream: RepositoryBluetoothSingleton()
                              .getBluetoothRepository
                              .subscribeToNameStream(),
                          builder: (context, dataSnapshot) {
                            if (dataSnapshot.hasData &&
                                dataSnapshot.data != null) {
                              appBarDeviceName = dataSnapshot.data;
                              return Text(dataSnapshot.data!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "Sofia",
                                  ));
                            } else {
                              return Container();
                            }
                          }),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      const Text(
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          'ManufacturerID: '),
                      StreamBuilder<String>(
                          stream: RepositoryBluetoothSingleton()
                              .getBluetoothRepository
                              .manufactureIDControllerStream(),
                          builder: (context, dataSnapshot) {
                            if (dataSnapshot.hasData &&
                                dataSnapshot.data != null) {
                              return Text('0x${dataSnapshot.data!}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "Sofia",
                                  ));
                            } else {
                              return Container();
                            }
                          }),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      const Text(
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                          'Product type: '),
                      // Streambuilder
                      StreamBuilder<String>(
                          stream: RepositoryBluetoothSingleton()
                              .getBluetoothRepository
                              .productTypeControllerStream(),
                          builder: (context, dataSnapshot) {
                            if (dataSnapshot.hasData &&
                                dataSnapshot.data != null) {
                              return Text('0x${dataSnapshot.data!.toString()}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "Sofia",
                                  ));
                            } else {
                              return Container();
                            }
                          }),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      const Text(
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                          'Device Name: '),
                      StreamBuilder<String>(
                          stream: RepositoryBluetoothSingleton()
                              .getBluetoothRepository
                              .deviceNameControllerStream(),
                          builder: (context, dataSnapshot) {
                            if (dataSnapshot.hasData &&
                                dataSnapshot.data != null) {
                              return Expanded(
                                  child: Text(dataSnapshot.data!.toString(),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: "Sofia",
                                      )));
                            } else {
                              return Container();
                            }
                          }),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      const Text(
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                          'DMX address: '),
                      Expanded(
                        child: StreamBuilder<List<int>>(
                            stream: RepositoryBluetoothSingleton()
                                .getBluetoothRepository
                                .dmxAddressControllerStream(),
                            builder: (context, dataSnapshot) {
                              if (dataSnapshot.hasData &&
                                  dataSnapshot.data != null) {
                                return Text(dataSnapshot.data![1].toString(),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: "Sofia",
                                    ));
                              } else {
                                return Container();
                              }
                            }),
                      ),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      const Text(
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                          'Mode: '),
                      StreamBuilder<Mode>(
                          stream: RepositoryBluetoothSingleton()
                              .getBluetoothRepository
                              .deviceModeControllerStream(),
                          builder: (context, dataSnapshot) {
                            if (dataSnapshot.hasData &&
                                dataSnapshot.data != null) {
                              print(
                                  '!!! bytesvalue: ${dataSnapshot.data!.byteValue}');
                              //Mode currentMode = Mode.fromByteValue(
                              //    dataSnapshot.data.byteValue);
                              //currentMode = dataSnapshot.data!.label.toString();

                              return Text(dataSnapshot.data!.label.toString(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "Sofia",
                                  ));
                            } else {
                              return Container();
                            }
                          }),
                    ]),
                    TextButton(
                        onPressed: () async {
                          List<int> dataToSend = [];
                          if (_deviceMode.byteValue == 0) {
                            dataToSend = Constants.SET_MODE + [0x01];
                          } else {
                            dataToSend = Constants.SET_MODE + [0x00];
                          }
                          try {
                            await RepositoryBluetoothSingleton()
                                .getBluetoothRepository
                                .setDataCommand(dataToSend, null);
                          } catch (error) {
                            print('error changing mode $error');
                          }
                        },
                        child: const Text('Switch mode'))
                  ],
                ),
              ),
            ),
            Form(
              child: Padding(
                padding: const EdgeInsets.only(right: 30, left: 30),
                child: TextFormField(
                  controller: deviceNameController,
                  style: const TextStyle(color: Colors.black),
                  textAlign: TextAlign.start,
                  keyboardType: TextInputType.name,
                  autocorrect: false,
                  autofocus: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a name';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Device name',
                  ),
                ),
              ),
            ),
            TextButton(
                onPressed: () async {
                  await RepositoryBluetoothSingleton()
                      .getBluetoothRepository
                      .setDataCommand(Constants.SET_DEVICE_LABEL,
                          deviceNameController.text);
                },
                child: const Text(
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    'Set device name')),
            Form(
              child: Padding(
                padding: const EdgeInsets.only(right: 30, left: 30),
                child: TextFormField(
                  controller: dmxAddressController,
                  style: const TextStyle(color: Colors.black),
                  textAlign: TextAlign.start,
                  keyboardType: TextInputType.name,
                  autocorrect: false,
                  autofocus: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a name';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'DMX address',
                  ),
                ),
              ),
            ),
            TextButton(
                onPressed: () async {
                  await RepositoryBluetoothSingleton()
                      .getBluetoothRepository
                      .setDataCommand(
                          Constants.SET_DMX_ADDRESS, dmxAddressController.text);
                },
                child: const Text(
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    'Set DMX address')),
            const SizedBox(height: 30),
            const SizedBox(height: 30),
            TextButton(
                onPressed: () async {
                  showProgressDialog(context);
                  RepositoryBluetoothSingleton()
                      .getBluetoothRepository
                      .listenForDeviceState(false);
                  await RepositoryBluetoothSingleton()
                      .getBluetoothRepository
                      .disconnect();
                  _navigateToMainScreen();
                },
                child: const Text(
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    'Disconnect')),
          ],
        ));
  }

  showProgressDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          Container(
              margin: const EdgeInsets.only(left: 7),
              child: const Text("Disconnecting")),
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

  fetchDeviceData() async {
    await RepositoryBluetoothSingleton()
        .getBluetoothRepository
        .fetchDeviceName();
    await RepositoryBluetoothSingleton()
        .getBluetoothRepository
        .getDataCommand(Constants.GET_MANUFACTURER_ID, 0);
    await RepositoryBluetoothSingleton()
        .getBluetoothRepository
        .getDataCommand(Constants.GET_PRODUCT_TYPE, 1);
    await RepositoryBluetoothSingleton()
        .getBluetoothRepository
        .getDataCommand(Constants.GET_DEVICE_LABEL, 2);
    await RepositoryBluetoothSingleton()
        .getBluetoothRepository
        .getDataCommand(Constants.GET_DMX_ADDRESS, 3);
    await RepositoryBluetoothSingleton()
        .getBluetoothRepository
        .getDataCommand(Constants.GET_MODE, 4);
    setState(() {
      loadingData = false;
    });
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()));
  }
}
