import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/my_booking_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class MyBookingController extends GetxController {
  var isLoading = true.obs;
  var bookingList = <Booking>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/my-bookings",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['bookings'] != null) {
          final List<dynamic> bannerList = data['bookings'];
          bookingList.assignAll(
            bannerList.map((e) => Booking.fromJson(e)).toList(),
          );
        } else {
          bookingList.clear();
          CustomToast.error("No Bookings found.");
        }
      } else {
        CustomToast.error("Failed to fetch Bookings: ${response.statusCode}");
      }
    } catch (e) {
      CustomToast.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
