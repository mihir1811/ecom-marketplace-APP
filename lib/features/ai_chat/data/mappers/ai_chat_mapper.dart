import '../../domain/models/ai_chat_message.dart';
import '../../domain/models/ai_chat_product.dart';
import '../../domain/models/ai_chat_reply.dart';

abstract final class AiChatMapper {
  static AiChatProduct productFromJson(Map<String, dynamic> json) {
    return AiChatProduct(
      id: json['id']?.toString() ?? '',
      productType: json['productType']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      stockNumber: json['stockNumber']?.toString() ?? '',
      shape: _nullableString(json['shape']),
      caratWeight: _asDouble(json['caratWeight']),
      color: _nullableString(json['color']),
      clarity: _nullableString(json['clarity']),
      cut: _nullableString(json['cut']),
      certificateCompanyName: _nullableString(json['certificateCompanyName']),
      totalPrice: _asDouble(json['totalPrice']),
      pricePerCarat: _asDouble(json['pricePerCarat']),
      imageUrl: _nullableString(json['imageUrl']),
      href: json['href']?.toString() ?? '',
    );
  }

  static AiChatProductGroup groupFromJson(Map<String, dynamic> json) {
    final productsJson = json['products'];
    final products = <AiChatProduct>[];
    if (productsJson is List) {
      for (final item in productsJson) {
        if (item is Map<String, dynamic>) {
          final product = productFromJson(item);
          if (product.id.isNotEmpty) products.add(product);
        }
      }
    }
    return AiChatProductGroup(
      label: json['label']?.toString() ?? '',
      products: products,
      totalFound: _asInt(json['totalFound']) ?? products.length,
      productType: json['productType']?.toString() ?? '',
    );
  }

  static AiChatReply replyFromJson(Map<String, dynamic> json) {
    final productsJson = json['products'];
    final groupsJson = json['productGroups'];
    final products = <AiChatProduct>[];
    final groups = <AiChatProductGroup>[];

    if (productsJson is List) {
      for (final item in productsJson) {
        if (item is Map<String, dynamic>) {
          final product = productFromJson(item);
          if (product.id.isNotEmpty) products.add(product);
        }
      }
    }
    if (groupsJson is List) {
      for (final item in groupsJson) {
        if (item is Map<String, dynamic>) {
          groups.add(groupFromJson(item));
        }
      }
    }

    return AiChatReply(
      reply: json['reply']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      products: products,
      productGroups: groups,
      totalFound: _asInt(json['totalFound']) ?? products.length,
    );
  }

  static AiChatSessionSummary sessionSummaryFromJson(Map<String, dynamic> json) {
    return AiChatSessionSummary(
      sessionId: json['sessionId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      preview: json['preview']?.toString() ?? '',
      messageCount: _asInt(json['messageCount']) ?? 0,
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  static AiChatMessage messageFromJson(Map<String, dynamic> json) {
    final productsJson = json['products'];
    final groupsJson = json['productGroups'];
    final imageUrlsJson = json['imageUrls'];
    final products = <AiChatProduct>[];
    final groups = <AiChatProductGroup>[];
    final imageUrls = <String>[];

    if (productsJson is List) {
      for (final item in productsJson) {
        if (item is Map<String, dynamic>) {
          final product = productFromJson(item);
          if (product.id.isNotEmpty) products.add(product);
        }
      }
    }
    if (groupsJson is List) {
      for (final item in groupsJson) {
        if (item is Map<String, dynamic>) {
          groups.add(groupFromJson(item));
        }
      }
    }
    if (imageUrlsJson is List) {
      for (final item in imageUrlsJson) {
        final url = item?.toString() ?? '';
        if (url.isNotEmpty) imageUrls.add(url);
      }
    }

    return AiChatMessage(
      id: json['id']?.toString() ?? '',
      role: AiChatRole.fromApi(json['role']?.toString()),
      content: json['content']?.toString() ?? '',
      imageUrls: imageUrls,
      products: products,
      productGroups: groups,
      totalFound: _asInt(json['totalFound']),
      createdAt: _asDate(json['createdAt']),
    );
  }

  static AiChatSessionDetail sessionDetailFromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'];
    final messages = <AiChatMessage>[];
    if (messagesJson is List) {
      for (final item in messagesJson) {
        if (item is Map<String, dynamic>) {
          messages.add(messageFromJson(item));
        }
      }
    }
    return AiChatSessionDetail(
      sessionId: json['sessionId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      messages: messages,
    );
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _asDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
