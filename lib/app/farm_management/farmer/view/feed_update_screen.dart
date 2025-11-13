import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/tank_controller.dart';

// ignore: must_be_immutable
class FeedUpdateScreen extends StatelessWidget {
  FeedUpdateScreen({super.key, required this.farmId});
  final String farmId;
  final tankController = Get.find<TankController>();

  List<String> mealsDropDownList = ['0', '1', '2', '3', '4'];

  @override
  Widget build(BuildContext context) {
    // Call API when page opens

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Adding feed'),
      ),
      body: Obx(() {
        if (tankController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final tanks = tankController.farmList.value?.data ?? [];

        if (tanks.isEmpty) {
          return const Center(child: Text("No Tank Found"));
        }

        return Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      "Today's feed Update",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Center(
                    child: Text(
                      "16/09/2025",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                      
                  // ✅ Dynamic Tank List UI
                  ListView.builder(
                    itemCount: tanks.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final tank = tanks[index];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FeedUpdateCard(
                          mealsDropDownList: mealsDropDownList,
                          tankName: tank.tankName ?? "",
                          dayInfo:
                              "16 Day",
                          initialMeals: tank.meals?.toString() ?? "0",
                          initialQuantity: tank.feedQuantity ?? "0",
                          showEditButton: tank.status == 1,
                          showAddButton: tank.status == 0,
                          onTapEdit: () {
                            if (!tankController.isAddingTodayTankQuntity.value) {
                              tankController.addTodayTankQuntity(farmId: farmId);
                            }
                          },
                          onTapAdd: () {
                            if (!tankController.isAddingTodayTankQuntity.value) {
                              tankController.addTodayTankQuntity(farmId: farmId);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (tankController.isAddingTodayTankQuntity.value)
            Positioned(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(.3)
                ),
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class FeedUpdateCard extends StatelessWidget {
  final String tankName;
  final String dayInfo;
  final String initialMeals;
  final String initialQuantity;
  final bool showEditButton;
  final bool showAddButton;
  final List<String> mealsDropDownList;
  final VoidCallback onTapEdit;
  final VoidCallback onTapAdd;

  const FeedUpdateCard({
    super.key,
    required this.tankName,
    required this.dayInfo,
    required this.initialMeals,
    required this.initialQuantity,
    this.showEditButton = false,
    this.showAddButton = false,
    required this.mealsDropDownList,
    required this.onTapEdit,
    required this.onTapAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(16),
      //   color: Colors.white,
      // ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Tank Name and Day Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  tankName,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dayInfo,
                  style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Meals Section
            Text(
              'Meals',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4.0),
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 12.0),
            //   decoration: BoxDecoration(
            //     border: Border.all(color: Colors.grey.shade300),
            //     borderRadius: BorderRadius.circular(4.0),
            //   ),
            //   child: DropdownButtonHideUnderline(
            //     child: DropdownButton<String>(
            //       value: mealsDropDownList.contains(initialMeals)
            //           ? initialMeals
            //           : null,
            //       isExpanded: true,
            //       icon: const Icon(Icons.keyboard_arrow_down),
            //       items: mealsDropDownList.map<DropdownMenuItem<String>>((
            //         String value,
            //       ) {
            //         return DropdownMenuItem<String>(
            //           value: value,
            //           child: Text(value),
            //         );
            //       }).toList(),
            //       onChanged: (String? newValue) {
            //         // Handle meal selection change
            //       },
            //     ),
            //   ),
            // ),
             TextFormField(
               initialValue: initialMeals,
               keyboardType: TextInputType.number,
               decoration: InputDecoration(
                 border: const OutlineInputBorder(),
                 contentPadding: const EdgeInsets.symmetric(
                   vertical: 10.0,
                   horizontal: 10.0,
                 ),
                 isDense: true,
                 enabledBorder: OutlineInputBorder(
                   borderSide: BorderSide(color: Colors.grey.shade300),
                   borderRadius: BorderRadius.circular(4.0),
                 ),
                 focusedBorder: const OutlineInputBorder(
                   borderSide: BorderSide(color: AppColors.primary),
                   borderRadius: BorderRadius.all(Radius.circular(4.0)),
                 ),
               ),
             ),
            const SizedBox(height: 16.0),

            // Feed Quantity Section
            Text(
              'Feed Quantity',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4.0),
            Row(
              children: <Widget>[
                // Quantity Input Field
                Expanded(
                  child: TextFormField(
                    initialValue: initialQuantity,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 10.0,
                      ),
                      isDense: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),

                // Unit Dropdown ('Kgs')
                SizedBox(
                  width: 100, // Adjust width as needed
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: 'Kgs',
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: <String>['Kgs', 'Grams', 'Lbs']
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                        onChanged: (String? newValue) {
                          // Handle unit selection change
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Action Buttons (Edit or Add)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showEditButton)
                  OutlinedButton(
                    onPressed:onTapEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 10.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                    child: const Text('Edit'),
                  ),
                if (showAddButton)
                  ElevatedButton(
                    onPressed: onTapAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 10.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                    child: const Text('Add'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
