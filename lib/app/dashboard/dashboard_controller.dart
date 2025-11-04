import 'package:get/get.dart';

class DashboardController extends GetxController {
  /// observable index
  var currentIndex = 0.obs;

  /// update index
  void changeIndex(int index) {
    currentIndex.value = index;
  }
}
