import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:seedsuser/app/auth/controller/otp_verify_controller.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
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
    _otpController = TextEditingController(text: '');

    otpController.phoneNumber.value = widget.phoneNumber;
    // otpController.otp.value = widget.otp; // set OTP in controller

    // Start the 2-minute timer since OTP was just sent
    otpController.startResendTimer();
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
      appBar: CustomAppBar(
        backgroundColor: const Color(0xFF0076BE),
        elevation: 0,
        title: Text(
          "OTP Verification",
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
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
              final bool isOtpComplete = otpController.otp.value.length == 6;
              return otpController.isLoading.value
                  ? Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: "Confirm",
                      isLoading: otpController.isLoading.value,
                      borderRadius: 16,
                      backgroundColor: isOtpComplete
                          ? const Color(0xFF0076BE)
                          : const Color(0xFF0076BE).withValues(alpha: 0.5),
                      onPressed: () async {
                        if (isOtpComplete) {
                          await otpController.verifyOtp();
                        } else {
                          CustomToast.error("Please enter a valid 6-digit OTP");
                        }
                      },
                    );
            }),

            const SizedBox(height: 20),

            // Resend Code with Timer
            Obx(() {
              final canResend = otpController.canResend;
              final isResending = otpController.isResending.value;
              final timer = otpController.formattedTimer;

              return Center(
                child: Column(
                  children: [
                    if (!canResend && !isResending)
                      Text(
                        "Resend code in $timer",
                        style: GoogleFonts.roboto(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: (isResending || !canResend)
                          ? null
                          : () => otpController.resendOtp(),
                      child: Text(
                        isResending
                            ? "Resending..."
                            : "Didn't receive the code? Resend code",
                        style: GoogleFonts.roboto(
                          color: (canResend && !isResending)
                              ? const Color(0xFF0076BE)
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
