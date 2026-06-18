class Product {
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageName,
    this.sortOrder = 0,
    this.isAvailable = true,
  });

  final int id;
  final String name;
  final double price;
  final String category;
  final String? imageName;
  final int sortOrder;
  final bool isAvailable;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    category: json['category'] as String,
    imageName: (json['imageName'] as String?)?.trim().isEmpty ?? true
        ? null
        : (json['imageName'] as String).trim(),
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    isAvailable: json['isAvailable'] as bool? ?? true,
  );
}
