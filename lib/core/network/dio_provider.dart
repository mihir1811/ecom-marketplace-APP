import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_client.dart';

/// App-wide Dio client. Feature repositories depend on this provider.
final dioProvider = Provider<Dio>((ref) => DioClient.create());
