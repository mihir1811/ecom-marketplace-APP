import 'package:go_router/go_router.dart';

import 'route_names.dart';

/// Whether the current location is under the buyer account area.
bool isBuyerLocation(GoRouterState state) =>
    state.uri.path.startsWith('/buyer');

bool isBuyerPath(String path) => path.startsWith('/buyer');

String profilePathFor(String currentPath) => isBuyerPath(currentPath)
    ? AppRouteNames.buyerProfile
    : AppRouteNames.sellerProfile;

String inquiriesPathFor(String currentPath) => isBuyerPath(currentPath)
    ? AppRouteNames.buyerInquiries
    : AppRouteNames.sellerInquiries;

String inquiryNewPathFor(String currentPath) => isBuyerPath(currentPath)
    ? AppRouteNames.buyerInquiryNew
    : AppRouteNames.sellerInquiryNew;

String inquiryDetailPathFor(
  String currentPath,
  String category,
  String inquiryId,
) =>
    isBuyerPath(currentPath)
        ? AppRouteNames.buyerInquiryDetailPath(category, inquiryId)
        : AppRouteNames.sellerInquiryDetailPath(category, inquiryId);

String helpCenterPathFor(String currentPath) => isBuyerPath(currentPath)
    ? AppRouteNames.buyerHelpCenter
    : AppRouteNames.sellerHelpCenter;

String messagesPathFor(String currentPath) => isBuyerPath(currentPath)
    ? AppRouteNames.buyerMessages
    : AppRouteNames.sellerChat;

String chatDetailPathFor(String currentPath, String chatId) =>
    isBuyerPath(currentPath)
        ? AppRouteNames.buyerChatDetailPath(chatId)
        : AppRouteNames.sellerChatDetailPath(chatId);
