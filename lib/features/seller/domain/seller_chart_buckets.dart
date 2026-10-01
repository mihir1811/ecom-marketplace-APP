import 'models/seller_stats.dart';

/// One chart bar covering the local calendar days [start]..[end] (inclusive).
class SellerChartBucket {
  const SellerChartBucket({
    required this.start,
    required this.end,
    required this.label,
    required this.detail,
    required this.serverLabel,
  });

  final DateTime start;
  final DateTime end;

  /// Short x-axis label (may contain one line break).
  final String label;

  /// Full period name for tooltips.
  final String detail;

  /// Label `GET /seller/stats` gives the same bucket (en-US formatting).
  final String serverLabel;

  bool contains(DateTime day) {
    final d = SellerChartBuckets.day(day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

/// Calendar buckets for seller charts, built on the client so every chart
/// knows exactly which days each bar covers.
///
/// Week, month and year boundaries match the server's bucketing in
/// `SellerDashboardService` (weeks start on Monday), so server values can be
/// placed on these buckets one-to-one. All arithmetic uses calendar fields,
/// never fixed 24 h durations, so DST changes cannot shift a day.
abstract final class SellerChartBuckets {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Monday of the week containing [d].
  static DateTime weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

  /// Start month (1, 4, 7, 10) of the quarter containing [month].
  static int quarterStartMonth(int month) => ((month - 1) ~/ 3) * 3 + 1;

  /// The buckets the server returns for [query], clipped to its range.
  static List<SellerChartBucket> forQuery(SellerStatsQuery query) {
    var from = day(query.from);
    var to = day(query.to);
    if (to.isBefore(from)) (from, to) = (to, from);
    return switch (query.period) {
      SellerStatsPeriod.daily => _daily(from, to),
      SellerStatsPeriod.weekly => _weekly(from, to),
      SellerStatsPeriod.monthly => _monthly(from, to),
      SellerStatsPeriod.yearly => _yearly(from, to),
    };
  }

  /// Calendar quarters from [from]'s quarter through [to]'s quarter.
  static List<SellerChartBucket> quarters(DateTime from, DateTime to) {
    final first = day(from);
    final last = day(to);
    final buckets = <SellerChartBucket>[];
    var cursor = DateTime(first.year, quarterStartMonth(first.month), 1);
    while (!cursor.isAfter(last)) {
      final quarterEnd = DateTime(cursor.year, cursor.month + 3, 0);
      final q = (cursor.month - 1) ~/ 3 + 1;
      final start = cursor.isBefore(first) ? first : cursor;
      final end = quarterEnd.isAfter(last) ? last : quarterEnd;
      buckets.add(
        SellerChartBucket(
          start: start,
          end: end,
          label: 'Q$q\n${cursor.year}',
          detail:
              'Q$q ${cursor.year} '
              '(${_rangeText(start, end)})',
          serverLabel: 'Q$q ${cursor.year}',
        ),
      );
      cursor = DateTime(cursor.year, cursor.month + 3, 1);
    }
    return buckets;
  }

  /// Server [chart] values placed on [buckets].
  ///
  /// Values are matched by position when the server sent one value per
  /// bucket, otherwise by label — and then every server label must be one
  /// of [buckets]' (a monthly "Sep 26" must not pass as the day Sep 26).
  /// Returns `null` when neither works, which means the server used a
  /// different bucket size than requested.
  static List<double>? align(
    SellerStatsChart chart,
    List<SellerChartBucket> buckets,
  ) {
    if (chart.values.isEmpty) return List<double>.filled(buckets.length, 0);
    if (chart.values.length == buckets.length) return List.of(chart.values);

    final index = {
      for (var i = 0; i < buckets.length; i++) buckets[i].serverLabel: i,
    };
    final aligned = List<double>.filled(buckets.length, 0);
    for (var i = 0; i < chart.values.length; i++) {
      final label = i < chart.labels.length ? chart.labels[i].trim() : '';
      final at = index[label];
      if (at == null) return null;
      aligned[at] += chart.values[i];
    }
    return aligned;
  }

  /// Sums [values] (one per [source] bucket) into the [target] bucket that
  /// contains each source bucket's first day.
  static List<double> regroup(
    List<double> values,
    List<SellerChartBucket> source,
    List<SellerChartBucket> target,
  ) {
    final out = List<double>.filled(target.length, 0);
    for (var i = 0; i < source.length && i < values.length; i++) {
      for (var t = 0; t < target.length; t++) {
        if (target[t].contains(source[i].start)) {
          out[t] += values[i];
          break;
        }
      }
    }
    return out;
  }

  static List<SellerChartBucket> _daily(DateTime from, DateTime to) {
    final buckets = <SellerChartBucket>[];
    for (
      var d = from;
      !d.isAfter(to);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      final short = '${_months[d.month - 1]} ${d.day}';
      buckets.add(
        SellerChartBucket(
          start: d,
          end: d,
          label: short,
          detail: '$short, ${d.year}',
          serverLabel: short,
        ),
      );
    }
    return buckets;
  }

  static List<SellerChartBucket> _weekly(DateTime from, DateTime to) {
    final buckets = <SellerChartBucket>[];
    for (
      var monday = weekStart(from);
      !monday.isAfter(to);
      monday = DateTime(monday.year, monday.month, monday.day + 7)
    ) {
      final sunday = DateTime(monday.year, monday.month, monday.day + 6);
      final start = monday.isBefore(from) ? from : monday;
      final end = sunday.isAfter(to) ? to : sunday;
      buckets.add(
        SellerChartBucket(
          start: start,
          end: end,
          label: '${_md(start)}\n–${_md(end)}',
          detail: 'Week of ${_rangeText(start, end)}',
          serverLabel: 'Wk ${_md(monday)}',
        ),
      );
    }
    return buckets;
  }

  static List<SellerChartBucket> _monthly(DateTime from, DateTime to) {
    final buckets = <SellerChartBucket>[];
    for (
      var month = DateTime(from.year, from.month, 1);
      !month.isAfter(to);
      month = DateTime(month.year, month.month + 1, 1)
    ) {
      final monthEnd = DateTime(month.year, month.month + 1, 0);
      final start = month.isBefore(from) ? from : month;
      final end = monthEnd.isAfter(to) ? to : monthEnd;
      final name = _months[month.month - 1];
      final yy = (month.year % 100).toString().padLeft(2, '0');
      buckets.add(
        SellerChartBucket(
          start: start,
          end: end,
          label: '$name\n${month.year}',
          detail: start == month && end == monthEnd
              ? '$name ${month.year}'
              : '$name ${month.year} (${_rangeText(start, end)})',
          serverLabel: '$name $yy',
        ),
      );
    }
    return buckets;
  }

  static List<SellerChartBucket> _yearly(DateTime from, DateTime to) {
    return [
      for (var year = from.year; year <= to.year; year++)
        () {
          final yearStart = DateTime(year, 1, 1);
          final yearEnd = DateTime(year, 12, 31);
          final start = yearStart.isBefore(from) ? from : yearStart;
          final end = yearEnd.isAfter(to) ? to : yearEnd;
          return SellerChartBucket(
            start: start,
            end: end,
            label: '$year',
            detail: start == yearStart && end == yearEnd
                ? '$year'
                : '$year (${_rangeText(start, end)})',
            serverLabel: '$year',
          );
        }(),
    ];
  }

  static String _md(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  static String _rangeText(DateTime start, DateTime end) {
    if (start == end) return '${_md(start)}, ${start.year}';
    if (start.year == end.year) {
      return '${_md(start)} – ${_md(end)}, ${end.year}';
    }
    return '${_md(start)}, ${start.year} – ${_md(end)}, ${end.year}';
  }
}
