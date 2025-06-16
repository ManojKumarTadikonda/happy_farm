class CartItem {
  final String id;
  final String priceId;
  final String userId;
  final int quantity;
  final double subTotal;
  final Product product;

  CartItem({
    required this.id,
    required this.priceId,
    required this.userId,
    required this.quantity,
    required this.subTotal,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'],
      priceId: json['priceId'],
      userId: json['userId'],
      quantity: json['quantity'],
      subTotal: (json['subTotal'] as num).toDouble(),
      product: Product.fromJson(json['productId']),
    );
  }
}


class Product {
  final String id;
  final String name;
  final String description;
  final List<String> images;
  final List<Price> prices;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.prices,
    required this.rating,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      images: List<String>.from(json['images'] ?? []),
      prices: (json['prices'] as List<dynamic>)
          .map((p) => Price.fromJson(p))
          .toList(),
      rating: (json['rating'] as num).toDouble(),
    );
  }
}

class Price {
  final String id;
  final int quantity;
  final double actualPrice;
  final double oldPrice;
  final double discount;
  final String type;
  final int countInStock;

  Price({
    required this.id,
    required this.quantity,
    required this.actualPrice,
    required this.oldPrice,
    required this.discount,
    required this.type,
    required this.countInStock,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      id: json['_id'],
      quantity: json['quantity'],
      actualPrice: (json['actualPrice'] as num).toDouble(),
      oldPrice: (json['oldPrice'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      type: json['type'],
      countInStock: json['countInStock'],
    );
  }
}
