/// AI chat boundary with a local/remote fallback seam.
///
/// Implementations (see MIGRATION_PLAN.md §5):
/// - `LocalAiChat`  — existing Node SSE endpoint (DioManager.postStream).
/// - `RemoteAiChat` — hosted AI API; the reliable default for the demo so it
///   runs without the local PC.
/// A fallback provider tries local, then falls back to remote on timeout/error.
///
/// Throws a sealed [AppFailure] on error.
abstract interface class AiChatRepository {
  /// Streams the assistant reply token-by-token for [message] in [sessionId].
  Stream<String> streamReply({
    required String sessionId,
    required String message,
  });
}