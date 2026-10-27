import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/live_show_models.dart';

/// Live Shows HTTP API (buyer side). Screens depend on this, not on Dio.
abstract class LiveShowRepository {
  /// Shows on air with video coming in, most watched first.
  Future<Result<List<LiveShow>, Failure>> shows();

  Future<Result<LiveShow, Failure>> show(String showId);

  Future<Result<LiveViewerToken, Failure>> viewerToken(String showId);

  Future<Result<ShowAuction, Failure>> auction(String showId);

  Future<Result<MyShowState, Failure>> me(String showId);

  Future<Result<LiveBidResult, LiveBidError>> bid({
    required String lotId,
    required int amount,
  });

  Future<Result<List<LiveChatMessage>, Failure>> chat(String showId);

  /// 403 = the seller muted this viewer; 400 = too fast or the show ended.
  Future<Result<LiveChatMessage, LiveActionError>> sendChat({
    required String showId,
    required String body,
  });

  Future<Result<void, LiveActionError>> like({
    required String showId,
    required int count,
  });
}
