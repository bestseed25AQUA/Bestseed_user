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
        // Server rejects anything over 2048 KB, so fail early with a message
        // the user can act on instead of a raw 422 body.
        final sizeInKb = await profileImage.length() / 1024;
        if (sizeInKb > 2048) {
          CustomToast.error(
            "Image is too large (${sizeInKb.toStringAsFixed(0)} KB). "
            "Please pick an image under 2 MB.",
          );
          return;
        }

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
        CustomToast.error(_readableError(response.statusCode, respStr));
      }
    } catch (e) {
      CustomToast.error("Something went wrong: $e");
    } finally {
      isUpdating.value = false;
    }
  }

  /// Turns a Laravel error response into something worth showing a user.
  /// A 422 carries {"message": ..., "errors": {"field": ["reason", ...]}};
  /// anything else falls back to the status code so the failure is still
  /// identifiable from a screenshot.
  String _readableError(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final messages = errors.values
              .expand((value) => value is List ? value : [value])
              .map((value) => value.toString())
              .toList();
          if (messages.isNotEmpty) return messages.join('\n');
        }

        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {
      // Body was not JSON (an HTML error page, say) — fall through.
    }
    return "Update failed (error $statusCode)";
  }
}
