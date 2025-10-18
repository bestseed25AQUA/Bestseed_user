class CategoryModel {
  final bool status;
  final List<Category> categories;

  CategoryModel({required this.status, required this.categories});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      status: json['status'] ?? false,
      categories: json['categories'] != null
          ? List<Category>.from(
              json['categories'].map((x) => Category.fromJson(x)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'categories': categories.map((x) => x.toJson()).toList(),
    };
  }
}

class Category {
  final int id;
  final String categoryName;

  Category({required this.id, required this.categoryName});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      categoryName: json['category_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'category_name': categoryName};
  }
}
