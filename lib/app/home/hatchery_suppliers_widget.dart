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
        padding: const EdgeInsets.only(top: 8,bottom: 8,right: 10,left: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hatchery / Broodstock",
                  style: GoogleFonts.roboto(
                    fontSize: 17,
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
                      fontWeight: FontWeight.w600,fontSize: 14
                    ),
                  ),
                ),
              ],
            ),
            (broodStockController.homeBroodStocks.isEmpty)
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4,right: 8),
                      child: Text(
                        'No hatchery / broodstock found',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(
                     ( broodStockController.homeBroodStocks.length <= 5 ) ? broodStockController.homeBroodStocks.length:5,
                      (index) {
                        final data =
                            broodStockController.homeBroodStocks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              if (kDebugMode) {
                                print('working');
                              }
                              dashboardCtrl.changeIndex(2);
                            },
                            child: _buildHatcheryCard(data,context),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      );
    });
    
  }

    Widget _buildHatcheryCard(BroodstockData data,BuildContext context) {
      print("checking for data availability ${data.availableOn}");
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                        fontSize: 14,
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
                      data.locationName.isNotEmpty ? data.locationName : "Location",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    data.availableQuantity.replaceAll("Pieces", ""),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
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
              fontSize: 14,
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

