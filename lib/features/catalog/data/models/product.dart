class ProductVariant {
  final int id;
  final String sku;
  final String size;
  final String color;
  final int stock;

  ProductVariant({
    required this.id,
    required this.sku,
    required this.size,
    required this.color,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      sku: json['sku'] ?? 'N/A',
      size: json['size'] ?? 'U',
      color: json['color'] ?? 'N/A',
      stock: json['stock'] ?? 0,
    );
  }
}

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? categoryName;
  final String? brandName;
  final String? conditionName;
  final String? sellerName;
  final List<String> images;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.categoryName,
    this.brandName,
    this.conditionName,
    this.sellerName,
    this.images = const [],
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> imageUrls = [];
    if (json['images'] != null) {
      for (var img in json['images']) {
        if (img['url'] != null) imageUrls.add(img['url']);
      }
    }

    List<ProductVariant> parsedVariants = [];
    if (json['variants'] != null) {
      for (var v in json['variants']) {
        parsedVariants.add(ProductVariant.fromJson(v));
      }
    }
    
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: _parsePrice(json),
      categoryName: json['categoryName'],
      brandName: json['brandName'],
      conditionName: json['conditionName'],
      sellerName: json['sellerName'],
      images: imageUrls,
      variants: parsedVariants,
    );
  }

  static double _parsePrice(Map<String, dynamic> json) {
    if (json['price'] != null) {
      return double.tryParse(json['price'].toString()) ?? 0.0;
    }
    if (json['variants'] != null && json['variants'].isNotEmpty) {
      final firstVariant = json['variants'][0];
      if (firstVariant['price'] != null) {
        return double.tryParse(firstVariant['price'].toString()) ?? 0.0;
      }
    }
    return 0.0;
  }
}
