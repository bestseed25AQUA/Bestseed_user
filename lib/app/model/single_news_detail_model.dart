// To parse this JSON data, do
//
//     final singleNewsDetailModel = singleNewsDetailModelFromJson(jsonString);

import 'dart:convert';

SingleNewsDetailModel singleNewsDetailModelFromJson(String str) => SingleNewsDetailModel.fromJson(json.decode(str));

String singleNewsDetailModelToJson(SingleNewsDetailModel data) => json.encode(data.toJson());

class SingleNewsDetailModel {
    bool? status;
    String? message;
    Data? data;

    SingleNewsDetailModel({
        this.status,
        this.message,
        this.data,
    });

    factory SingleNewsDetailModel.fromJson(Map<String, dynamic> json) => SingleNewsDetailModel(
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
    int? id;
    String? title;
    String? subtitle;
    String? caption;
    String? description;
    String? mediaType;
    String? mediaPath;
    List<String>? mediaFiles;
    List<String>? mediaTypes;
    String? medicineName;
    String? whatsappNumber;
    String? callNumber;

    Data({
        this.id,
        this.title,
        this.subtitle,
        this.caption,
        this.description,
        this.mediaType,
        this.mediaPath,
        this.mediaFiles,
        this.mediaTypes,
        this.medicineName,
        this.whatsappNumber,
        this.callNumber,
    });

    factory Data.fromJson(Map<String, dynamic> json) {
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
        return Data(
            id: json["id"],
            title: json["title"],
            subtitle: json["subtitle"],
            caption: json["caption"],
            description: json["description"],
            mediaType: json["media_type"],
            mediaPath: json["media_path"],
            mediaFiles: files,
            mediaTypes: types,
            medicineName: json["medicine_name"],
            whatsappNumber: json["whatsapp_number"],
            callNumber: json["call_number"],
        );
    }

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "subtitle": subtitle,
        "caption": caption,
        "description": description,
        "media_type": mediaType,
        "media_path": mediaPath,
        "media_files": mediaFiles,
        "media_types": mediaTypes,
        "medicine_name": medicineName,
        "whatsapp_number": whatsappNumber,
        "call_number": callNumber,
    };
}
