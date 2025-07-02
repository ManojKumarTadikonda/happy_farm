// Base abstract product class
abstract class BaseProduct {
  final String id;
  final String name;
  final String description;
  final List<String> images;
  final List<PriceModel> prices;
  final String catName;
  final String? subCatName;
  final int rating;
  final bool isFeatured;
  final bool isAddedToCart;
  final bool isAddedToWishlist;

  BaseProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.prices,
    required this.catName,
    this.subCatName,
    required this.rating,
    required this.isFeatured,
    required this.isAddedToCart,
    required this.isAddedToWishlist,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'images': images,
        'prices': prices.map((e) => e.toJson()).toList(),
        'catName': catName,
        'subCatName': subCatName,
        'rating': rating,
        'isFeatured': isFeatured,
      };
}

// Price Model
class PriceModel {
  final int quantity;
  final double actualPrice;
  final double oldPrice;
  final double discount;
  final String type;
  final int countInStock;
  final String id;

  PriceModel({
    required this.quantity,
    required this.actualPrice,
    required this.oldPrice,
    required this.discount,
    required this.type,
    required this.countInStock,
    required this.id,
  });

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      quantity: json['quantity'] ?? 0,
      actualPrice: (json['actualPrice'] ?? 0).toDouble(),
      oldPrice: (json['oldPrice'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      countInStock: json['countInStock'] ?? 0,
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'quantity': quantity,
        'actualPrice': actualPrice,
        'oldPrice': oldPrice,
        'discount': discount,
        'type': type,
        'countInStock': countInStock,
        '_id': id,
      };
}

// Featured Product
class FeaturedProduct extends BaseProduct {
  final String category;
  final String subCategory;
  final DateTime dateCreated;

  FeaturedProduct({
    required String id,
    required String name,
    required String description,
    required List<String> images,
    required List<PriceModel> prices,
    required this.category,
    required this.subCategory,
    required int rating,
    required bool isFeatured,
    required this.dateCreated,
    required isAddedToWishlist,
    required isAddedToCart,
  }) : super(
            id: id,
            name: name,
            description: description,
            images: images,
            prices: prices,
            catName: category,
            subCatName: subCategory,
            rating: rating,
            isFeatured: isFeatured,
            isAddedToCart: isAddedToCart,
            isAddedToWishlist: isAddedToWishlist);

  factory FeaturedProduct.fromJson(Map<String, dynamic> json) {
    return FeaturedProduct(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      prices:
          (json['prices'] as List).map((e) => PriceModel.fromJson(e)).toList(),
      category: json['catName'] ?? '',
      subCategory: json['subCatName'] ?? '',
      rating: json['rating'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      isAddedToWishlist: json['isAddedToWishlist'] ?? false,
      isAddedToCart: json['isAddedToCart'] ?? false,
      dateCreated:
          DateTime.tryParse(json['dateCreated'] ?? '') ?? DateTime.now(),
    );
  }
}

// All Products
class AllProduct extends BaseProduct {
  final String catId;
  final String? subCatId;
  final String? subCat;

  AllProduct({
    required String id,
    required String name,
    required String description,
    required List<String> images,
    required List<PriceModel> prices,
    required String catName,
    required this.catId,
    String? subCatName,
    this.subCatId,
    this.subCat,
    required int rating,
    required bool isFeatured,
    required isAddedToWishlist,
    required isAddedToCart,
  }) : super(
          id: id,
          name: name,
          description: description,
          images: images,
          prices: prices,
          catName: catName,
          subCatName: subCatName,
          rating: rating,
          isFeatured: isFeatured,
          isAddedToCart: isAddedToCart,
          isAddedToWishlist: isAddedToWishlist
        );

  factory AllProduct.fromJson(Map<String, dynamic> json) {
    String? subCatName = (json['subCatName']?.toString().trim().isEmpty ?? true)
        ? null
        : json['subCatName'];

    return AllProduct(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      prices:
          (json['prices'] as List).map((e) => PriceModel.fromJson(e)).toList(),
      catName: (json['catName'] ?? '').trim(),
      catId: json['catId'] ?? '',
      subCatName: subCatName,
      subCatId: json['subCatId'],
      subCat: json['subCat'],
      rating: json['rating'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      isAddedToWishlist: json['isAddedToWishlist'] ?? false,
      isAddedToCart: json['isAddedToCart'] ?? false,
    );
  }
}

// Filtered Product
class FilterProducts extends BaseProduct {
  final DateTime? dateCreated;

  FilterProducts({
    required String id,
    required String name,
    required String description,
    required List<String> images,
    required List<PriceModel> prices,
    required String catName,
    String? subCatName,
    required int rating,
    required bool isFeatured,
    this.dateCreated, required isAddedToWishlist, required isAddedToCart,
  }) : super(
          id: id,
          name: name,
          description: description,
          images: images,
          prices: prices,
          catName: catName,
          subCatName: subCatName,
          rating: rating,
          isFeatured: isFeatured,
          isAddedToCart: isAddedToCart,
          isAddedToWishlist: isAddedToWishlist
        );

  factory FilterProducts.fromJson(Map<String, dynamic> json) {
    String? subCatName = (json['subCatName']?.toString().trim().isEmpty ?? true)
        ? null
        : json['subCatName'];

    return FilterProducts(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      prices:
          (json['prices'] as List).map((e) => PriceModel.fromJson(e)).toList(),
      catName: json['catName'] ?? '',
      subCatName: subCatName,
      rating: json['rating'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      isAddedToWishlist: json['isAddedToWishlist'] ?? false,
      isAddedToCart: json['isAddedToCart'] ?? false,
      dateCreated: json['dateCreated'] != null
          ? DateTime.tryParse(json['dateCreated'])
          : null,
    );
  }
}

// Category Model
class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final String color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: (json['images'] as List).isNotEmpty ? json['images'][0] : '',
      color: json['color'] ?? '#ffffff',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'images': [imageUrl],
        'color': color,
      };
}
