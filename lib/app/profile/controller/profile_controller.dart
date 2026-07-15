import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/safe_back.dart';
import 'package:http/http.dart' as http;
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/profile_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';
import 'package:seedsuser/app/common/local_storage.dart';

class ProfileController extends GetxController {
  var isLoading = false.obs;
  var isUpdating = false.obs;

  Rx<ProfileModel?> profile = Rx<ProfileModel?>(null);

  @override
  void onInit() {
    super.onInit();
    getProfile(); // 🔄 Automatically fetch profile on controller init
  }

  /// Fetch profile data
  Future<void> getProfile() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/profile",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        profile.value = ProfileModel.fromJson(data);
      } else {
        // CustomToast.error("Failed to fetch profile ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }

  /// Update profile with FormData (supports image + fields)
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? language,
    File? profileImage,
  }) async {
    try {
      isUpdating.value = true;
      final token = await AuthLocalStorage.getToken();

      var url = Uri.parse("${NetworkConfig.baseURL}/farmer/update-profile");

      var request = http.MultipartRequest("POST", url);

      // 🔐 Headers
      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      // 🧾 Fields
      if (firstName != null) request.fields['first_name'] = firstName;
      if (lastName != null) request.fields['last_name'] = lastName;
      if (language != null) request.fields['language'] = 'en';

      // 🖼️ Optional profile image
      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', profileImage.path),
        );
      }

      // 🔄 Send request
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success("Profile updated successfully");
        safeBack();
        await getProfile(); // refresh profile
      } else {
        CustomToast.error("Update failed  $respStr");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isUpdating.value = false;
    }
  }
}
