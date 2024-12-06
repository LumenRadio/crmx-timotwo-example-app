import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Device {
  DeviceIdentifier _id;
  BluetoothDevice _device;
  List _services;
  String _name;

  Device.name(
    this._id,
    this._device,
    this._services,
    this._name,
  );

  BluetoothDevice get device => _device;

  List get services => _services;

  String get name => _name;

  DeviceIdentifier get id => _id;

  set id(DeviceIdentifier value) {
    _id = value;
  }
}

class ManufacturerData {
  AdvertisementData _advertisementData;

  final int _developmentManufacturerKey = 0xFFFF;
  final int _lumenRadioManufacturerKey = 0x09E9;

  ManufacturerData(AdvertisementData advertisementData)
      : _advertisementData = advertisementData;

  List<int>? get manufacturerData {
    if (_advertisementData.manufacturerData
        .containsKey(_lumenRadioManufacturerKey)) {
      return _advertisementData.manufacturerData[_lumenRadioManufacturerKey];
    } else if (_advertisementData.manufacturerData
        .containsKey(_developmentManufacturerKey)) {
      return _advertisementData.manufacturerData[_developmentManufacturerKey];
    }

    return null;
  }

  String? get hardwareId {
    var rawId = manufacturerData?.sublist(1, 5);
    if (rawId == null) {
      return null;
    }
    return rawId[0].toRadixString(16).padLeft(2, '0').toUpperCase() +
        rawId[1].toRadixString(16).padLeft(2, '0').toUpperCase() +
        rawId[2].toRadixString(16).padLeft(2, '0').toUpperCase() +
        rawId[3].toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  String? get manufacturerId {
    var rawId = manufacturerData?.sublist(5, 7);
    if (rawId == null) {
      return null;
    }
    return rawId[0].toRadixString(16).padLeft(2, '0').toUpperCase() +
        rawId[1].toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  String? get modelId {
    var rawId = manufacturerData?.sublist(7, 9);
    if (rawId == null) {
      return null;
    }
    return rawId[0].toRadixString(16).padLeft(2, '0').toUpperCase() +
        rawId[1].toRadixString(16).padLeft(2, '0').toUpperCase();
  }
}
