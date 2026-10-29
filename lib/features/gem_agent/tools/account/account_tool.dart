import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/agent_session.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';

/// Whether an account answer stays in the sheet or opens the screen.
enum AnswerMode {
  /// "how many", "is there", "what's my" — answer in the sheet.
  answer,

  /// "show", "open", "take me to", "list all" — open the screen.
  open;

  static AnswerMode? parse(Object? raw) => switch (raw?.toString().trim()) {
    'answer' => answer,
    'open' => open,
    _ => null,
  };

  static const schema = {
    'type': 'string',
    'enum': ['answer', 'open'],
    'description':
        '"open" only when the user asks to show / open / go to / list the '
        'screen; otherwise "answer".',
  };
}

/// Read-only look-up over the signed-in user's own account data.
///
/// Account tools never change anything (no accepting, paying, bidding,
/// deleting): those stay a deliberate tap on the real screen. They read
/// with the app's own repositories, so the backend's auth decides what the
/// user may see.
abstract class AccountTool extends AgentTool {
  const AccountTool();

  @override
  AgentToolAccess get access => AgentToolAccess.signedIn;

  /// Most rows listed in a card; the rest are counted as "+N more".
  static const maxRows = 5;

  /// Most rows echoed to the model, which needs enough to answer a
  /// follow-up ("which one is the biggest?") but no personal details.
  static const maxModelRows = 10;

  /// A repository failure as a tool failure (cancel stays quiet).
  static ToolFailure failureOf(Failure failure) => ToolFailure(
    failure is NetworkFailure && failure.isCancelled
        ? 'Cancelled.'
        : failure.message,
  );

  /// Unwraps [result] or returns null and reports through [onFailure].
  static T? valueOr<T>(
    Result<T, Failure> result,
    void Function(Failure failure) onFailure,
  ) {
    switch (result) {
      case Success(:final value):
        return value;
      case ResultFailure(:final failure):
        onFailure(failure);
        return null;
    }
  }

  static String plural(int n, String one, [String? many]) =>
      '$n ${n == 1 ? one : (many ?? '${one}s')}';

  static String shortDate(DateTime? at) {
    if (at == null) return '';
    final l = at.toLocal();
    const months = [
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
    return '${l.day} ${months[l.month - 1]}';
  }
}
