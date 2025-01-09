import 'package:crmx_timotwo_example_app/models/device.dart';
import 'package:flutter/material.dart';

class DeviceListItem extends StatelessWidget {
  final String title;
  final GestureTapCallback? onPressed;
  final int rssi;
  final Device? device;

  DeviceListItem(
      {required this.title,
      this.onPressed,
      required this.rssi,
      this.device}); //was required

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(15.0),
          decoration: const BoxDecoration(
            color: Colors.grey,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //Image? other data?
              Text(
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  title),
              //Add signal icon
            ],
          ),
        ),
      ),
    );
  }
}
