import 'package:dio/dio.dart';
import 'package:flutter_networking_auth_showcase/core/network/api_client.dart';
import 'package:flutter_networking_auth_showcase/core/network/api_exceptions.dart';
import 'package:flutter_networking_auth_showcase/features/data/data_model.dart';

class DataService {
  final ApiClient _apiClient;

  DataService(this._apiClient);

  Future<DataModel> getPublicData() async {
    try {
      final response = await _apiClient.dio.get('/public-data');
      return DataModel.fromResponse(response.data);
    } on DioException catch (e) {
      throw ExceptionHandler.handle(e);
    } catch (e) {
      throw UnknownException('Failed to fetch public data: ${e.toString()}');
    }
  }

  Future<DataModel> getProtectedData() async {
    try {
      final response = await _apiClient.dio.get('/protected-data');
      return DataModel.fromResponse(response.data);
    } on DioException catch (e) {
      throw ExceptionHandler.handle(e);
    } catch (e) {
      throw UnknownException('Failed to fetch protected data: ${e.toString()}');
    }
  }

  Future<DataModel> createData(DataModel model) async {
    try {
      final response = await _apiClient.dio.post(
        '/public-data',
        data: model.toJson(),
      );
      return DataModel.fromResponse(response.data);
    } on DioException catch (e) {
      throw ExceptionHandler.handle(e);
    } catch (e) {
      throw UnknownException('Failed to create data: ${e.toString()}');
    }
  }
}
