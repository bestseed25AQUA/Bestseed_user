// To parse this JSON data, do
//
//     final hatcherUpdateModel = hatcherUpdateModelFromJson(jsonString);

import 'dart:convert';

HatcherUpdateModel hatcherUpdateModelFromJson(String str) => HatcherUpdateModel.fromJson(json.decode(str));

String hatcherUpdateModelToJson(HatcherUpdateModel data) => json.encode(data.toJson());

class HatcherUpdateModel {
    bool? status;
    String? message;
    List<HatcheryData>? data;

    HatcherUpdateModel({
        this.status,
        this.message,
        this.data,
    });

    factory HatcherUpdateModel.fromJson(Map<String, dynamic> json) => HatcherUpdateModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? [] : List<HatcheryData>.from(json["data"]!.map((x) => HatcheryData.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    };
}

class HatcheryData {
    int? id;
    String? hatcheryName;
    dynamic profileImage;
    String? caption;
    List<Hashtag>? hashtags;
    List<String>? mediaFiles;
    String? mediaType;
    String? postedOn;
    dynamic callUrl;
    dynamic whatsappUrl;
    dynamic facebookUrl;
    String? shareLink;

    HatcheryData({
        this.id,
        this.hatcheryName,
        this.profileImage,
        this.caption,
        this.hashtags,
        this.mediaFiles,
        this.mediaType,
        this.postedOn,
        this.callUrl,
        this.whatsappUrl,
        this.facebookUrl,
        this.shareLink,
    });

    factory HatcheryData.fromJson(Map<String, dynamic> json) => HatcheryData(
        id: json["id"],
        hatcheryName: json["hatchery_name"],
        profileImage: json["profile_image"],
        caption: json["caption"],
        hashtags: json["hashtags"] == null ? [] : List<Hashtag>.from(json["hashtags"]!.map((x) => hashtagValues.map[x]!)),
        mediaFiles: json["media_files"] == null ? [] : List<String>.from(json["media_files"]!.map((x) => x)),
        mediaType: json["media_type"],
        postedOn: json["posted_on"],
        callUrl: json["call_url"],
        whatsappUrl: json["whatsapp_url"],
        facebookUrl: json["facebook_url"],
        shareLink: json["share_link"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "hatchery_name": hatcheryName,
        "profile_image": profileImage,
        "caption": caption,
        "hashtags": hashtags == null ? [] : List<dynamic>.from(hashtags!.map((x) => hashtagValues.reverse[x])),
        "media_files": mediaFiles == null ? [] : List<dynamic>.from(mediaFiles!.map((x) => x)),
        "media_type": mediaType,
        "posted_on": postedOn,
        "call_url": callUrl,
        "whatsapp_url": whatsappUrl,
        "facebook_url": facebookUrl,
        "share_link": shareLink,
    };
}

enum Hashtag {
    AQUACULTURE,
    SHRIMP
}

final hashtagValues = EnumValues({
    "aquaculture": Hashtag.AQUACULTURE,
    "shrimp": Hashtag.SHRIMP
});

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
