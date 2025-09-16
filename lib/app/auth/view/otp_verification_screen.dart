import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/dashboard/dashboard.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String otpCode = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0076BE), // Primary Blue
        elevation: 0,
        title: Text(
          "OTP Verification",
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              "We have sent the verification code to your",
              style: GoogleFonts.roboto(fontSize: 15, color: Colors.black87),
            ),
            Row(
              children: [
                Text(
                  "Mobile number",
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  " ${widget.phoneNumber}",
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  " Edit",
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // OTP Input
            PinCodeTextField(
              appContext: context,
              length: 4,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 45, // Adjust size
                fieldWidth: 45, // Adjust size
                inactiveColor: Colors.grey.shade400,
                activeColor: const Color(0xFF0076BE),
                selectedColor: const Color(0xFF0076BE),
              ),
              onChanged: (value) {
                otpCode = value;
              },
            ),

            const SizedBox(height: 30),

            // Confirm Button
            CustomButton(
              text: "Confirm",
              isLoading: false,
              borderRadius: 16,
              onPressed: () {
                if (otpCode.length == 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Entered OTP: $otpCode")),
                  );
                } else {
                  Get.to(() => DashboardScreen());
                }
              },
            ),

            const SizedBox(height: 20),

            // Resend Code
            Center(
              child: Text.rich(
                TextSpan(
                  text: "Didn’t receive the code? ",
                  style: GoogleFonts.roboto(color: Colors.black54),
                  children: [
                    TextSpan(
                      text: "Resend code",
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF0076BE),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/bottom_image.png',
                  height: 353,
                  width: 350,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
