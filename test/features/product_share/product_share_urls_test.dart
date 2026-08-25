import 'package:flutter_test/flutter_test.dart';

import 'package:gemstone/core/network/api_config.dart';
import 'package:gemstone/features/product_share/domain/product_share_urls.dart';

void main() {
  test('rewriteApiShareUrl is an absolute http(s) URL', () {
    final url = ProductShareUrls.rewriteApiShareUrl(
      token: 'abc-token',
      apiShareUrl: 'http://localhost:8000/share/abc-token',
    );
    expect(url.startsWith('http://') || url.startsWith('https://'), isTrue);
    expect(url.contains('/#/share/abc-token'), isTrue);
    expect(url.contains('localhost:8000'), isFalse);
    expect(Uri.parse(url).origin, Uri.parse(ApiConfig.baseUrl).origin);
  });
}
