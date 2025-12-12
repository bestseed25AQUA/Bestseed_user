import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';
import 'package:seedsuser/app/updates/controller/hatchery_updates_controller.dart';
import 'package:seedsuser/app/updates/view/update_screen.dart';

class HatcheryDetailsScreen extends StatefulWidget {
  HatcheryDetailsScreen({super.key, required this.id});
  final String id;

  @override
  State<HatcheryDetailsScreen> createState() => _HatcheryDetailsScreenState();
}

class _HatcheryDetailsScreenState extends State<HatcheryDetailsScreen> {
  final hatcheryUpdatesController = Get.put(HatcheryUpdatesController());

  @override
  void initState() {
    initFunc();

    super.initState();
  }

  initFunc() async {
    await Future.delayed(Duration(seconds: 1));
    hatcheryUpdatesController.fetchHatcheryUpdatesSingle(id: widget.id);
  }
  @override
  void dispose() {
    // TODO: implement dispose
    hatcheryUpdatesController.isSingleLoading(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
    
        automaticallyImplyLeading: false,
        title: Text(
          'Updates',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          InkWell(
            onTap: () {
              Get.to(() => LanguageSelectionScreen());
            },
            child: Image.asset('assets/images/lan_image.png', height: 32),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: () {
              Get.to(() => NotificationsScreen());
            },
            child: Image.asset('assets/images/notification.png', height: 32),
          ),
          SizedBox(width: 16),
          InkWell(
            onTap: () {
              Get.to(() => ProfileScreen());
            },
            child: Image.asset('assets/images/person.png', height: 32),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 140,
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ---------- IMAGE + NAME ----------
                      Row(
                        children: [
                          ClipOval(
                            child: Image.network(
                              (hatcheryUpdatesController
                                          .hatcherySingleData
                                          .value
                                          ?.data
                                          ?.isEmpty ??
                                      true)
                                  ? ""
                                  : (hatcheryUpdatesController
                                            .hatcherySingleData
                                            .value
                                            ?.data?[0]
                                            .profileImage ??
                                        ''),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey.withOpacity(.2),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: MediaQuery.of(context).size.width*.3,
                            child: Text(
                              (hatcheryUpdatesController
                                          .hatcherySingleData
                                          .value
                                          ?.data
                                          ?.isEmpty ??
                                      true)
                                  ? ""
                                  : (hatcheryUpdatesController
                                            .hatcherySingleData
                                            .value
                                            ?.data?[0]
                                            .hatcheryName ??
                                        ''),
                              style: GoogleFonts.roboto(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ---------- LOCATION ----------
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            (hatcheryUpdatesController
                                        .hatcherySingleData
                                        .value
                                        ?.data
                                        ?.isEmpty ??
                                    true)
                                ? ""
                                : (hatcheryUpdatesController
                                          .hatcherySingleData
                                          .value
                                          ?.data?[0]
                                          .locationName ??
                                      ''),
                            style: GoogleFonts.roboto(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Obx(() {
              if (hatcheryUpdatesController.isSingleLoading.value) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * .3,
                  ),
                  child: CircularProgressIndicator(),
                );
              }
              return ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount:
                    hatcheryUpdatesController
                        .hatcherySingleData
                        .value
                        ?.data
                        ?.length ??
                    0,
                itemBuilder: (context, index) {
                  return PostWidget(
                    postData: hatcheryUpdatesController
                        .hatcherySingleData
                        .value
                        ?.data?[index],
                    // ontap: () {
                    //   hatcheryUpdatesController.fetchHatcheryUpdatesSingle(
                    //     id:
                    //         hatcheryUpdatesController
                    //             .hatcherySingleData
                    //             .value
                    //             ?.data?[index]
                    //             .id
                    //             .toString() ??
                    //         '',
                    //   );
                    //   Get.to(() => HatcheryDetailsScreen());
                    // },
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
