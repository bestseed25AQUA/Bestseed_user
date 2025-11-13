import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/manager/model/manager_list_model.dart';
import 'package:seedsuser/app/farm_management/manager/view/manager_screen.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';
import 'package:seedsuser/app/model/my_booking_model.dart';

var managerDummy = {
  "status": true,
  "message": "Manager list fetched successfully",
  "data": [
    {
      "name": "John Doe",
      "phone_number": "9998887776",
      "can_edit": true,
      "can_view": true,
      "can_delete": false,
      "can_create": true,
    },
    {
      "name": "Rohan Sharma",
      "phone_number": "9876543210",
      "can_edit": false,
      "can_view": true,
      "can_delete": false,
      "can_create": false,
    },
  ],
};

class ManagerController extends GetxController {
  var isLoading = true.obs;
  var managerList = <Manager>[].obs;

  Future<void> fetchManagers() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/manager/list", // change API if needed
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> listData = data['data'];
          managerList.assignAll(
            listData.map((e) => Manager.fromJson(e)).toList(),
          );
          return;
        }
      }
    } catch (e) {
      CustomToast.error("Something went wrong, showing offline data");
    } finally {
      // ✅ Assign dummy data if API fails
      try {
        final List<dynamic> dummy = managerDummy["data"] as List;
        managerList.assignAll(dummy.map((e) => Manager.fromJson(e)).toList());
      } catch (e) {
        print("Dummy Error: $e");
      }
      isLoading.value = false;
    }
  }

  RxBool isCreateLoading = false.obs;

  /// ✅ Create Manager API
  Future<bool> createManager({
    required String personName,
    required String phoneNumber,
    required bool canEdit,
    required bool canView,
    required bool canDelete,
    required bool canCreate,
  }) async {
    isCreateLoading.value = true;

    try {
      var url = Uri.parse(
        "${NetworkConfig.baseURL}/manager/createManager",
      ); // 🔥 replace with your correct API

      Map<String, dynamic> body = {
        "name": personName,
        "phone": phoneNumber,
        "can_edit": canEdit,
        "can_view": canView,
        "can_delete": canDelete,
        "can_create": canCreate,
      };
      final response = await postRequest(
        endPoint:
            "${NetworkConfig.baseURL}/manager/list", // change API if needed
        headers: await buildHeader(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["status"] == true) {
          CustomToast.success('Added');

          return true;
        } else {
          CustomToast.success('Failed');
        }
      } else {
        CustomToast.success('Failed');
      }
    } catch (e) {
      CustomToast.success('Failed');
    }

    isCreateLoading.value = false;
    return false;
  }
}
