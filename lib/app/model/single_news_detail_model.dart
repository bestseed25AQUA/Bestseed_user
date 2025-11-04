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
    String? caption;
    String? description;
    String? mediaType;
    String? mediaPath;

    Data({
        this.id,
        this.title,
        this.caption,
        this.description,
        this.mediaType,
        this.mediaPath,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        title: json["title"],
        caption: json["caption"],
        description: json["description"],
        mediaType: json["media_type"],
        mediaPath: json["media_path"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "caption": caption,
        "description": description,
        "media_type": mediaType,
        "media_path": mediaPath,
    };
}
