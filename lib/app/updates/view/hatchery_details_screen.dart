import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/view/hatchery_category_screen.dart';
import 'package:seedsuser/app/language/language_screen.dart';
import 'package:seedsuser/app/notification/notification_screen.dart';
import 'package:seedsuser/app/profile/view/profile_screen.dart';
import 'package:seedsuser/app/common/full_image_screen.dart';
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
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
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
            Obx(() {
              final data = hatcheryUpdatesController.hatcherySingleData.value?.data;
              final hasData = data != null && data.isNotEmpty;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 214, 232, 243),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ---------- LOGO (tap to fullscreen) ----------
                    GestureDetector(
                      onTap: hasData && (data[0].thumbnail ?? '').isNotEmpty
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullImageScreen(
                                    imageUrl: data[0].thumbnail!,
                                    title: data[0].hatcheryName ?? '',
                                  ),
                                ),
                              )
                          : null,
                      child: ClipOval(
                        child: Image.network(
                          hasData ? (data[0].thumbnail ?? '') : '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ---------- NAME + LOCATION (tap to navigate) ----------
                    Expanded(
                      child: InkWell(
                        onTap: hasData && (data[0].hatcheryId ?? '').isNotEmpty
                            ? () => Get.to(() => HatcheryCateogryScreen(
                                  hatcheryId: data[0].hatcheryId!,
                                  hatcheryName: data[0].hatcheryName ?? '',
                                  useHatcheryId: true,
                                ))
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasData ? (data[0].hatcheryName ?? '') : '',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),


                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
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
