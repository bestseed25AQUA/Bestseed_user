import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class HomeController extends GetxController {
  var isLoading = false.obs;

  var categories = <Category>[].obs;

  @override
  void onInit() {
    super.onInit();
    getCategories();
  }


  Future<void> getCategories() async {
    print('enter in get cat');
    try {
      isLoading.value = true;
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/categories",
        headers: await buildHeader(),
      );
      print('=====get cat apis========');
      print(response.body);
      print(response.statusCode);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List<dynamic> catList = data['categories'];
        categories.assignAll(catList.map((e) => Category.fromJson(e)).toList());
      } else {
        CustomToast.error("Failed to fetch categories: ${response.statusCode}");
      }
    } catch (e, s) {
      print('enter in get cat error');
      print(e);
      print(s);
      CustomToast.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
