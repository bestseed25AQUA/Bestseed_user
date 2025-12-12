import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
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
                  SizedBox(height: 20,),
                  Center(
                    child: Text(
                      "Today's feed Update",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                    Center(
                    child: Text(
                      "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                      style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                      ),
                    ),
                    ),
                  const SizedBox(height: 24.0),

                  ListView.builder(
                    itemCount: tanks.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.only(left: 10,right: 10),
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final tank = tanks[index];
                      final bool isShowEditButton = tank.feed !=null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FeedUpdateCard(
                          mealsDropDownList: mealsDropDownList,
                          tankName: tank.tankName ?? "",
                          dayInfo: "${tank.day??0} Day",
                          initialMeals: tank.feed?.meals?.toString() ?? "0",
                          initialFeedQuantity: tank.feed?.feedQuantity ?? "0.00",
                          showEditButton: isShowEditButton,
                          showAddButton: !isShowEditButton,
                          onTapEdit:
                              ({
                                required String meals,
                                required String feedQty,
                              }) {
                                if (!tankController
                                    .isAddingTodayTankQuntity
                                    .value) {
                                  tankController.addTodayTankQuntity(
                                    farmId: farmId,
                                    feedQty: feedQty,
                                    mealQty: meals,
                                    tankId: tank.id.toString(),
                                    mealId: '',
                                    feedId: ''
                                  );
                                }
                              },
                          onTapAdd:
                              ({
                                required String meals,
                                required String feedQty,
                              }) {
                                if (!tankController
                                    .isAddingTodayTankQuntity
                                    .value) {
                                  tankController.addTodayTankQuntity(
                                    farmId: farmId,
                                    feedQty: feedQty,
                                    mealQty: meals,
                                    tankId: tank.id.toString(),
                                  );
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
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(.3)),
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

// ignore: must_be_immutable
class FeedUpdateCard extends StatelessWidget {
  final String tankName;
  final String dayInfo;
  final String initialMeals;
  final String initialFeedQuantity;
  final bool showEditButton;
  final bool showAddButton;
  final List<String> mealsDropDownList;
  final Function({required String meals, required String feedQty}) onTapEdit;
  final Function({required String meals, required String feedQty}) onTapAdd;

  FeedUpdateCard({
    super.key,
    required this.tankName,
    required this.dayInfo,
    required this.initialMeals,
    required this.initialFeedQuantity,
    this.showEditButton = false,
    this.showAddButton = false,
    required this.mealsDropDownList,
    required this.onTapEdit,
    required this.onTapAdd,
  });
  String feedQtyText = '';
  String mealText = '';
  @override
  Widget build(BuildContext context) {
    if (feedQtyText.isEmpty) {
      feedQtyText = initialFeedQuantity;
    }
    if (mealText.isEmpty) {
      mealText = initialMeals;
    }
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
            Text(
              'Meals',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4.0),
            TextFormField(
              initialValue: initialMeals,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                mealText = value;
              },
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
                    onChanged: (value) {
                      feedQtyText = value;
                    },
                    initialValue: initialFeedQuantity,
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
                    onPressed: () {
                      onTapEdit(feedQty: feedQtyText, meals: mealText);
                    },
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
                    onPressed: () {
                      onTapAdd(feedQty: feedQtyText, meals: mealText);
                    },
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
