#!/usr/bin/env python

import argparse
import atexit
import time
import uuid
from enum import Enum

import Adafruit_BluefruitLE

GENERIC_RXTX_DATA_SERVICE = uuid.UUID("95221000-c733-6ac3-5256-467c1e68623f")
GENERIC_RX_DATA_CHAR = uuid.UUID("95221001-c733-6ac3-5256-467c1e68623f")
GENERIC_TX_DATA_CHAR = uuid.UUID("95221002-c733-6ac3-5256-467c1e68623f")
DATA_AVAILABLE_CHAR = uuid.UUID("95221003-c733-6ac3-5256-467c1e68623f")
CLEAR_TO_SEND_CHAR = uuid.UUID("95221004-c733-6ac3-5256-467c1e68623f")


class SpiCommand(Enum):
    GET_MANUFACTURER_ID = 0x00
    # Reserved
    GET_PRODUCT_TYPE = 0x02
    # Reserved
    GET_DEVICE_LABEL = 0x04
    SET_DEVICE_LABEL = 0x05
    GET_MODE = 0x06
    SET_MODE = 0x07
    GET_DMX_ADDRESS = 0x08
    SET_DMX_ADDRESS = 0x09


class TransactionManager:
    def __init__(
        self,
        rx_data_char,
        tx_data_char,
        data_available_char,
        clear_to_send_char,
    ):
        self.rx_data_char = rx_data_char
        self.tx_data_char = tx_data_char
        self.data_available_char = data_available_char
        self.clear_to_send_char = clear_to_send_char

    def do_get_command(
        self,
        command: SpiCommand,
    ) -> bytes:
        while not self.clear_to_send_char.read_value():
            time.sleep(0.1)

        payload = int.to_bytes(command.value, 1, "big")
        self.tx_data_char.write_value(payload)

        while not self.data_available_char.read_value():
            time.sleep(0.1)

        response = self.rx_data_char.read_value()

        self.data_available_char.write_value(int.to_bytes(0, 1, "big"))

        return response

    def do_set_command(
        self,
        command: SpiCommand,
        payload: bytes,
    ):
        while not self.clear_to_send_char.read_value():
            time.sleep(0.1)

        payload = int.to_bytes(command.value, 1, "big") + payload
        self.tx_data_char.write_value(payload)

        time.sleep(0.1)


def parse_manufacturer_id(data: bytes) -> str:
    return hex(int.from_bytes(data, "big"))


def parse_product_type(data: bytes) -> str:
    return hex(int.from_bytes(data, "big"))


def parse_device_label(data: bytes) -> str:
    return data.decode("utf-8")


def parse_dmx_address(data: bytes) -> int:
    return int.from_bytes(data, "big")


def parse_mode(data: bytes) -> str:
    return "TX" if bool.from_bytes(data, "big") else "RX"


def find_device(ble, id, timeout=20):
    devices = set([])
    for _ in range(0, int(timeout)):
        new_devices = set(ble.list_devices()) - devices
        for device in new_devices:
            print("'{}': '{}'".format(device.id, device.name))
            if device.id == uuid.UUID(id):
                return device
        devices |= new_devices
        time.sleep(1)
    return None


arg_parser = argparse.ArgumentParser()
arg_parser.add_argument("device_id", help="UUID of the target device")
arg_parser.add_argument("--device-label", type=str, help="Set device label")
arg_parser.add_argument("--mode", choices=["RX", "TX"], help="Set mode")
arg_parser.add_argument("--dmx-address", type=int, help="Set dmx address")
args = arg_parser.parse_args()

ble = Adafruit_BluefruitLE.get_provider()


def pretty_print(left, right, align_right=True):
    printout = ""
    printout += (
        f"{left}: ".rjust(20, " ") if align_right else f"{left}: ".ljust(20, " ")
    )
    printout += f"{right}"

    print(printout)


def main():
    ble.clear_cached_data()

    adapter = ble.get_default_adapter()
    adapter.power_on()
    print("Using adapter: {0}".format(adapter.name))

    print("Searching for devices...")
    device = None
    try:
        adapter.start_scan()
        atexit.register(adapter.stop_scan)

        device = find_device(ble, args.device_id)

    finally:
        adapter.stop_scan()

    print("Connecting to {}, {}".format(device.id, device.name))
    device.connect()  # Will time out after 60 seconds, specify timeout_sec parameter
    # to change the timeout.

    try:
        time.sleep(2)
        print("Discovering services...")
        device.discover([], [])

        print("Listing services...")
        for service in device.list_services():
            print("{}".format(service.uuid))

        print("Finding the TXRX service...")
        generic_rxtx_service = device.find_service(GENERIC_RXTX_DATA_SERVICE)

        print("Listing characteristics...")
        for characteristic in generic_rxtx_service.list_characteristics():
            print("{}".format(characteristic.uuid))
        print("Finding the RX characteristics...")
        rx_data_char = generic_rxtx_service.find_characteristic(GENERIC_RX_DATA_CHAR)
        tx_data_char = generic_rxtx_service.find_characteristic(GENERIC_TX_DATA_CHAR)
        data_avail_char = generic_rxtx_service.find_characteristic(DATA_AVAILABLE_CHAR)
        clear_to_w_char = generic_rxtx_service.find_characteristic(CLEAR_TO_SEND_CHAR)

        transaction_manager = TransactionManager(
            rx_data_char,
            tx_data_char,
            data_avail_char,
            clear_to_w_char,
        )

        print()
        response = transaction_manager.do_get_command(SpiCommand.GET_MANUFACTURER_ID)
        pretty_print("Manufacturer ID", parse_manufacturer_id(response))

        response = transaction_manager.do_get_command(SpiCommand.GET_PRODUCT_TYPE)
        pretty_print("Product ID", parse_product_type(response))

        response = transaction_manager.do_get_command(SpiCommand.GET_DEVICE_LABEL)
        pretty_print("Device Label", parse_device_label(response))

        response = transaction_manager.do_get_command(SpiCommand.GET_DMX_ADDRESS)
        pretty_print("DMX Address", parse_dmx_address(response))

        response = transaction_manager.do_get_command(SpiCommand.GET_MODE)
        pretty_print("Mode", parse_mode(response))

        print()
        if args.device_label:
            pretty_print("Writing label", args.device_label, align_right=False)
            transaction_manager.do_set_command(
                command=SpiCommand.SET_DEVICE_LABEL,
                payload=args.device_label.encode(),
            )

        if args.dmx_address:
            pretty_print("Writing address", args.dmx_address, align_right=False)
            transaction_manager.do_set_command(
                command=SpiCommand.SET_DMX_ADDRESS,
                payload=args.dmx_address.to_bytes(2, "big"),
            )

        if args.mode:
            pretty_print("Writing mode", args.mode, align_right=False)
            new_mode = 0 if args.mode == "RX" else 1
            transaction_manager.do_set_command(
                command=SpiCommand.SET_MODE,
                payload=new_mode.to_bytes(1, "big"),
            )

        print("Done!")

    finally:
        try:
            device.disconnect()
        except:
            pass  # Workaround. Passing to avoid having a disconnect exception obfuscating the real expections.


ble.initialize()
ble.run_mainloop_with(main)
