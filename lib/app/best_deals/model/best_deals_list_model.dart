import 'dart:convert';

BestDealsListModel bestDealsListModelFromJson(String str) =>
    BestDealsListModel.fromJson(json.decode(str));

class BestDealsListModel {
  bool? status;
  String? message;
  List<BestDealItem>? data;

  BestDealsListModel({this.status, this.message, this.data});

  factory BestDealsListModel.fromJson(Map<String, dynamic> json) =>
      BestDealsListModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<BestDealItem>.from(
                json["data"]!.map((x) => BestDealItem.fromJson(x)),
              ),
      );
}

class BestDealItem {
  int? id;
  String? title;
  String? subtitle;
  String? mediaType;
  String? mediaPath;
  List<String>? mediaFiles;
  List<String>? mediaTypes;
  String? createdAt;

  BestDealItem({
    this.id,
    this.title,
    this.subtitle,
    this.mediaType,
    this.mediaPath,
    this.mediaFiles,
    this.mediaTypes,
    this.createdAt,
  });

  factory BestDealItem.fromJson(Map<String, dynamic> json) {
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
    return BestDealItem(
      id: json["id"],
      title: json["title"],
      subtitle: json["subtitle"],
      mediaType: json["media_type"],
      mediaPath: json["media_path"],
      mediaFiles: files,
      mediaTypes: types,
      createdAt: json["created_at"],
    );
  }
}
