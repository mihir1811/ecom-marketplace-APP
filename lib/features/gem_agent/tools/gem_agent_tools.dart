import '../domain/agent_tool.dart';
import 'ask_user/ask_user_tool.dart';
import 'bullion_search/bullion_search_tool.dart';
import 'buyer/my_auctions_tool.dart';
import 'buyer/my_cart_tool.dart';
import 'buyer/my_offers_tool.dart';
import 'buyer/my_orders_tool.dart';
import 'buyer/my_wallet_tool.dart';
import 'buyer/my_wishlist_tool.dart';
import 'diamond_search/diamond_search_tool.dart';
import 'gemstone_search/gemstone_search_tool.dart';
import 'jewelry_search/jewelry_search_tool.dart';
import 'navigation/open_screen_tool.dart';
import 'seller/seller_auctions_tool.dart';
import 'seller/seller_inventory_tool.dart';
import 'seller/seller_offers_tool.dart';
import 'seller/seller_orders_tool.dart';
import 'seller/seller_sales_tool.dart';
import 'watch_search/watch_search_tool.dart';

/// Every capability Gem Agent has. To add one: implement [AgentTool] in its
/// own folder under `tools/` (catalog searches extend `CatalogSearchTool`,
/// account look-ups extend `AccountTool`) and append it here. The prompt,
/// schemas, access checks and engine pick it up.
///
/// Every tool is read-only or navigates: nothing here pays, bids, accepts,
/// rejects or deletes. Those stay deliberate taps on the real screens.
const List<AgentTool> gemAgentTools = [
  AskUserTool(),
  // Catalog search (everyone).
  DiamondSearchTool(),
  GemstoneSearchTool(),
  WatchSearchTool(),
  JewelrySearchTool(),
  BullionSearchTool(),
  OpenScreenTool(),
  // The signed-in user's own account.
  MyCartTool(),
  MyOrdersTool(),
  MyWishlistTool(),
  MyWalletTool(),
  MyOffersTool(),
  MyAuctionsTool(),
  // Seller workspace.
  SellerOrdersTool(),
  SellerSalesTool(),
  SellerInventoryTool(),
  SellerAuctionsTool(),
  SellerOffersTool(),
];
