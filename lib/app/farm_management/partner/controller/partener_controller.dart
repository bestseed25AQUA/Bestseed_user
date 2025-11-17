import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/partner/model/partner_list_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class PartnerController extends GetxController {
  var isLoading = true.obs;

  var partnerList = <Partner>[].obs;

  Future<void> fetchPartners() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/partner/parteners",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data["status"] == true && data["data"] != null) {
          final List<dynamic> list = data["data"];
          partnerList.assignAll(list.map((e) => Partner.fromJson(e)).toList());
        }
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }

  // CREATE / UPDATE PARTNER
  RxBool isCreateLoading = false.obs;

  Future<bool> createPartner({
    required String name,
    required String phone,
    required bool viewAccess,
    required bool editAccess,
    String? id,
  }) async {
    isCreateLoading.value = true;

    try {
      Map<String, dynamic> body = {
        "name": name,
        "phone": phone,
        "view_access": viewAccess ? "1" : "0",
        "edit_access": editAccess ? "1" : "0",
        "read_access": "0",
        "delete_access": "0",
        if (id != null) "partner_id": id,
      };

      print(body);

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/partner/create",
        headers: await buildHeader(),
        body: body,
      );

      isCreateLoading.value = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final res = jsonDecode(response.body);

        if (res["status"] == true) {
          CustomToast.success("Partner Saved!");
          return true;
        }
      }
      print('========++++++++++++++==========');
      print("${NetworkConfig.baseURL}/partner/create");
      print(jsonDecode(response.body));

      CustomToast.error("Failed to save partner");
    } catch (e) {
      CustomToast.error("Something went wrong");
    }

    return false;
  }

  RxBool isAccessUpdating = false.obs;

  Future<bool> removePartnerAccess({
    required String id,
    required String accessType,
  }) async {
    isAccessUpdating(true);

    try {
      Map<String, dynamic> body = {"partner_id": id, accessType: "0"};

      print(body);

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/partner/remove-access",
        headers: await buildHeader(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["status"] == true) {
          CustomToast.success("Access Updated!");
          return true;
        }
      }

      CustomToast.error("Failed to update access");
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isAccessUpdating(false);
    }

    return false;
  }

  // DELETE PARTNER
  RxBool isDeleting = false.obs;

  Future<bool> deletePartner({required String id}) async {
    isDeleting(true);

    try {
      Map<String, dynamic> body = {"id": id};

      print("===== DELETE PARTNER BODY =====");
      print(body);

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/partner/delete",
        headers: await buildHeader(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"] == true) {
          CustomToast.success("Deleted Successfully!");
          return true;
        }
      }

      CustomToast.error("Failed to delete partner");
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isDeleting(false);
    }
    return false;
  }
}
