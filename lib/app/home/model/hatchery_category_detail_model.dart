// To parse this JSON data, do
//
//     final hatcherCategoryDetailModel = hatcherCategoryDetailModelFromJson(jsonString);

import 'dart:convert';

HatcherCategoryDetailModel hatcherCategoryDetailModelFromJson(String str) => HatcherCategoryDetailModel.fromJson(json.decode(str));

String hatcherCategoryDetailModelToJson(HatcherCategoryDetailModel data) => json.encode(data.toJson());

class HatcherCategoryDetailModel {
    bool? status;
    String? message;
    Data? data;

    HatcherCategoryDetailModel({
        this.status,
        this.message,
        this.data,
    });

    factory HatcherCategoryDetailModel.fromJson(Map<String, dynamic> json) => HatcherCategoryDetailModel(
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
    String? hatcheryName;
    List<String>? images;
    String? status;
    DateTime? availableOn;
    int? isSpot;
    Category? category;
    Location? location;
    List<Unit>? units;
    List<Broodstock>? broodstock;
    List<Price>? prices;
    String? callUrl;
    String? whatsappUrl;

    Data({
        this.id,
        this.hatcheryName,
        this.images,
        this.status,
        this.availableOn,
        this.isSpot,
        this.category,
        this.location,
        this.units,
        this.broodstock,
        this.prices,
        this.callUrl,
        this.whatsappUrl,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        hatcheryName: json["hatchery_name"],
        images: json["images"] == null ? [] : List<String>.from(json["images"]!.map((x) => x)),
        status: json["status"],
        availableOn: json["available_on"] == null ? null : DateTime.parse(json["available_on"]),
        isSpot: json["is_spot"],
        category: json["category"] == null ? null : Category.fromJson(json["category"]),
        location: json["location"] == null ? null : Location.fromJson(json["location"]),
        units: json["units"] == null ? [] : List<Unit>.from(json["units"]!.map((x) => Unit.fromJson(x))),
        broodstock: json["broodstock"] == null ? [] : List<Broodstock>.from(json["broodstock"]!.map((x) => Broodstock.fromJson(x))),
        prices: json["prices"] == null ? [] : List<Price>.from(json["prices"]!.map((x) => Price.fromJson(x))),
        callUrl: json["call_url"],
        whatsappUrl: json["whatsapp_url"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "hatchery_name": hatcheryName,
        "images": images == null ? [] : List<dynamic>.from(images!.map((x) => x)),
        "status": status,
        "available_on": "${availableOn!.year.toString().padLeft(4, '0')}-${availableOn!.month.toString().padLeft(2, '0')}-${availableOn!.day.toString().padLeft(2, '0')}",
        "is_spot": isSpot,
        "category": category?.toJson(),
        "location": location?.toJson(),
        "units": units == null ? [] : List<dynamic>.from(units!.map((x) => x.toJson())),
        "broodstock": broodstock == null ? [] : List<dynamic>.from(broodstock!.map((x) => x.toJson())),
        "prices": prices == null ? [] : List<dynamic>.from(prices!.map((x) => x.toJson())),
        "call_url": callUrl,
        "whatsapp_url": whatsappUrl,
    };
}

class Broodstock {
    int? count;

    Broodstock({
        this.count,
    });

    factory Broodstock.fromJson(Map<String, dynamic> json) => Broodstock(
        count: json["count"],
    );

    Map<String, dynamic> toJson() => {
        "count": count,
    };
}

class Category {
    int? id;
    String? name;
    String? description;
    List<String>? gallery;
    String? report;

    Category({
        this.id,
        this.name,
        this.description,
        this.gallery,
        this.report,
    });

    factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        gallery: json["gallery"] == null ? [] : List<String>.from(json["gallery"]!.map((x) => x)),
        report: json["report"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "gallery": gallery == null ? [] : List<dynamic>.from(gallery!.map((x) => x)),
        "report": report,
    };
}

class Location {
    int? id;
    String? name;

    Location({
        this.id,
        this.name,
    });

    factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json["id"],
        name: json["name"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
    };
}

class Price {
    String? price;

    Price({
        this.price,
    });

    factory Price.fromJson(Map<String, dynamic> json) => Price(
        price: json["price"],
    );

    Map<String, dynamic> toJson() => {
        "price": price,
    };
}

class Unit {
    int? id;
    String? branchName;

    Unit({
        this.id,
        this.branchName,
    });

    factory Unit.fromJson(Map<String, dynamic> json) => Unit(
        id: json["id"],
        branchName: json["branch_name"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "branch_name": branchName,
    };
}
