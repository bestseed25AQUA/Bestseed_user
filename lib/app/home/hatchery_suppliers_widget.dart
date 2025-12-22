import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/broadstock/controller/brood_stock_controller.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/dashboard/dashboard_controller.dart';
import 'package:seedsuser/app/model/brood_stock_model.dart';
import 'package:shimmer/shimmer.dart';

class HatcherySuppliersWidget extends StatelessWidget {
  HatcherySuppliersWidget({super.key});
  final DashboardController dashboardController = DashboardController();
  @override
  Widget build(BuildContext context) {
    final dashboardCtrl = Get.find<DashboardController>();
    final broodStockController = Get.put(BroodStockController());
    return Obx(() {
      return Padding(
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
            // ignore: prefer_is_empty
            (broodStockController.homeBroodStocks.length) == 0
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'No hatchery / broodstock found',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(
                     ( broodStockController.homeBroodStocks.length <= 5 ) ? broodStockController.homeBroodStocks.length:5,
                      (index) {
                        final data =
                            broodStockController.homeBroodStocks[index];
                        return InkWell(
                          onTap: () {
                            if (kDebugMode) {
                              print('working');
                            }
                            dashboardCtrl.changeIndex(2);
                          },
                          child: _buildHatcheryCard(data,context),
                        );
                      },
                    ),
                  ),
          ],
        ),
      );
    });
    
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

    Widget _buildHatcheryCard(BroodstockData data,BuildContext context) {
    return Ink(
      // elevation: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(width: 1, color: Colors.grey.withOpacity(.1)),
        boxShadow: [BoxShadow(color: Colors.black)],
      ),

      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Material(
        elevation: 1,
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1 → Name + Count
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      data.hatcheryName,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Text(
                    "Count",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Row 2 → Location
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      "Location",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    data.availableQuantity,
                    style: GoogleFonts.roboto(
                      fontSize: 17,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Supplier + Imported Date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.supplierName,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Text(
                    data.importedDate,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Chips Row → Available + Packing (conditional)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (data.availableOn.isNotEmpty)
                    _buildChip(context,
                      label: data.availableOn.replaceAll(" on", ''),
                      bgColor: Colors.green.withOpacity(0.15),
                      textColor: Colors.green[800]!,
                    ),

                  // if (data.availableOn.isNotEmpty && data.packingStart.isNotEmpty)
                  //   const SizedBox(width: 10),
                  if (data.packingStart.isNotEmpty)
                    _buildChip(context,
                      label: "${data.packingStart}",
                      bgColor: Colors.blue.withOpacity(0.15),
                      textColor: Colors.blue[700]!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context,{
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * .4 - 22,
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

