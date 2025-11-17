import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/manager/model/manager_list_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class ManagerController extends GetxController {
  var isLoading = true.obs;
  var managerList = <Manager>[].obs;

  Future<void> fetchManagers() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/manager/managers", // change API if needed
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
      isLoading.value = false;
    }
  }

  RxBool isCreateLoading = false.obs;

  Future<bool> createManager({
    required String personName,
    required String phoneNumber,
    required bool canEdit,
    required bool canView,
    required bool canDelete,
    required bool canCreate,
    String? id,
  }) async {
    isCreateLoading.value = true;

    try {
      Map<String, dynamic> body = {
        "name": personName,
        "phone": phoneNumber,
        "edit_access": canEdit ? "1" : "0",
        "view_access": canView ? "1" : "0",
        "delete_access": canDelete ? "1" : "0",
        "read_access": canCreate ? "1" : "0",
        if (id != null) "manager_id": id,
      };
      print('=======------------========');
      print(body);
      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/manager/create",
        headers: await buildHeader(),
        body: body,
      );
      isCreateLoading.value = false;
      if (response.statusCode == 201 || response.statusCode == 200) {
        CustomToast.success('Successfully saved!');
        return true;
      } else {
        CustomToast.error('Failed');
      }
    } catch (e) {
      CustomToast.error('Failed');
    }
    return false;
  }

  RxBool isAccessUpdating = false.obs;

  Future<bool> removeAccess({
    required String id,
    required String accessType,
  }) async {
    isAccessUpdating(true);

    try {
      Map<String, dynamic> body = {"manager_id": id, accessType: "0"};

      print("===== REMOVE ACCESS BODY =====");
      print(body);
      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/manager/remove-access",
        headers: await buildHeader(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["status"] == true) {
          CustomToast.success('Access updated!');
          return true;
        }
      }

      CustomToast.error('Failed to update access');
    } catch (e) {
      CustomToast.error('Something went wrong');
    } finally {
      isAccessUpdating(false);
    }

    return false;
  }

  RxBool isDeleting = false.obs;

  Future<bool> deleteManager({required String id}) async {
    isDeleting(true);
    try {
      Map<String, dynamic> body = {"id": id};
      print(body);

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/manager/delete",
        headers: await buildHeader(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["status"] == true) {
          CustomToast.success('Deleted Successfully!');
          return true;
        }
      }
      CustomToast.error('Failed to delete manager');
    } catch (e) {
      CustomToast.error('Something went wrong');
    } finally {
      isDeleting(false);
    }
    return false;
  }
}
