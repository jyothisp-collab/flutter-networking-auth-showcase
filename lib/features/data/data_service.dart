import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import 'data_model.dart';

class DataService {
  final ApiClient _apiClient;

  DataService(this._apiClient);

  Future<DataModel> getProtectedData() async {
    try {
      final response = await _apiClient.dio.get('/protected-data');
      return DataModel.fromJson(response.data);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  Future<DataModel> getPublicData() async {
    try {
      final response = await _apiClient.dio.get('/public-data');
      return DataModel.fromJson(response.data);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  Future<DataModel> createPublicData(String title) async {
    try {
      final response = await _apiClient.dio.post(
        '/public-data',
        data: {'title': title},
      );
      return DataModel.fromJson(response.data);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
}
