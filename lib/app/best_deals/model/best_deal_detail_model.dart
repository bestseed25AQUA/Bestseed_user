import 'dart:convert';

BestDealDetailModel bestDealDetailModelFromJson(String str) =>
    BestDealDetailModel.fromJson(json.decode(str));

class BestDealDetailModel {
  bool? status;
  String? message;
  BestDealDetail? data;

  BestDealDetailModel({this.status, this.message, this.data});

  factory BestDealDetailModel.fromJson(Map<String, dynamic> json) =>
      BestDealDetailModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : BestDealDetail.fromJson(json["data"]),
      );
}

class BestDealDetail {
  int? id;
  String? title;
  String? subtitle;
  String? description;
  String? mediaType;
  String? mediaPath;
  List<String>? mediaFiles;
  List<String>? mediaTypes;
  String? callNumber;
  String? whatsappNumber;
  String? createdAt;

  BestDealDetail({
    this.id,
    this.title,
    this.subtitle,
    this.description,
    this.mediaType,
    this.mediaPath,
    this.mediaFiles,
    this.mediaTypes,
    this.callNumber,
    this.whatsappNumber,
    this.createdAt,
  });

  factory BestDealDetail.fromJson(Map<String, dynamic> json) {
    List<String>? files;
    List<String>? types;
    if (json["media_files"] != null && json["media_files"] is List) {
      files = List<String>.from(
        json["media_files"].map((x) => x.toString()),
      );
      types = json["media_types"] != null && json["media_types"] is List
          ? List<String>.from(
              json["media_types"].map((x) => x.toString()),
            )
          : [];
    } else if (json["media_path"] != null &&
        json["media_path"].toString().isNotEmpty) {
      files = [json["media_path"].toString()];
      types = [json["media_type"]?.toString() ?? 'image'];
    }
    return BestDealDetail(
      id: json["id"],
      title: json["title"],
      subtitle: json["subtitle"],
      description: json["description"],
      mediaType: json["media_type"],
      mediaPath: json["media_path"],
      mediaFiles: files,
      mediaTypes: types,
      callNumber: json["call_number"],
      whatsappNumber: json["whatsapp_number"],
      createdAt: json["created_at"],
    );
  }
}
