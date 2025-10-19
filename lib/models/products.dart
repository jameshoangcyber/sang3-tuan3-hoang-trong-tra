import 'category.dart';

class ProductPost {
  ProductPost({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    this.categoryId,
    this.category,
  });

  final int? id;
  final String? name;
  final double? price;
  final String? image;
  final String? description;
  final int? categoryId;
  final Category? category;

  factory ProductPost.fromJson(Map<String, dynamic> json) {
    return ProductPost(
      id: json["id"],
      name: json["name"],
      price: json["price"]?.toDouble(),
      image: json["image"],
      description: json["description"],
      categoryId: json["categoryId"],
      category: json["category"] != null
          ? Category.fromJson(json["category"])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "name": name,
      "price": price,
      "image": image,
      "description": description,
      "categoryId": categoryId,
    };

    // Only include id if it's not null (for updates)
    if (id != null) {
      data["id"] = id;
    }

    return data;
  }

  // Copy with method for updates
  ProductPost copyWith({
    int? id,
    String? name,
    double? price,
    String? image,
    String? description,
    int? categoryId,
    Category? category,
  }) {
    return ProductPost(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
    );
  }
}
