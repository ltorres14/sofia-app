class Product {
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  final int id;
  final String name;
  final double price;
  final String category;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        category: json['category'] as String,
      );
}
