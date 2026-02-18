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
    String? subtitle;
    String? curesFor;
    String? mediaType;
    String? mediaPath;
    List<String>? mediaFiles;
    List<String>? mediaTypes;
    String? createdAt;
    String? title;

    Datum({
        this.id,
        this.medicineName,
        this.subtitle,
        this.curesFor,
        this.mediaType,
        this.mediaPath,
        this.mediaFiles,
        this.mediaTypes,
        this.createdAt,
        this.title,
    });

    factory Datum.fromJson(Map<String, dynamic> json) {
        List<String>? files;
        List<String>? types;
        if (json["media_files"] != null && json["media_files"] is List) {
            files = List<String>.from(json["media_files"].map((x) => x.toString()));
            types = json["media_types"] != null && json["media_types"] is List
                ? List<String>.from(json["media_types"].map((x) => x.toString()))
                : [];
        } else if (json["media_path"] != null && json["media_path"].toString().isNotEmpty) {
            files = [json["media_path"].toString()];
            types = [json["media_type"]?.toString() ?? 'image'];
        }
        return Datum(
            id: json["id"],
            medicineName: json["medicine_name"],
            subtitle: json["subtitle"],
            curesFor: json["cures_for"],
            mediaType: json["media_type"],
            mediaPath: json["media_path"],
            mediaFiles: files,
            mediaTypes: types,
            createdAt: json["created_at"],
            title: json['title'],
        );
    }

    Map<String, dynamic> toJson() => {
        "id": id,
        "medicine_name": medicineName,
        "cures_for": curesFor,
        "media_type": mediaType,
        "media_path": mediaPath,
        "media_files": mediaFiles,
        "media_types": mediaTypes,
        "created_at": createdAt,
        "title": title,
    };
}
