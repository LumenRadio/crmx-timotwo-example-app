import 'package:crmx_timotwo_example_app/models/device.dart';
import 'package:crmx_timotwo_example_app/resources/constants.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DeviceBrand { crmx, wdmx, unknown }

class DeviceScanFilter {
  List<int> manufacturerId = [];
  List<int> deviceModelId = [];
  static const String lumenRadioEstaManufacturerId = "4C55";
  static const String wirelessSolutionEstaManufacturerId = "5753";
  static const String timoTwoDeviceModelId = "F140";

  Device? filterCRMDevice(ScanResult result) {
    if (!result.advertisementData.serviceUuids
        .map((e) => e.toString().toLowerCase())
        .contains(Constants.dmxServiceUuid)) {
      return null;
    }

    var manufacturerData = ManufacturerData(result.advertisementData);
    DeviceBrand brand = deviceBrand(manufacturerData);
    if (brand == DeviceBrand.unknown) {
      return null;
    }

    return Device.name(
      //result.device.remoteId.toString(),
      //result.device.advName.toString(),
      result.device.remoteId,
      result.device,
      //result.advertisementData,
      //false,
      [],
      result.device.platformName,
      //result.rssi,
      //manufacturerData.hardwareId!
    );
  }

  static DeviceBrand deviceBrand(ManufacturerData manufacturerData) {
    if (manufacturerData.manufacturerId == lumenRadioEstaManufacturerId) {
      return DeviceBrand.crmx;
    }
    if (manufacturerData.modelId == timoTwoDeviceModelId) {
      return DeviceBrand.crmx;
    }
    if (manufacturerData.manufacturerId == wirelessSolutionEstaManufacturerId) {
      return DeviceBrand.wdmx;
    }

    return DeviceBrand.unknown;
  }
}
