// ignore_for_file: constant_identifier_names

class Constants {
  static const String dmxServiceUuid = '33b5376d-0942-1f91-379b-ac5af36b9efa';
  static const String configService = '33b5376d-0942-1f91-379b-ac5af36b9efa';
  static const String uuidTimotwo = 'd739421f-9bfe-bbe4-7787-ee3412c26d6a';

  static const String nameCharacteristic =
      '33b5376e-0942-1f91-379b-ac5af36b9efa';

  // Arduino
  static const String genericRxTxService =
      '95221000-c733-6ac3-5256-467c1e68623f';
  static const String bleRxCharacteristic =
      '95221001-c733-6ac3-5256-467c1e68623f';
  static const String bleTxCharacteristic =
      '95221002-c733-6ac3-5256-467c1e68623f';
  static const String bleDataAvailableCharacteristic =
      '95221003-c733-6ac3-5256-467c1e68623f';
  static const String bleClearToSendCharacteristic =
      '95221004-c733-6ac3-5256-467c1e68623f';

  static const List<int> GET_MANUFACTURER_ID = [0x00];
  static const List<int> GET_PRODUCT_TYPE = [0x02];
  static const List<int> GET_DEVICE_LABEL = [0x04];
  static const List<int> SET_DEVICE_LABEL = [0x05];
  static const List<int> GET_MODE = [0x06];
  static const List<int> SET_MODE = [0x07];
  static const List<int> GET_DMX_ADDRESS = [0x08];
  static const List<int> SET_DMX_ADDRESS = [0x09];
}
