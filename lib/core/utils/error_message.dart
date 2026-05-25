import 'package:dio/dio.dart';

import '../errors/api_exception.dart';

String readableError(Object error) {
  if (error is ApiException) {
    return error.message;
  }

  if (error is DioException && error.error is ApiException) {
    return (error.error as ApiException).message;
  }

  return error.toString().replaceFirst('Exception: ', '');
}
