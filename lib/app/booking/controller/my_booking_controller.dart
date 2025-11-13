import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/my_booking_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

var bookingDummy = {
  "status": true,
  "message": "Your bookings fetched successfully",
  "data": [
    {
      "booking_id": 6,
      "hatchery_name": "My Test Hatchery",
      "customer_name": "Nabeela Fatima",
      "customer_mobile": "9700912007",
      "unit": "Vizag Unit-2",
      "no_of_pieces": 500,
      "dropping_location": "17-2-14/A New Market Hyderabad",
      "packing_date": "2025-11-15T00:00:00.000000Z",
      "hatchery_location": "Hyderabad",
      "created_at": "2025-11-12 07:49:30",
    },

    {
      "booking_id": 6,
      "hatchery_name": "My Test Hatchery",
      "customer_name": "Nabeela Fatima",
      "customer_mobile": "9700912007",
      "unit": "Vizag Unit-2",
      "no_of_pieces": 500,
      "dropping_location": "17-2-14/A New Market Hyderabad",
      "packing_date": "2025-11-15T00:00:00.000000Z",
      "hatchery_location": "Hyderabad",
      "created_at": "2025-11-12 07:49:30",
    },
  ],
};

class MyBookingController extends GetxController {
  var isLoading = true.obs;
  var bookingList = <BookingData>[].obs;

  Future<void> fetchBookings() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/my-bookings",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> listData = data['data'];
          bookingList.assignAll(
            listData.map((e) => BookingData.fromJson(e)).toList(),
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

  var isCreateLoading = false.obs;

  Future<bool> createHatcheryBooking({
    required String hatcheryId,
    required String hatcheryName,
    required String customerName,
    required String customerMobile,
    required String unit,
    required String noOfPieces,
    required String droppingLocation,
    required String packingDate,
    required String locationId,
  }) async {
    try {
      print({
        "hatchery_id": hatcheryId.toString(),
        "hatchery_name": hatcheryName,
        "customer_name": customerName,
        "customer_mobile": customerMobile,
        "unit": unit,
        "no_of_pieces": noOfPieces.toString(),
        "dropping_location": droppingLocation,
        "packing_date": packingDate,
        "location_id": locationId.toString(),
      });
      isCreateLoading.value = true;

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/book-spot-hatchery",
        headers: await buildHeader(),
        body: {
          "hatchery_id": hatcheryId.toString(),
          "hatchery_name": hatcheryName,
          "customer_name": customerName,
          "customer_mobile": customerMobile,
          "unit": unit,
          "no_of_pieces": noOfPieces.toString(),
          "dropping_location": droppingLocation,
          "packing_date": packingDate,
          // "location_id": locationId.toString(),
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == true) {
          CustomToast.success(
            data['message'] ?? "Booking created successfully",
          );
          return true;
        } else {
          CustomToast.error(data['message'] ?? "Booking failed");
        }
      } else {
        CustomToast.error(data['message'] ?? "Failed to create booking");
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isCreateLoading.value = false;
    }
    return false;
  }
}
