/// Where the agent is in a turn.
enum GemAgentPhase { idle, listening, thinking, acting, awaitingInput, error }

/// One visible line of the agent conversation.
class GemAgentEntry {
  const GemAgentEntry._(
    this.text, {
    required this.fromUser,
    this.isError = false,
  });

  factory GemAgentEntry.user(String text) =>
      GemAgentEntry._(text, fromUser: true);

  factory GemAgentEntry.agent(String text, {bool isError = false}) =>
      GemAgentEntry._(text, fromUser: false, isError: isError);

  final String text;
  final bool fromUser;
  final bool isError;
}

/// UI state of the Gem Agent sheet and result flash.
class GemAgentState {
  const GemAgentState({
    this.isOpen = false,
    this.phase = GemAgentPhase.idle,
    this.liveTranscript = '',
    this.activity,
    this.notice,
    this.flash,
    this.entries = const [],
    this.options = const [],
    this.soundLevel = 0,
    this.voiceAvailable = true,
  });

  final bool isOpen;
  final GemAgentPhase phase;

  /// Words heard so far while listening.
  final String liveTranscript;

  /// Current step, e.g. "Searching natural diamonds…".
  final String? activity;

  /// Inline hint (mic unavailable, nothing heard).
  final String? notice;

  /// Result line shown above the dock after the sheet closes.
  final String? flash;
  final List<GemAgentEntry> entries;

  /// Quick replies for the pending question.
  final List<String> options;
  final double soundLevel;
  final bool voiceAvailable;

  bool get isBusy =>
      phase == GemAgentPhase.thinking || phase == GemAgentPhase.acting;

  static const _keep = Object();

  GemAgentState copyWith({
    bool? isOpen,
    GemAgentPhase? phase,
    String? liveTranscript,
    Object? activity = _keep,
    Object? notice = _keep,
    Object? flash = _keep,
    List<GemAgentEntry>? entries,
    List<String>? options,
    double? soundLevel,
    bool? voiceAvailable,
  }) {
    return GemAgentState(
      isOpen: isOpen ?? this.isOpen,
      phase: phase ?? this.phase,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      activity: identical(activity, _keep)
          ? this.activity
          : activity as String?,
      notice: identical(notice, _keep) ? this.notice : notice as String?,
      flash: identical(flash, _keep) ? this.flash : flash as String?,
      entries: entries ?? this.entries,
      options: options ?? this.options,
      soundLevel: soundLevel ?? this.soundLevel,
      voiceAvailable: voiceAvailable ?? this.voiceAvailable,
    );
  }
}
