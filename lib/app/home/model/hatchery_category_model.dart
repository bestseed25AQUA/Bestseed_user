// To parse this JSON data, do
//
//     final hatcherCategoryModel = hatcherCategoryModelFromJson(jsonString);

import 'dart:convert';

HatcherCategoryModel hatcherCategoryModelFromJson(String str) => HatcherCategoryModel.fromJson(json.decode(str));

String hatcherCategoryModelToJson(HatcherCategoryModel data) => json.encode(data.toJson());

class HatcherCategoryModel {
    bool? status;
    String? message;
    HatcheryCategoryData? data;

    HatcherCategoryModel({
        this.status,
        this.message,
        this.data,
    });

    factory HatcherCategoryModel.fromJson(Map<String, dynamic> json) => HatcherCategoryModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? null : HatcheryCategoryData.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data?.toJson(),
    };
}

class HatcheryCategoryData {
    int? id;
    String? hatcheryName;
    List<String>? images;
    String? status;
    DateTime? availableOn;
    int? isSpot;
    Category? category;
    Category? location;
    List<Unit>? units;
    List<Broodstock>? broodstock;
    List<Price>? prices;
    String? callUrl;
    String? whatsappUrl;
    List<SimilarHatchery>? similarHatcheries;

    HatcheryCategoryData({
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
        this.similarHatcheries,
    });

    factory HatcheryCategoryData.fromJson(Map<String, dynamic> json) => HatcheryCategoryData(
        id: json["id"],
        hatcheryName: json["hatchery_name"],
        images: json["images"] == null ? [] : List<String>.from(json["images"]!.map((x) => x)),
        status: json["status"],
        availableOn: json["available_on"] == null ? null : DateTime.parse(json["available_on"]),
        isSpot: json["is_spot"],
        category: json["category"] == null ? null : Category.fromJson(json["category"]),
        location: json["location"] == null ? null : Category.fromJson(json["location"]),
        units: json["units"] == null ? [] : List<Unit>.from(json["units"]!.map((x) => Unit.fromJson(x))),
        broodstock: json["broodstock"] == null ? [] : List<Broodstock>.from(json["broodstock"]!.map((x) => Broodstock.fromJson(x))),
        prices: json["prices"] == null ? [] : List<Price>.from(json["prices"]!.map((x) => Price.fromJson(x))),
        callUrl: json["call_url"],
        whatsappUrl: json["whatsapp_url"],
        similarHatcheries: json["similar_hatcheries"] == null ? [] : List<SimilarHatchery>.from(json["similar_hatcheries"]!.map((x) => SimilarHatchery.fromJson(x))),
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
        "similar_hatcheries": similarHatcheries == null ? [] : List<dynamic>.from(similarHatcheries!.map((x) => x.toJson())),
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

    Category({
        this.id,
        this.name,
    });

    factory Category.fromJson(Map<String, dynamic> json) => Category(
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

class SimilarHatchery {
    int? id;
    String? hatcheryName;
    int? categoryId;
    int? locationId;
    String? status;
    DateTime? availableOn;
    String? image;
    int? isSpot;

    SimilarHatchery({
        this.id,
        this.hatcheryName,
        this.categoryId,
        this.locationId,
        this.status,
        this.availableOn,
        this.image,
        this.isSpot,
    });

    factory SimilarHatchery.fromJson(Map<String, dynamic> json) => SimilarHatchery(
        id: json["id"],
        hatcheryName: json["hatchery_name"],
        categoryId: json["category_id"],
        locationId: json["location_id"],
        status: json["status"],
        availableOn: json["available_on"] == null ? null : DateTime.parse(json["available_on"]),
        image: json["image"],
        isSpot: json["is_spot"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "hatchery_name": hatcheryName,
        "category_id": categoryId,
        "location_id": locationId,
        "status": status,
        "available_on": "${availableOn!.year.toString().padLeft(4, '0')}-${availableOn!.month.toString().padLeft(2, '0')}-${availableOn!.day.toString().padLeft(2, '0')}",
        "image": image,
        "is_spot": isSpot,
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
