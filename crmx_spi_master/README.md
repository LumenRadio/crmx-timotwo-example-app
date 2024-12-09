# Arduino SPI Master for CRMX TimoTwo

Arduino example on how to implement SPI master for CRMX TimoTwo and controlling the Arduino Due via BLE interface of the TimoTwo.

## Getting Started

Follow the [Arduino CLI - Installation](https://arduino.github.io/arduino-cli/1.1/installation/) guide for installing `arduino-cli` utility.

Install Arduino Due Board Manager by running:

```sh
arduino-cli core install arduino:sam
```

## How to use

Connect your arduino to the TimoTwo's SPI interface (all five signals).

Compile and upload the sketch to Arduino Due by running:

```sh
make PORT=/dev/<serial-port>
```

Monitor the communication on serial port by running:

```sh
arduino-cli monitor --port /dev/<serial-port> --config 250000

```

## BLE and SPI Interface

Arduino may be accessed via TimoTwo's BLE interface on `Generic RXTX Service`. For more information, navigate to LumenRadio's official documentation [BLE interface - Generix RXTX data service](https://docs.lumenrad.io/timotwo/ble-interface/#generic-rxtx-data-service).

### SPI Commands

Arduino implements handlers for following commands:

| Name                | Value |
| ------------------- | ----- |
| GET_MANUFACTURER_ID | 0x00  |
| RESERVED            | 0x01  |
| GET_PRODUCT_TYPE    | 0x02  |
| RESERVED            | 0x03  |
| GET_DEVICE_LABEL    | 0x04  |
| SET_DEVICE_LABEL    | 0x05  |
| GET_MODE            | 0x06  |
| SET_MODE            | 0x07  |
| GET_DMX_ADDRESS     | 0x08  |
| SET_DMX_ADDRESS     | 0x09  |

### Default values

Arduino will respond following values by default.

| Name            | Size     | Default value | Access     |
| --------------- | -------- | ------------- | ---------- |
| manufacturer_id | 2 bytes  | 0x4c55        | Read-only  |
| product_type    | 2 bytes  | 0x7101        | Read-only  |
| device_name     | 32 bytes | Test          | Read/Write |
| mode            | 1 byte   | 0 (RX)        | Read/Write |
| dmx_address     | 2 bytes  | 123           | Read/Write |
