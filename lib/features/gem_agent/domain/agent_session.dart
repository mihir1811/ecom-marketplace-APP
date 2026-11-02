/// Which side of the app the user is on when they ask. [shared] pages
/// (about, terms, policies…) belong to neither side.
enum AgentWorkspace { buyer, seller, shared }

/// Who is asking. Decides which tools exist for the turn and lets tools
/// refuse work the account may not do. Never sent to the model beyond the
/// role facts in the prompt context.
class AgentSession {
  const AgentSession({
    this.signedIn = false,
    this.isSeller = false,
    this.workspace = AgentWorkspace.buyer,
  });

  static const guest = AgentSession();

  final bool signedIn;
  final bool isSeller;
  final AgentWorkspace workspace;

  bool get onSellerSide => workspace == AgentWorkspace.seller;
}

/// Minimum account a tool needs.
enum AgentToolAccess {
  public,
  signedIn,
  seller;

  bool allows(AgentSession session) => switch (this) {
    public => true,
    signedIn => session.signedIn,
    seller => session.signedIn && session.isSeller,
  };

  /// User-facing reason the tool is not available.
  String deniedMessage(AgentSession session) => switch (this) {
    public => '',
    signedIn => 'Please sign in first, then ask me again.',
    seller =>
      session.signedIn
          ? 'That is available on seller accounts only.'
          : 'Please sign in to your seller account first.',
  };
}
