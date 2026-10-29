/// Time window an account question is about. The model only picks a name;
/// dates are always computed here from the device clock, never by the model.
enum AgentPeriod {
  today('today'),
  yesterday('yesterday'),
  thisWeek('this week'),
  last7Days('the last 7 days'),
  thisMonth('this month'),
  lastMonth('last month'),
  last30Days('the last 30 days'),
  last90Days('the last 90 days'),
  thisYear('this year'),
  allTime('all time'),
  custom('the selected dates');

  const AgentPeriod(this.label);

  final String label;

  /// Model-facing names, in [values] order.
  static const names = [
    'today',
    'yesterday',
    'this_week',
    'last_7_days',
    'this_month',
    'last_month',
    'last_30_days',
    'last_90_days',
    'this_year',
    'all_time',
    'custom',
  ];

  String get apiName => names[index];

  static AgentPeriod? parse(Object? raw) {
    final key = raw?.toString().trim().toLowerCase().replaceAll(' ', '_');
    final i = names.indexOf(key ?? '');
    return i < 0 ? null : values[i];
  }

  /// JSON schema for a `period` slot plus optional custom dates.
  static Map<String, Object?> schema({String? hint}) => {
    'period': {
      'type': 'string',
      'enum': names,
      'description':
          hint ??
          'Window the user named. "custom" needs from_date/to_date. Leave '
              'out when no time was mentioned.',
    },
    'from_date': {
      'type': 'string',
      'description': 'YYYY-MM-DD, only with period "custom".',
    },
    'to_date': {
      'type': 'string',
      'description': 'YYYY-MM-DD, only with period "custom".',
    },
  };

  /// Inclusive calendar-day window ending today (or the period end).
  /// Null for [allTime] or an incomplete [custom].
  DateRangeDays? range(DateTime now, {DateTime? from, DateTime? to}) {
    final day = DateTime(now.year, now.month, now.day);
    final y = day.year, m = day.month, d = day.day;
    DateRangeDays span(DateTime a, DateTime b) => DateRangeDays(a, b);
    return switch (this) {
      today => span(day, day),
      yesterday => span(DateTime(y, m, d - 1), DateTime(y, m, d - 1)),
      thisWeek => span(DateTime(y, m, d - (day.weekday - 1)), day),
      last7Days => span(DateTime(y, m, d - 6), day),
      thisMonth => span(DateTime(y, m, 1), day),
      lastMonth => span(DateTime(y, m - 1, 1), DateTime(y, m, 0)),
      last30Days => span(DateTime(y, m, d - 29), day),
      last90Days => span(DateTime(y, m, d - 89), day),
      thisYear => span(DateTime(y, 1, 1), day),
      allTime => null,
      custom =>
        from == null || to == null
            ? null
            : (from.isAfter(to) ? span(to, from) : span(from, to)),
    };
  }

  /// Reads `period`, `from_date`, `to_date`; [fallback] when unset.
  static (AgentPeriod, DateRangeDays?) read(
    Map<String, Object?> args,
    DateTime now, {
    AgentPeriod fallback = allTime,
  }) {
    var period = parse(args['period']) ?? fallback;
    final from = _date(args['from_date']);
    final to = _date(args['to_date']);
    if (period == custom && (from == null || to == null)) period = fallback;
    // Never look past today.
    final today = DateTime(now.year, now.month, now.day);
    DateTime clamp(DateTime d) => d.isAfter(today) ? today : d;
    return (
      period,
      period.range(
        now,
        from: from == null ? null : clamp(from),
        to: to == null ? null : clamp(to),
      ),
    );
  }

  static DateTime? _date(Object? raw) {
    final parsed = DateTime.tryParse(raw?.toString().trim() ?? '');
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }
}

/// Inclusive local calendar days.
class DateRangeDays {
  const DateRangeDays(this.from, this.to);

  final DateTime from;
  final DateTime to;

  int get days => to.difference(from).inDays + 1;

  bool contains(DateTime? at) {
    if (at == null) return false;
    final local = at.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  /// The equally long window right before this one.
  DateRangeDays get previous => DateRangeDays(
    DateTime(from.year, from.month, from.day - days),
    DateTime(from.year, from.month, from.day - 1),
  );

  String get isoFrom => isoDay(from);
  String get isoTo => isoDay(to);

  static String isoDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
