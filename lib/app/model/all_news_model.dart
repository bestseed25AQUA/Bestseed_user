// To parse this JSON data, do
//
//     final allNewsModel = allNewsModelFromJson(jsonString);

import 'dart:convert';

AllNewsModel allNewsModelFromJson(String str) =>
    AllNewsModel.fromJson(json.decode(str));

String allNewsModelToJson(AllNewsModel data) => json.encode(data.toJson());

class AllNewsModel {
  bool? status;
  String? message;
  Data? data;

  AllNewsModel({this.status, this.message, this.data});

  factory AllNewsModel.fromJson(Map<String, dynamic> json) => AllNewsModel(
    status: json["status"],
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  List<ClimateNew>? trendingUpdate;
  List<MedicineNew>? medicineNews;
  List<ClimateNew>? climateNews;

  Data({this.trendingUpdate, this.medicineNews, this.climateNews});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    trendingUpdate: json["trending_update"] == null
        ? []
        : List<ClimateNew>.from(
            json["trending_update"]!.map((x) => ClimateNew.fromJson(x)),
          ),
    medicineNews: json["medicine_news"] == null
        ? []
        : List<MedicineNew>.from(
            json["medicine_news"]!.map((x) => MedicineNew.fromJson(x)),
          ),
    climateNews: json["climate_news"] == null
        ? []
        : List<ClimateNew>.from(
            json["climate_news"]!.map((x) => ClimateNew.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "trending_update": trendingUpdate == null
        ? []
        : List<dynamic>.from(trendingUpdate!.map((x) => x.toJson())),
    "medicine_news": medicineNews == null
        ? []
        : List<dynamic>.from(medicineNews!.map((x) => x.toJson())),
    "climate_news": climateNews == null
        ? []
        : List<dynamic>.from(climateNews!.map((x) => x.toJson())),
  };
}

class ClimateNew {
  int? id;
  String? title;
  String? mediaType;
  String? mediaPath;
  String? createdAt;

  ClimateNew({
    this.id,
    this.title,
    this.mediaType,
    this.mediaPath,
    this.createdAt,
  });

  factory ClimateNew.fromJson(Map<String, dynamic> json) => ClimateNew(
    id: json["id"],
    title: json["title"],
    mediaType: json["media_type"],
    mediaPath: json["media_path"],
    createdAt: json["created_at"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "media_type": mediaType,
    "media_path": mediaPath,
    "created_at": createdAt,
  };
}

class MedicineNew {
  int? id;
  String? medicineName;
  String? curesFor;
  String? mediaType;
  String? mediaPath;
  String? createdAt;

  MedicineNew({
    this.id,
    this.medicineName,
    this.curesFor,
    this.mediaType,
    this.mediaPath,
    this.createdAt,
  });

  factory MedicineNew.fromJson(Map<String, dynamic> json) => MedicineNew(
    id: json["id"],
    medicineName: json["medicine_name"],
    curesFor: json["cures_for"],
    mediaType: json["media_type"],
    mediaPath: json["media_path"],
    createdAt: json["created_at"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "medicine_name": medicineName,
    "cures_for": curesFor,
    "media_type": mediaType,
    "media_path": mediaPath,
    "created_at": createdAt,
  };
}
