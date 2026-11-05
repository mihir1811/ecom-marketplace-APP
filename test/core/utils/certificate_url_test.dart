import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/utils/certificate_url.dart';

void main() {
  const file =
      'https://dv0r6bse5npgr.cloudfront.net/vision360/certificate/260000020072.pdf';

  test('builds GIA report check url from certificate number', () {
    expect(
      CertificateUrl.resolve(certificateNumber: '5241044524'),
      'https://www.gia.edu/report-check?reportno=5241044524',
    );
  });

  test('recovers number from pdf name when feed sends exponent form', () {
    expect(
      CertificateUrl.resolve(
        certificateNumber: '2.6e+11',
        certificateFileUrl: file,
      ),
      'https://www.gia.edu/report-check?reportno=260000020072',
    );
  });

  test('keeps fallback for non-GIA labs or missing number', () {
    expect(
      CertificateUrl.resolve(
        lab: 'IGI',
        certificateNumber: '123456789',
        fallbackUrl: file,
      ),
      file,
    );
    expect(
      CertificateUrl.resolve(fallbackUrl: 'https://x.com/a'),
      'https://x.com/a',
    );
  });

  test('isPdf', () {
    expect(CertificateUrl.isPdf(file), isTrue);
    expect(
      CertificateUrl.isPdf('https://www.gia.edu/report-check?reportno=1'),
      isFalse,
    );
  });
}
