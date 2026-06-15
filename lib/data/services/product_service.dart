import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/products/product.dart';

class ProductService {
  final _client = ApiClient.instance.dio;

  Future<List<Product>> getProducts() async {
    try {
      final response = await _client.get(ApiConstants.products);
      return (response.data as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }
}
