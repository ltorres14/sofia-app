import '../models/products/product.dart';
import '../services/product_service.dart';

class ProductRepository {
  ProductRepository({ProductService? service}) : _service = service ?? ProductService();

  final ProductService _service;

  Future<List<Product>> getProducts() => _service.getProducts();
}
