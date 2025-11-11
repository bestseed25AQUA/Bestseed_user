import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class FarmerDetailController extends GetxController {
  RxBool isLoading = false.obs;

  /// ------------ ADD NEW FARM ---------------- ///
  Future<void> uploadFarmData({
    required String farmName,
    required String stockingDate,
    required String store,
    required String lowFeedLimit,
    required String tanks,
    required List<String> imagePaths,
  }) async {
    try {
      isLoading(true);

      var response = await multipartPostRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/create-farm",
        fields: {
          "type": "form",
          "farm_name": farmName,
          "stocking_date": stockingDate,
          "store": store,
          "low_feed_limit": lowFeedLimit,
          "tanks": tanks,
        },
        headers: await buildHeader(),
        imagePaths: imagePaths,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success("Farm added successfully ✔");
      } else {
        CustomToast.error("Failed to add farm ❌");
      }
    } catch (e) {
      CustomToast.error("Error  ");
    } finally {
      isLoading(false);
    }
  }

  /// ------------- UPDATE FARM DETAILS ----------------- ///
  Future<void> updateFarmData({
    required int farmId,
    required String farmName,
    required String stockingDate,
    required String store,
    required String lowFeedLimit,
    required String tanks,
    required List<String> imagePaths,
  }) async {
    try {
      isLoading(true);

      var response = await multipartPostRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farms/$farmId",
        fields: {
          "farm_name": farmName,
          "stocking_date": stockingDate,
          "store": store,
          // "low_feed_limit": lowFeedLimit,
          "no_of_tanks": tanks
        },
        headers: await buildHeader(),
        imagePaths: imagePaths,
      );
      print('response is = ${response.stream.toString()}');
      print('status code = ${response.statusCode.toString()}');

      if (response.statusCode == 200) {
        CustomToast.success("Farm updated successfully ✔");
      } else {
        CustomToast.error("Failed to update farm ❌");
      }
    } catch (e) {
      CustomToast.error("Something went wrong ❌");
    } finally {
      isLoading(false);
    }
  }

  /// -------------  DELETE FARM ----------------- ///
  Future<bool> deleteFarm({required String farmId}) async {
    try {
      isLoading(true);
      String url  =  "${NetworkConfig.baseURL}/farmer/farm/delete/$farmId"; 
      print(url);

      var response = await getRequest(
        endPoint: url,
        headers: await buildHeader(),
      );
       print('============response==============');

       print(response.body);
      if (response.statusCode == 200) {
        CustomToast.success("Farm deleted successfully ✔");
        return true;
      } else {
        CustomToast.error("Failed to delete");
      }
    } catch (e) {
      CustomToast.error("Error deleting");
    } finally {
      isLoading(false);
    }
    return false;
  }
}
