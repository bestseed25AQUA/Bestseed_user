import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:seedsuser/app/auth/controller/otp_verify_controller.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_toast.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String otp; // OTP received from API

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.otp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late TextEditingController _otpController;
  final OtpVerifyController otpController = Get.put(OtpVerifyController());

  @override
  void initState() {
    super.initState();

    // Autofill OTP from API
    _otpController = TextEditingController(text: widget.otp);

    otpController.phoneNumber.value = widget.phoneNumber;
    otpController.otp.value = widget.otp; // set OTP in controller
  }

  // @override
  // void dispose() {
  //   _otpController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0076BE),
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
            Text(
              widget.phoneNumber,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // OTP Input (pre-filled)
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpController,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 45,
                fieldWidth: 45,
                inactiveColor: Colors.grey.shade400,
                activeColor: const Color(0xFF0076BE),
                selectedColor: const Color(0xFF0076BE),
              ),
              onChanged: (value) {
                otpController.otp.value = value;
              },
            ),

            const SizedBox(height: 30),

            // Confirm Button
            Obx(() {
              return otpController.isLoading.value
                  ? Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: "Confirm",
                      isLoading: otpController.isLoading.value,
                      borderRadius: 16,
                      onPressed: () async {
                        if (otpController.otp.value.length == 6) {
                          await otpController.verifyOtp();
                        } else {
                          CustomToast.error("Please enter a valid 6-digit OTP");
                        }
                      },
                    );
            }),

            const SizedBox(height: 20),

            // Resend Code
            Obx(() {
              return Center(
                child: GestureDetector(
                  onTap: otpController.isResending.value
                      ? null
                      : () => otpController.resendOtp(),
                  child: Text(
                    otpController.isResending.value
                        ? "Resending..."
                        : "Didn’t receive the code? Resend code",
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF0076BE),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),

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
