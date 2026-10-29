/// Rich, read-only answer content shown inside the agent sheet under the
/// agent's reply: KPI tiles, short lists and small charts. Cards never reach
/// the model; tools send it a compact data echo instead.
sealed class AgentCard {
  const AgentCard({this.title, this.action});

  final String? title;

  /// Optional button under the card, e.g. "Open cart".
  final AgentCardAction? action;
}

/// Tap target that closes the sheet and opens [route].
class AgentCardAction {
  const AgentCardAction(this.label, this.route);

  final String label;
  final String route;
}

/// One KPI tile.
class AgentStat {
  const AgentStat(this.label, this.value, {this.hint, this.trend});

  final String label;
  final String value;
  final String? hint;

  /// Period-over-period change in percent; sign drives the arrow.
  final double? trend;
}

class AgentStatsCard extends AgentCard {
  const AgentStatsCard({super.title, required this.stats, super.action});

  final List<AgentStat> stats;
}

class AgentListRow {
  const AgentListRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.imageUrl,
    this.route,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final String? imageUrl;

  /// Opens this row's screen when tapped.
  final String? route;
}

class AgentListCard extends AgentCard {
  const AgentListCard({
    super.title,
    required this.rows,
    this.moreCount = 0,
    super.action,
  });

  final List<AgentListRow> rows;

  /// Items not listed ("+4 more").
  final int moreCount;
}

enum AgentValueFormat { usd, inr, count }

/// Bar chart over labelled buckets.
class AgentChartCard extends AgentCard {
  const AgentChartCard({
    super.title,
    required this.labels,
    required this.values,
    this.format = AgentValueFormat.count,
    this.caption,
    super.action,
  });

  final List<String> labels;
  final List<double> values;
  final AgentValueFormat format;
  final String? caption;
}
