// To parse this JSON data:
//
//     final hatcherUpdateModel = hatcherUpdateModelFromJson(jsonString);

import 'dart:convert';

HatcherUpdateModel hatcherUpdateModelFromJson(String str) =>
    HatcherUpdateModel.fromJson(json.decode(str));

String hatcherUpdateModelToJson(HatcherUpdateModel data) =>
    json.encode(data.toJson());

class HatcherUpdateModel {
  bool? status;
  String? message;
  List<HatcheryData>? data;

  HatcherUpdateModel({
    this.status,
    this.message,
    this.data,
  });

  factory HatcherUpdateModel.fromJson(Map<String, dynamic> json) =>
      HatcherUpdateModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<HatcheryData>.from(
                json["data"].map((x) => HatcheryData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class HatcheryData {
  int? id;

  // Old fields (keep same name)
  String? hatcheryName;
  String? profileImage;
  String? caption;
  List<String>? hashtags;
  List<String>? mediaFiles;
  List<String>? mediaTypes; // NEW: array of media types
  String? mediaType;
  String? postedOn;

  dynamic callUrl;
  dynamic whatsappUrl;
  dynamic facebookUrl;
  String? shareLink;

  // NEW API fields
  String? title;
  String? description;
  String? mediaPath;
  String? thumbnail;
  String? locationName;

  String? vendorName;
  String? vendorMobile;

  String? hatcheryId;

  HatcheryData({
    this.id,
    this.hatcheryName,
    this.profileImage,
    this.caption,
    this.hashtags,
    this.mediaFiles,
    this.mediaTypes,
    this.mediaType,
    this.postedOn,
    this.callUrl,
    this.whatsappUrl,
    this.facebookUrl,
    this.shareLink,
    this.title,
    this.description,
    this.mediaPath,
    this.thumbnail,
    this.vendorName,
    this.vendorMobile,
    this.hatcheryId,
    this.locationName,
  });

  factory HatcheryData.fromJson(Map<String, dynamic> json) {
    // Convert hashtags string → list
    List<String> tagList = [];
    if (json["hashtags"] != null) {
      tagList = json["hashtags"]
          .toString()
          .split(" ")
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    // Parse media_files array from API (with fallback to single media_path)
    List<String> mediaFilesList = [];
    if (json["media_files"] != null && json["media_files"] is List) {
      mediaFilesList = List<String>.from(
          json["media_files"].where((e) => e != null && e.toString().isNotEmpty));
    } else if (json["media_path"] != null &&
        json["media_path"].toString().isNotEmpty) {
      // Fallback to single media_path for backward compatibility
      mediaFilesList = [json["media_path"]];
    }

    // Parse media_types array from API
    List<String> mediaTypesList = [];
    if (json["media_types"] != null && json["media_types"] is List) {
      mediaTypesList = List<String>.from(
          json["media_types"].where((e) => e != null && e.toString().isNotEmpty));
    } else if (json["media_type"] != null) {
      // Fallback to single media_type
      mediaTypesList = [json["media_type"]];
    }

    return HatcheryData(
      id: json["id"],

      // Keep old UI fields working
      hatcheryName: json["hatchery"]?["hatchery_name"] ?? "",
      profileImage: json["hatchery"]?["hatchery_logo"],
      locationName: json["hatchery"]?["location_name"],
      caption: json["description"] ?? "",
      hashtags: tagList,
      mediaFiles: mediaFilesList,
      mediaTypes: mediaTypesList,
      mediaType: json["media_type"],
      postedOn: json["posted_on"],

      callUrl: json["vendor"]?["call_url"],
      whatsappUrl: json["vendor"]?["whatsapp_url"],
      facebookUrl: json["vendor"]?["facebook_url"],

      shareLink: json["share_link"],

      /// New fields preserved
      title: json["title"],
      description: json["description"],
      mediaPath: json["media_path"],
      thumbnail: json["thumbnail"],

      vendorName: json["vendor"]?["name"],
      vendorMobile: json["vendor"]?["mobile"],

      hatcheryId: json["hatchery"]?["id"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "hatchery_name": hatcheryName,
        "location_name": locationName,
        "profile_image": profileImage,
        "caption": caption,
        "hashtags": hashtags ?? [],
        "media_files": mediaFiles ?? [],
        "media_types": mediaTypes ?? [],
        "media_type": mediaType,
        "posted_on": postedOn,
        "call_url": callUrl,
        "whatsapp_url": whatsappUrl,
        "facebook_url": facebookUrl,
        "share_link": shareLink,
        "title": title,
        "description": description,
        "media_path": mediaPath,
        "thumbnail": thumbnail,
        "vendor_name": vendorName,
        "vendor_mobile": vendorMobile,
        "hatchery_id": hatcheryId,
      };
}
