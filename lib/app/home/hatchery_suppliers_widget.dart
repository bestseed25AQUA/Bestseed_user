import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/broadstock/controller/brood_stock_controller.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/model/brood_stock_model.dart';

class HatcherySuppliersWidget extends StatelessWidget {
   HatcherySuppliersWidget({super.key});
final DashboardController dashboardController = DashboardController();
  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<DashboardController>();
    final broodStockController = Get.put(BroodStockController());
    return Obx(() {
      return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hatchery / Broodstock",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      print('taped');
                      dashboardCtrl.changeIndex(2);
                    },
                    child: Text(
                      "View all",
                      style: GoogleFonts.roboto(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
               (broodStockController.homeBroodStocks.length ?? 0) == 0
                  ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'No hatchery / broodstock found',
                          style: TextStyle(fontSize:13),
                        ),
                      ),
                  )
                  :
              Column(
                children: 
                 List.generate(
                  broodStockController.homeBroodStocks.length,
                  (index) {
                    final data = broodStockController.homeBroodStocks[index];
                    return InkWell(
                      onTap: () {
                        print('working');
                        dashboardCtrl.changeIndex(2);
                      },
                      child: _buildHatcheryCard(data),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHatcheryCard(BroodstockData data) {
    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Image.network(
                  data.image,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey[300],
                    // child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.availableOn,
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              data.packingStart,
              style: GoogleFonts.roboto(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.hatcheryName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      data.hatcheryName,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Row(
                //   children: [
                //     const Icon(Icons.location_on, color: Colors.grey, size: 16),
                //     const SizedBox(width: 4),
                //     Text(
                //       data.location,
                //       style: GoogleFonts.roboto(color: Colors.grey),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 8),
                // Text(
                //   data.category.map((e) => e.capitalizeFirst ?? e).join(', '),
                //   style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                // ),
                // const SizedBox(height: 4),
                Text(
                  'Imported Date: ${data.importedDate ?? ''}',
                  style: GoogleFonts.roboto(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Available Quantity',
                  style: GoogleFonts.roboto(color: Colors.grey[700]),
                ),
                Text(
                  data.availableQuantity,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildHatcheryCard({
  //   required String imageUrl,
  //   required String availableDate,
  //   required String packingStartDate,
  //   required String hatcheryName,
  //   required String location,
  //   required String availableQuantity,
  //   required String supplierName,
  //   required String importedDate,
  // }) {
  //   return Container(
  //     padding: const EdgeInsets.all(12.0),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Stack(
  //           children: [
  //             ClipRRect(
  //               borderRadius: BorderRadius.circular(8.0),
  //               child: Image.asset(
  //                 imageUrl,
  //                 fit: BoxFit.cover,
  //                 width: double.infinity,
  //                 height: 120,
  //               ),
  //             ),
  //             Positioned(
  //               top: 8,
  //               right: 8,
  //               child: Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 8,
  //                   vertical: 4,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   borderRadius: BorderRadius.circular(30),
  //                 ),
  //                 child: Text(
  //                   "Available on $availableDate",
  //                   style: GoogleFonts.roboto(
  //                     color: Colors.black,
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 12,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         Text(
  //           "Packing Start From $packingStartDate",
  //           style: GoogleFonts.roboto(
  //             fontWeight: FontWeight.bold,
  //             color: AppColors.primary,
  //           ),
  //         ),
  //         const SizedBox(height: 10),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   hatcheryName,
  //                   style: GoogleFonts.roboto(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 6),
  //                 Row(
  //                   children: [
  //                     const Icon(
  //                       Icons.location_on,
  //                       size: 18,
  //                       color: Colors.grey,
  //                     ),
  //                     const SizedBox(width: 4),
  //                     Text(
  //                       location,
  //                       style: GoogleFonts.roboto(color: Colors.grey),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,

  //               children: [
  //                 Text(
  //                   "Available Quantity",
  //                   style: GoogleFonts.roboto(color: Colors.grey),
  //                 ),
  //                 Text(
  //                   availableQuantity,
  //                   style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),

  //         const SizedBox(height: 8),
  //         Text(
  //           supplierName,
  //           style: GoogleFonts.roboto(
  //             fontSize: 15,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           "Imported Date on $importedDate",
  //           style: GoogleFonts.roboto(color: Colors.grey, fontSize: 12),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
