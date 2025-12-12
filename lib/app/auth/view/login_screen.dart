import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/auth/controller/auth_controller.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';

class LoginWithMobileScreen extends StatefulWidget {
  const LoginWithMobileScreen({super.key});

  @override
  State<LoginWithMobileScreen> createState() => _LoginWithMobileScreenState();
}

class _LoginWithMobileScreenState extends State<LoginWithMobileScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Initialize AuthController
  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo section
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/login_image.png',
                  height: 353,
                  width: 350,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // White container section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Login with mobile number",
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "We will send you a 6-digit OTP to verify your mobile number.",
                      style: GoogleFonts.roboto(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: "Enter your mobile number",
                        counterText: "",

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter mobile number";
                        } else if (value.length != 10) {
                          return "Enter valid 10-digit number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      return authController.isLoading.value
                          ? Center(child: CircularProgressIndicator())
                          : CustomButton(
                              text: "Continue",
                              isLoading: authController.isLoading.value,
                              borderRadius: 16,
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  authController.phoneNumber.value =
                                      _phoneController.text.trim();

                                  await authController.sendOtp();
                                }
                              },
                            );
                    }),

                    // CustomButton(
                    //   text: "Continue",
                    //   isLoading: false,
                    //   borderRadius: 16,
                    //   onPressed: () {
                    //     if (_formKey.currentState!.validate()) {
                    //       Get.to(
                    //         () => OtpVerificationScreen(
                    //           phoneNumber: _phoneController.text,
                    //         ),
                    //       );
                    //     }
                    //   },
                    // ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "By sign-in, I agree to the ",
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          children: [
                            TextSpan(
                              text: "Terms & Conditions",
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: " and "),
                            TextSpan(
                              text: "Privacy Policy",
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: " of BestSeed."),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
