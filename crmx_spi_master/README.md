# Arduino SPI Master for CRMX TimoTwo

Arduino example on how to implement SPI master for CRMX TimoTwo and controlling the Arduino via BLE interface of the TimoTwo.

## How to use

Connect your arduino to the TimoTwo's SPI interface (all five signals).

## SPI Interface

This document explains roughly how to reach the arduino via TimoTwo's BLE interface.

## Generic RXTX Service

Arduino may be accessed via TimoTwo's BLE interface on `Generic RXTX Service`.

The `Generic RXTX Service` is documented [here](https://docs.lumenrad.io/timotwo/ble-interface/#generic-rxtx-data-service).

## SPI Commands

Arduino implements following commands handlers:

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

## Default values

Arduino will respond following values by default.

| Name            | Size     | Default value | Access     |
| --------------- | -------- | ------------- | ---------- |
| manufacturer_id | 2 bytes  | 0x4c55        | Read-only  |
| product_type    | 2 bytes  | 0x7101        | Read-only  |
| device_name     | 32 bytes | Test          | Read/Write |
| mode            | 1 byte   | 0 (RX)        | Read/Write |
| dmx_address     | 2 bytes  | 123           | Read/Write |
