import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'certificate_pins.dart';

/// Dio adapter that sends requests for [CertificatePins.hosts] through an
/// HttpClient trusting only the pinned roots, and everything else (S3,
/// third-party APIs) through a normal HttpClient. Null when pinning is off.
HttpClientAdapter? createPinnedAdapter() {
  if (!CertificatePins.active) return null;
  final context = SecurityContext(withTrustedRoots: false);
  for (final pem in CertificatePins.roots) {
    context.setTrustedCertificatesBytes(utf8.encode(pem));
  }
  return _HostRoutingAdapter(
    pinned: IOHttpClientAdapter(
      createHttpClient: () => HttpClient(context: context)
        // Never accept a chain the pinned roots reject.
        ..badCertificateCallback = (_, _, _) => false,
    ),
    other: IOHttpClientAdapter(),
  );
}

class _HostRoutingAdapter implements HttpClientAdapter {
  _HostRoutingAdapter({required this.pinned, required this.other});

  final HttpClientAdapter pinned;
  final HttpClientAdapter other;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final adapter = CertificatePins.hosts.contains(options.uri.host)
        ? pinned
        : other;
    return adapter.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    pinned.close(force: force);
    other.close(force: force);
  }
}
