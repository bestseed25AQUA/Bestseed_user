import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:google_fonts/google_fonts.dart';

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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Details',
              style:  TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10,),
            Row(
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/user.png',
                      height: 25,
                      width: 25,
                    ),
                    SizedBox(width: 5),
                    Text(
                      driverName,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 7),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/call.png',
                      height: 30,
                      width: 30,
                    ),
                    SizedBox(width: 10),
                    Text(
                      phone,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 7),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/truck_icon.png',
                      height: 30,
                      width: 30,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 5),
                    Text(
                      vehicleNumber,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                // CircleAvatar(
                //   radius: 28,
                //   backgroundImage: NetworkImage(driverImage),
                // ),
                // const SizedBox(width: 16),
                // Expanded(
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Text(driverName,
                //           style: const TextStyle(
                //               fontSize: 16, fontWeight: FontWeight.w600)),
                //       Text(phone, style: const TextStyle(color: Colors.black54)),
                //       Text("Vehicle No: $vehicleNumber",
                //           style: const TextStyle(color: Colors.black87)),
                //     ],
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
