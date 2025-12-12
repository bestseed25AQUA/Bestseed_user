import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:seedsuser/app/booking/model/booking_detail_model.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/my_booking_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

// var bookingDummy = {
//   "status": true,
//   "message": "Your bookings fetched successfully",
//   "data": [
//     {
//       "booking_id": 6,
//       "hatchery_name": "My Test Hatchery",
//       "customer_name": "Nabeela Fatima",
//       "customer_mobile": "9700912007",
//       "unit": "Vizag Unit-2",
//       "no_of_pieces": 500,
//       "dropping_location": "17-2-14/A New Market Hyderabad",
//       "packing_date": "2025-11-15T00:00:00.000000Z",
//       "hatchery_location": "Hyderabad",
//       "created_at": "2025-11-12 07:49:30",
//     },

//     {
//       "booking_id": 6,
//       "hatchery_name": "My Test Hatchery",
//       "customer_name": "Nabeela Fatima",
//       "customer_mobile": "9700912007",
//       "unit": "Vizag Unit-2",
//       "no_of_pieces": 500,
//       "dropping_location": "17-2-14/A New Market Hyderabad",
//       "packing_date": "2025-11-15T00:00:00.000000Z",
//       "hatchery_location": "Hyderabad",
//       "created_at": "2025-11-12 07:49:30",
//     },
//   ],
// };

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
    } catch (e, s) {
      print('============error========');
      print(e.toString());
      print(s.toString());
      CustomToast.error("Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }

  RxBool isDetailLoading = false.obs;
  Rx<BookingDetailModel?> bookingDetail = Rx<BookingDetailModel?>(null);

  Future<void> fetchBookingDetail(String id) async {
    try {
      isDetailLoading(true);

      final headers = await buildHeader();
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/my-bookings-details/$id",
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        print('==========+++++++++++++===============');
        print(body["booking"]);

        bookingDetail.value = BookingDetailModel.fromJson(body);
        print('===========++++++++=============');
        print(bookingDetail.value?.bookingUId);
      } else {
        // bookingDetail.value = dummyBookingDetail();
      }
      print('=====================');
      print('-----------------');
    } catch (e, s) {
      print(e.toString());
      print(s.toString());
      // bookingDetail.value = dummyBookingDetail();
    } finally {
      isDetailLoading(false);
    }
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      // isDetailLoading(true);
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        barrierDismissible: false,
      );
      final headers = await buildHeader();

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/cancel-booking",
        headers: headers,
        body: {"booking_id": bookingId, "reason_code": reason},
      );
      print({"booking_id": bookingId, "reason_code": reason});
      print('status code');
      print(response.statusCode);
      final body = jsonDecode(response.body);
      print(body);
      if (body["status"] == true) {
        isDetailLoading(false);
        CustomToast.success('Cancelled');
        await fetchBookingDetail(bookingId);
        await fetchBookings(); // reload
      } else {
        CustomToast.error('Failed to Cancel');
      }
    } catch (e, s) {
      print(e.toString());
      print(s.toString());
      CustomToast.error('Failed to Cancel');
    } finally {
      if (isDetailLoading.value) isDetailLoading(false);
      Get.back();
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
      print('====is spot hatchery $isSpotHatchery========');
      print("${NetworkConfig.baseURL}/farmer/${isSpotHatchery ? 'book-spot-hatchery' : 'book-hatchery'}");
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

// BookingDetailModel dummyBookingDetail() {
//   return BookingDetailModel(
//     bookingId: "244355",
//     status: "Booking Confirmed",
//     statusDescription:
//         "We’ve received your booking. Within a few hours, we will assign your vehicle",
//     bookingDateTime: "12:30PM, 25/11/2025",
//     unitLocation: "Kakinada",
//     pieces: "12,000",
//     estimatedPrice: "₹1,20,000",
//     droppingLocation: "9-186, Prakash Nagar, Hyderabad, Telangana, 500032",
//     preferredDate: "21-11-2025",
//     bookingStatus: [
//       BookingStatusStep(
//         title: "Booking Confirmed",
//         date: "Mon, 21-11-2025",
//         time: "12:23 PM",
//         status: 1,
//       ),
//       BookingStatusStep(
//         title: "Driver Assigned",
//         date: "Mon, 21-11-2025",
//         time: "12:23 PM",
//         status: 1,
//       ),
//       BookingStatusStep(
//         title: "In Progress",
//         date: "Mon, 21-11-2025",
//         time: "12:23 PM",
//         status: 0,
//       ),
//       BookingStatusStep(
//         title: "Delivered",
//         date: "Mon, 21-11-2025",
//         time: "12:23 PM",
//         status: 0,
//       ),
//     ],
//   );
// }
