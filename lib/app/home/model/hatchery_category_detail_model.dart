import 'dart:convert';

HatcherCategoryDetailModel hatcherCategoryDetailModelFromJson(String str) {
  try {
    return HatcherCategoryDetailModel.fromJson(json.decode(str));
  } catch (e) {
    throw FormatException('Failed to parse JSON: $e');
  }
}

String hatcherCategoryDetailModelToJson(HatcherCategoryDetailModel data) =>
    json.encode(data.toJson());

class HatcherCategoryDetailModel {
  bool? status;
  String? message;
  Data? data;

  HatcherCategoryDetailModel({this.status, this.message, this.data});

  factory HatcherCategoryDetailModel.fromJson(Map<String, dynamic> json) {
    try {
      return HatcherCategoryDetailModel(
        status: json["status"] as bool?,
        message: json["message"] as String?,
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );
    } catch (e) {
      throw FormatException('Error parsing HatcherCategoryDetailModel: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  int? id;
  String? hatcheryName;
  String? description;
  List<String>? images;
  int? status;
  DateTime? availableOn;
  int? isSpot;
  Category? category;
  Location? location;
  List<Unit>? units;
  int? broodstock;
  String? price;
  String? callUrl;
  String? whatsappUrl;

  Data({
    this.id,
    this.hatcheryName,
    this.description,
    this.images,
    this.status,
    this.availableOn,
    this.isSpot,
    this.category,
    this.location,
    this.units,
    this.broodstock,
    this.price,
    this.callUrl,
    this.whatsappUrl,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    try {
      return Data(
        id: json["id"] as int?,
        hatcheryName: json["hatchery_name"] as String?,
        description: json["description"] as String?,
        images: json["images"] == null
            ? []
            : List<String>.from(json["images"] ?? []),
        status: json["status"] as int?,
        availableOn: json["available_on"] == null
            ? null
            : DateTime.tryParse(json["available_on"]),
        isSpot: json["is_spot"] as int?,
        category: json["category"] == null
            ? null
            : Category.fromJson(json["category"]),
        location: json["location"] == null
            ? null
            : Location.fromJson(json["location"]),
        units: json["units"] == null
            ? []
            : List<Unit>.from(
                json["units"]!.map((x) => Unit.fromJson(x)) ?? [],
              ),
        broodstock: json["broodstock"] as int?,
        price: json["price"] as String?,
        callUrl: json["call_url"] as String?,
        whatsappUrl: json["whatsapp_url"] as String?,
      );
    } catch (e) {
      throw FormatException('Error parsing Data: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "hatchery_name": hatcheryName,
    "description": description,
    "images": images ?? [],
    "status": status,
    "available_on": availableOn?.toIso8601String().split('T')[0],
    "is_spot": isSpot,
    "category": category?.toJson(),
    "location": location?.toJson(),
    "units": units?.map((x) => x.toJson()).toList() ?? [],
    "broodstock": broodstock,
    "price": price,
    "call_url": callUrl,
    "whatsapp_url": whatsappUrl,
  };
}

class Category {
  int? id;
  String? name;
  String? description;
  List<String>? gallery;
  String? report;

  Category({this.id, this.name, this.description, this.gallery, this.report});

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: json["id"] as int?,
        name: json["name"] as String?,
        description: json["description"] as String?,
        gallery: json["gallery"] == null
            ? []
            : List<String>.from(json["gallery"] ?? []),
        report: json["report"] as String?,
      );
    } catch (e) {
      throw FormatException('Error parsing Category: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "gallery": gallery ?? [],
    "report": report,
  };
}

class Location {
  int? id;
  String? name;

  Location({this.id, this.name});

  factory Location.fromJson(Map<String, dynamic> json) {
    try {
      return Location(id: json["id"] as int?, name: json["name"] as String?);
    } catch (e) {
      throw FormatException('Error parsing Location: $e');
    }
  }

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

class Unit {
  int? id;
  Branch? branch;

  Unit({this.id, this.branch});

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json["id"] as int?,
      branch: json["branch"] == null ? null : Branch.fromJson(json["branch"]),
    );
  }

  Map<String, dynamic> toJson() => {"id": id, "branch": branch?.toJson()};
}

class Branch {
  int? id;
  String? name;
  String? address;

  Branch({this.id, this.name, this.address});

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json["id"] as int?,
      name: json["name"] as String?,
      address: json["address"] as String?,
    );
  }

  Map<String, dynamic> toJson() => {"id": id, "name": name, "address": address};
}
