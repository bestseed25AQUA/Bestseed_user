import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/media_carousel_widget.dart';
import 'package:seedsuser/app/news & ads/controller/single_new_detail_controller.dart'; 

class TrendingUpdatesDetailsScreen extends StatefulWidget {
  final String id;
  final String title;

  const TrendingUpdatesDetailsScreen({
    super.key,
    required this.id,
    required this.title,
  });

  @override
  State<TrendingUpdatesDetailsScreen> createState() =>
      _TrendingUpdatesDetailsScreenState();
}

class _TrendingUpdatesDetailsScreenState
    extends State<TrendingUpdatesDetailsScreen> {
  final controller = Get.put(SingleNewDetailController());

  @override
  void initState() {
    super.initState();

    controller.fetch(
      type: "trending updates",
      id: widget.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final data = controller.singleDetailData.value?.data;

      if (data == null) {
        return const Scaffold(
          body: Center(child: Text("No Data Found")),
        );
      }

      // PREPARE LISTS FOR CAROUSEL
      final mediaUrls = [data.mediaPath ?? ""];
      final mediaTypes = [data.mediaType ?? "image"];

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[800],
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          title: Text(
            data.title ?? "",
            style: GoogleFonts.roboto(color: Colors.white),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20,),
              MediaCarouselWidget(
                mediaUrls: mediaUrls,
                mediaTypes: mediaTypes,
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Text(
                  data.title ?? "",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Text(
                  data.description ?? "",
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
