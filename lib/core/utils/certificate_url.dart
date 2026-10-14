/// Builds the viewable certificate link for a catalog stone.
///
/// The feed's hosted certificate PDFs are not publicly readable, so stones
/// with a GIA report number open GIA's own Report Check page instead.
abstract final class CertificateUrl {
  static const String giaReportCheckBase =
      'https://www.gia.edu/report-check?reportno=';

  static final RegExp _reportNo = RegExp(r'^\d{6,14}$');
  static final RegExp _fileReportNo = RegExp(
    r'/(\d{6,14})\.pdf(?:$|[?#])',
    caseSensitive: false,
  );

  /// GIA Report Check URL for [reportNumber], or null when it is not a
  /// plain report number.
  static String? gia(String? reportNumber) {
    final no = reportNumber?.trim();
    if (no == null || !_reportNo.hasMatch(no)) return null;
    return '$giaReportCheckBase$no';
  }

  /// Report number from [certificateNumber], falling back to the PDF file
  /// name in [certificateFileUrl] (the feed sometimes sends the number in
  /// lossy exponent form, e.g. `2.6e+11`).
  static String? reportNumber({
    String? certificateNumber,
    String? certificateFileUrl,
  }) {
    final no = certificateNumber?.trim();
    if (no != null && _reportNo.hasMatch(no)) return no;
    final file = certificateFileUrl?.trim();
    if (file == null || file.isEmpty) return null;
    return _fileReportNo.firstMatch(file)?.group(1);
  }

  /// GIA link when a report number is known and the lab is GIA or unknown;
  /// otherwise [fallbackUrl].
  static String? resolve({
    String? lab,
    String? certificateNumber,
    String? certificateFileUrl,
    String? fallbackUrl,
  }) {
    final l = lab?.trim().toUpperCase() ?? '';
    if (l.isEmpty || l.contains('GIA')) {
      final gia = CertificateUrl.gia(
        reportNumber(
          certificateNumber: certificateNumber,
          certificateFileUrl: certificateFileUrl,
        ),
      );
      if (gia != null) return gia;
    }
    return fallbackUrl;
  }

  /// True when [url] points at a PDF file.
  static bool isPdf(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    return path.endsWith('.pdf');
  }
}
