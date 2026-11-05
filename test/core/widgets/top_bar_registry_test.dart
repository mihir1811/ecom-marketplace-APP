import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/widgets/navigation/top_bar/top_bar_registry.dart';

void main() {
  TopBarSection section(String path) => TopBarRegistry.sectionFor(path);

  group('TopBarRegistry.sectionFor', () {
    test('catalogs and home are marketplace', () {
      for (final path in [
        '/',
        '/diamonds',
        '/diamonds/results',
        '/gemstones/results',
        '/watches',
        '/watches/brand/Rolex',
        '/bullions',
        '/auctions',
        '/live',
        '/comparison',
        '/product/natural-diamond/42',
      ]) {
        expect(section(path), TopBarSection.marketplace, reason: path);
      }
    });

    test('jewellery screens and jewellery products are jewelry', () {
      for (final path in [
        '/jewelry',
        '/jewelry/listing',
        '/jewelry/house/cartier',
        '/jewelry/orders',
        '/product/jewelry/ring-1',
      ]) {
        expect(section(path), TopBarSection.jewelry, reason: path);
      }
    });

    test('account areas map to their side', () {
      expect(section('/buyer/orders'), TopBarSection.buyer);
      expect(section('/buyer/wishlist'), TopBarSection.buyer);
      expect(section('/seller/dashboard'), TopBarSection.seller);
      expect(section('/seller/orders/7'), TopBarSection.seller);
    });

    test('flows and legal pages are focused', () {
      for (final path in [
        '/login',
        '/cart',
        '/jewelry/bag',
        '/jewelry/checkout',
        '/payment/confirmation/9',
        '/diamonds/filters',
        '/watches/brand/Rolex/filters',
        '/live/show-1',
        '/learn/diamonds',
        '/policies/returns',
        '/buyer/policies',
        '/seller/terms',
      ]) {
        expect(section(path), TopBarSection.focused, reason: path);
      }
    });
  });

  group('TopBarRegistry.specs', () {
    test('search only on marketplace sections', () {
      expect(TopBarRegistry.specFor('/').search, isTrue);
      expect(TopBarRegistry.specFor('/jewelry').search, isTrue);
      expect(TopBarRegistry.specFor('/buyer/orders').search, isFalse);
      expect(TopBarRegistry.specFor('/seller/dashboard').search, isFalse);
    });

    test('common cart and jewellery bag never share a section', () {
      for (final spec in TopBarRegistry.specs.values) {
        expect(
          spec.actions.contains(TopBarAction.cart) &&
              spec.actions.contains(TopBarAction.jewelryBag),
          isFalse,
        );
      }
      expect(
        TopBarRegistry.specFor('/diamonds').actions,
        contains(TopBarAction.cart),
      );
      expect(
        TopBarRegistry.specFor('/jewelry/listing').actions,
        contains(TopBarAction.jewelryBag),
      );
    });

    test('focused flows carry no shortcuts', () {
      expect(TopBarRegistry.specFor('/cart').actions, isEmpty);
    });
  });
}
