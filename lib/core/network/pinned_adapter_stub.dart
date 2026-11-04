import 'package:dio/dio.dart';

/// Web: the browser owns TLS, so there is nothing to pin here.
HttpClientAdapter? createPinnedAdapter() => null;
