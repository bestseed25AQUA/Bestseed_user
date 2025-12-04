import 'dart:convert';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
  var selectedMonth = ''.obs;
  var selectedYear = ''.obs;
  var selectedDate = ''.obs;
  var filterType = ''.obs;
  Future<void> fetchBookings() async {
    try {
      isLoading.value = true;

      // Build Query
      String query = "";
      if (filterType.value.isNotEmpty) {
        query += "?type=${filterType.value}";
      }
      if (selectedMonth.value.isNotEmpty) {
        query += "?month=${selectedMonth.value}";
      }
      if (selectedYear.value.isNotEmpty) {
        query += query.isEmpty
            ? "?year=${selectedYear.value}"
            : "&year=${selectedYear.value}";
      }
      if (selectedDate.value.isNotEmpty) {
        query += query.isEmpty
            ? "?date=${selectedDate.value}"
            : "&date=${selectedDate.value}";
      }

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/my-bookings$query",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['bookings'] != null) {
          bookingList.assignAll(
            (data['bookings'] as List)
                .map((e) => BookingData.fromJson(e))
                .toList(),
          );
        }
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }

  var isCreateLoading = false.obs;

  Future<bool> createHatcheryBooking({
    required String hatcheryId,
    required String categoryId,
    required String hatcheryName,
    required String customerName,
    required String customerMobile,
    required String unit,
    required String noOfPieces,
    required String droppingLocation,
    required String packingDate,
    required String locationId,
    required bool isSpotHatchery,
  }) async {
    try {
      Map<String, String> body = {
        "hatchery_id": hatcheryId.toString(),
        "hatchery_name": hatcheryName,
        "customer_name": customerName,
        "customer_mobile": customerMobile,
        "unit": unit,
        "no_of_pieces": noOfPieces.toString(),
        "dropping_location": droppingLocation,
        "packing_date": normalizeDate(packingDate),
        "category_id": categoryId,
        // "location_id": locationId.toString(),
      };

      print('second map');
      print(body);
      print('===============++++++++++=================');
      print(body.toString());
      // return false;
      isCreateLoading.value = true;

      final response = await postRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/${isSpotHatchery ? 'book-spot-hatchery' : 'book-hatchery'}",
        headers: await buildHeader(),
        body: body,
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

String normalizeDate(String input) {
  try {
    input = input.trim();

    // Replace all separators with a single dash.
    input = input.replaceAll("/", "-").replaceAll(".", "-");

    // If already in yyyy-MM-dd format, return directly
    final isoMatch = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (isoMatch.hasMatch(input)) {
      return input;
    }

    // For dd-MM-yyyy format → convert to yyyy-MM-dd
    final dmyMatch = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
    final dmy = dmyMatch.firstMatch(input);
    if (dmy != null) {
      final day = dmy.group(1);
      final month = dmy.group(2);
      final year = dmy.group(3);
      return "$year-$month-$day";
    }

    // For MM-dd-yyyy or other formats, try auto parse
    final autoParsed = DateTime.tryParse(input);
    if (autoParsed != null) {
      return DateFormat("yyyy-MM-dd").format(autoParsed);
    }

    return "";
  } catch (e) {
    return "";
  }
}
