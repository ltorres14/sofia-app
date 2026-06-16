import '../../../data/models/products/product.dart';

class ProductSelection {
  const ProductSelection({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;
}
