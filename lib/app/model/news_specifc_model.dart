// To parse this JSON data, do
//
//     final newsSpecificModel = newsSpecificModelFromJson(jsonString);

import 'dart:convert';

NewsSpecificModel newsSpecificModelFromJson(String str) => NewsSpecificModel.fromJson(json.decode(str));

String newsSpecificModelToJson(NewsSpecificModel data) => json.encode(data.toJson());

class NewsSpecificModel {
    bool? status;
    String? message;
    List<Datum>? data;

    NewsSpecificModel({
        this.status,
        this.message,
        this.data,
    });

    factory NewsSpecificModel.fromJson(Map<String, dynamic> json) => NewsSpecificModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    };
}

class Datum {
    int? id;
    String? medicineName;
    String? curesFor;
    String? mediaType;
    String? mediaPath;
    String? createdAt;
    String? title;

    Datum({
        this.id,
        this.medicineName,
        this.curesFor,
        this.mediaType,
        this.mediaPath,
        this.createdAt,
        this.title
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["id"],
        medicineName: json["medicine_name"],
        curesFor: json["cures_for"],
        mediaType: json["media_type"],
        mediaPath: json["media_path"],
        createdAt: json["created_at"],
        title: json['title']
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "medicine_name": medicineName,
        "cures_for": curesFor,
        "media_type": mediaType,
        "media_path": mediaPath,
        "created_at": createdAt,
        "title": title
    };
}
