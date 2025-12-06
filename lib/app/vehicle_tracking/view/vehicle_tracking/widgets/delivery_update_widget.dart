import 'package:flutter/material.dart';

class DriverSectionWidget extends StatelessWidget {
  final String driverName;
  final String phone;
  final String vehicleNumber;
  final String driverImage;

  const DriverSectionWidget({
    super.key,
    required this.driverName,
    required this.phone,
    required this.vehicleNumber,
    required this.driverImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(driverImage),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driverName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                Text(phone, style: const TextStyle(color: Colors.black54)),
                Text("Vehicle No: $vehicleNumber",
                    style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
